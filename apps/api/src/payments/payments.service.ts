import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import StripeConstructor = require('stripe');
import { DataSource, Repository } from 'typeorm';
import { Event, EventStatus, EventVisibility } from '../events/entities';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import { RegistrationResponseDto } from '../registrations/dto';
import {
  Registration,
  RegistrationStatus,
  TicketType,
} from '../registrations/entities';
import { User } from '../users/entities';
import {
  Booking,
  BookingStatus,
  BookingType,
  Payment,
  PaymentProvider,
  PaymentStatus,
} from './entities';
import {
  BookingResponseDto,
  CreateCheckoutSessionDto,
  PaymentCheckoutResponseDto,
  PaymentResponseDto,
} from './dto';

type StripeSessionSnapshot = {
  id: string | null;
  url: string | null;
};

@Injectable()
export class PaymentsService {
  private readonly stripe: StripeConstructor.Stripe | null;
  private readonly stripeWebhookSecret: string;
  private readonly stripeCurrency: string;
  private readonly defaultReturnUrl: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly dataSource: DataSource,
    private readonly notificationsService: NotificationsService,
    @InjectRepository(Booking)
    private readonly bookingsRepository: Repository<Booking>,
    @InjectRepository(Payment)
    private readonly paymentsRepository: Repository<Payment>,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(TicketType)
    private readonly ticketTypesRepository: Repository<TicketType>,
    @InjectRepository(Registration)
    private readonly registrationsRepository: Repository<Registration>,
  ) {
    const stripeSecretKey =
      this.configService.get<string>('payments.stripeSecretKey') ?? '';
    this.stripe =
      stripeSecretKey.length > 0 ? StripeConstructor(stripeSecretKey) : null;
    this.stripeWebhookSecret =
      this.configService.get<string>('payments.stripeWebhookSecret') ?? '';
    this.stripeCurrency =
      this.configService.get<string>('payments.stripeCurrency') ?? 'usd';
    this.defaultReturnUrl =
      this.configService.get<string>('payments.defaultReturnUrl') ??
      'http://127.0.0.1:8081';
  }

  async createCheckoutSession(
    eventId: string,
    attendeeId: string,
    dto: CreateCheckoutSessionDto,
  ): Promise<PaymentCheckoutResponseDto> {
    if (this.stripe == null) {
      throw new ServiceUnavailableException(
        'Stripe is not configured. Set STRIPE_SECRET_KEY to enable payments.',
      );
    }

    const prepared = await this.prepareStripePayment(eventId, attendeeId, dto);

    try {
      const returnUrl = this.normalizeReturnUrl(dto.returnUrl, eventId);
      const unitAmount = this.toStripeAmount(prepared.ticketType.price);
      const session = await this.stripe.checkout.sessions.create({
        mode: 'payment',
        success_url: this.appendUrlParams(returnUrl, {
          payment: 'success',
          session_id: '{CHECKOUT_SESSION_ID}',
          eventId,
        }),
        cancel_url: this.appendUrlParams(returnUrl, {
          payment: 'cancel',
          session_id: '{CHECKOUT_SESSION_ID}',
          eventId,
        }),
        customer_email: prepared.attendeeEmail,
        client_reference_id: prepared.payment.id,
        metadata: {
          paymentId: prepared.payment.id,
          bookingId: prepared.booking.id,
          registrationId: prepared.registration.id,
          eventId,
          attendeeId,
          ticketTypeId: dto.ticketTypeId,
        },
        line_items: [
          {
            quantity: dto.quantity,
            price_data: {
              currency: this.stripeCurrency,
              unit_amount: unitAmount,
              product_data: {
                name: `${prepared.event.title} · ${prepared.ticketType.name}`,
                description: `${prepared.event.venue}, ${prepared.event.city}`,
              },
            },
          },
        ],
      });

      prepared.payment.providerRef = session.id;
      await this.paymentsRepository.save(prepared.payment);

      return this.getCheckoutOrFail(prepared.payment.id, attendeeId, {
        id: session.id,
        url: session.url ?? null,
      });
    } catch (error) {
      await this.cancelInitiatedPayment(prepared.payment.id, attendeeId);
      throw new BadRequestException(
        error instanceof Error
          ? `Stripe checkout could not be created: ${error.message}`
          : 'Stripe checkout could not be created',
      );
    }
  }

  async verifyStripeCheckoutSession(
    sessionId: string,
    attendeeId: string,
  ): Promise<PaymentCheckoutResponseDto> {
    if (this.stripe == null) {
      throw new ServiceUnavailableException(
        'Stripe is not configured. Set STRIPE_SECRET_KEY to enable payments.',
      );
    }

    const payment = await this.paymentsRepository.findOne({
      where: {
        payerId: attendeeId,
        provider: PaymentProvider.STRIPE,
        providerRef: sessionId,
      },
      relations: {
        booking: true,
      },
    });

    if (!payment) {
      throw new NotFoundException('Stripe payment session not found');
    }

    const session = await this.stripe.checkout.sessions.retrieve(sessionId);

    if (session.payment_status === 'paid') {
      await this.confirmStripePayment(payment.id, attendeeId);
    } else if (
      (session.status === 'expired' || session.status === 'open') &&
      payment.status === PaymentStatus.INITIATED
    ) {
      // Keep initiated payments while the session is open, but release inventory
      // if Stripe reports the session as expired.
      if (session.status === 'expired') {
        await this.cancelInitiatedPayment(payment.id, attendeeId);
      }
    }

    return this.getCheckoutOrFail(payment.id, attendeeId, {
      id: session.id,
      url: session.url ?? null,
    });
  }

  async handleStripeWebhook(
    payload: Buffer | undefined,
    signature: string | undefined,
  ): Promise<{ received: true }> {
    if (this.stripe == null) {
      throw new ServiceUnavailableException(
        'Stripe is not configured. Set STRIPE_SECRET_KEY to enable payments.',
      );
    }

    if (payload == null || payload.length === 0) {
      throw new BadRequestException('Missing Stripe webhook payload');
    }

    if (!signature || this.stripeWebhookSecret.length === 0) {
      throw new ServiceUnavailableException(
        'Stripe webhook is not configured. Set STRIPE_WEBHOOK_SECRET to enable webhooks.',
      );
    }

    let event: any;
    try {
      event = this.stripe.webhooks.constructEvent(
        payload,
        signature,
        this.stripeWebhookSecret,
      );
    } catch (error) {
      throw new BadRequestException(
        error instanceof Error
          ? `Stripe webhook signature verification failed: ${error.message}`
          : 'Stripe webhook signature verification failed',
      );
    }

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as any;
      const paymentId = session.metadata?.paymentId;
      if (paymentId != null) {
        await this.confirmStripePaymentInternal(paymentId);
      }
    }

    if (event.type === 'checkout.session.expired') {
      const session = event.data.object as any;
      const paymentId = session.metadata?.paymentId;
      if (paymentId != null) {
        await this.cancelInitiatedPaymentById(paymentId);
      }
    }

    return { received: true };
  }

  async listMyPayments(attendeeId: string): Promise<PaymentCheckoutResponseDto[]> {
    const payments = await this.paymentsRepository.find({
      where: { payerId: attendeeId },
      order: { createdAt: 'DESC' },
      relations: {
        booking: true,
      },
    });

    return Promise.all(
      payments.map((payment) =>
        this.getCheckoutOrFail(payment.id, attendeeId, {
          id: payment.providerRef || null,
          url: null,
        }),
      ),
    );
  }

  async getCheckoutOrFail(
    paymentId: string,
    attendeeId: string,
    session: StripeSessionSnapshot = { id: null, url: null },
  ): Promise<PaymentCheckoutResponseDto> {
    const payment = await this.paymentsRepository.findOne({
      where: { id: paymentId, payerId: attendeeId },
      relations: {
        booking: true,
      },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const registration = await this.registrationsRepository.findOne({
      where: { id: payment.booking.registrationId, attendeeId },
      relations: {
        event: true,
        ticketType: true,
      },
    });

    if (!registration) {
      throw new NotFoundException('Registration not found');
    }

    return {
      booking: this.toBookingResponse(payment.booking),
      payment: this.toPaymentResponse(payment),
      registration: this.toRegistrationResponse(registration),
      checkoutSessionId: session.id,
      checkoutUrl: session.url,
    };
  }

  toBookingResponse(booking: Booking): BookingResponseDto {
    return {
      id: booking.id,
      type: booking.type,
      requesterId: booking.requesterId,
      targetUserId: booking.targetUserId,
      eventId: booking.eventId,
      registrationId: booking.registrationId,
      status: booking.status,
      amount: booking.amount,
      currency: booking.currency,
      createdAt: booking.createdAt,
    };
  }

  toPaymentResponse(payment: Payment): PaymentResponseDto {
    return {
      id: payment.id,
      bookingId: payment.bookingId,
      payerId: payment.payerId,
      provider: payment.provider,
      providerRef: payment.providerRef,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      paidAt: payment.paidAt,
      createdAt: payment.createdAt,
    };
  }

  private async prepareStripePayment(
    eventId: string,
    attendeeId: string,
    dto: CreateCheckoutSessionDto,
  ) {
    const shouldUseLock = this.dataSource.options.type !== 'sqljs';

    return this.dataSource.transaction(async (manager) => {
      const event = await manager.findOne(Event, {
        where: {
          id: eventId,
          status: EventStatus.PUBLISHED,
          visibility: EventVisibility.PUBLIC,
        },
      });

      if (!event) {
        throw new NotFoundException('Event not found');
      }

      const ticketType = await manager.findOne(TicketType, {
        where: { id: dto.ticketTypeId, eventId },
        ...(shouldUseLock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
      });

      if (!ticketType) {
        throw new NotFoundException('Ticket type not found');
      }

      const now = Date.now();
      if (
        ticketType.saleStartAt.getTime() > now ||
        ticketType.saleEndAt.getTime() < now
      ) {
        throw new BadRequestException('This ticket type is not currently on sale');
      }

      const unitPrice = Number.parseFloat(ticketType.price);
      if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
        throw new BadRequestException(
          'Use the free registration endpoint for free ticket types',
        );
      }

      if (ticketType.remaining < dto.quantity) {
        throw new BadRequestException('Not enough tickets remaining');
      }

      ticketType.remaining -= dto.quantity;
      await manager.save(ticketType);

      const registration = await manager.save(
        Registration,
        manager.create(Registration, {
          eventId,
          attendeeId,
          ticketTypeId: ticketType.id,
          quantity: dto.quantity,
          status: RegistrationStatus.PENDING_PAYMENT,
        }),
      );

      const amount = (unitPrice * dto.quantity).toFixed(2);

      const booking = await manager.save(
        Booking,
        manager.create(Booking, {
          type: BookingType.EVENT_TICKET,
          requesterId: attendeeId,
          targetUserId: event.organizerId,
          eventId,
          registrationId: registration.id,
          status: BookingStatus.PENDING,
          amount,
          currency: this.stripeCurrency.toUpperCase(),
        }),
      );

      const payment = await manager.save(
        Payment,
        manager.create(Payment, {
          bookingId: booking.id,
          payerId: attendeeId,
          provider: PaymentProvider.STRIPE,
          providerRef: `pending_${booking.id}`,
          amount,
          currency: this.stripeCurrency.toUpperCase(),
          status: PaymentStatus.INITIATED,
        }),
      );

      const attendee = await manager.findOne(User, {
        where: { id: attendeeId },
      });

      return {
        event,
        ticketType,
        registration,
        booking,
        payment,
        attendeeEmail: attendee?.email ?? '',
      };
    });
  }

  private async confirmStripePayment(
    paymentId: string,
    attendeeId: string,
  ): Promise<void> {
    await this.confirmStripePaymentInternal(paymentId, attendeeId);
  }

  private async confirmStripePaymentInternal(
    paymentId: string,
    attendeeId?: string,
  ): Promise<void> {
    const shouldUseLock = this.dataSource.options.type !== 'sqljs';
    let notificationContext:
      | {
          attendeeId: string;
          bookingId: string;
          bookingTargetUserId: string;
          eventTitle: string;
          paymentId: string;
        }
      | undefined;

    await this.dataSource.transaction(async (manager) => {
      const payment = await manager.findOne(Payment, {
        where: { id: paymentId },
        relations: {
          booking: true,
        },
        ...(shouldUseLock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
      });

      if (!payment) {
        throw new NotFoundException('Payment not found');
      }

      if (attendeeId != null && payment.payerId !== attendeeId) {
        throw new ForbiddenException('You cannot confirm this payment');
      }

      if (payment.status === PaymentStatus.PAID) {
        return;
      }

      if (payment.status !== PaymentStatus.INITIATED) {
        throw new BadRequestException('Only initiated payments can be confirmed');
      }

      payment.status = PaymentStatus.PAID;
      payment.paidAt = new Date();
      await manager.save(payment);

      const booking = payment.booking;
      booking.status = BookingStatus.CONFIRMED;
      await manager.save(booking);

      const registration = await manager.findOne(Registration, {
        where: { id: booking.registrationId },
        relations: { event: true },
      });
      if (!registration) {
        throw new NotFoundException('Registration not found');
      }

      registration.status = RegistrationStatus.CONFIRMED;
      await manager.save(registration);

      notificationContext = {
        attendeeId: payment.payerId,
        bookingId: booking.id,
        bookingTargetUserId: booking.targetUserId,
        eventTitle: registration.event.title,
        paymentId: payment.id,
      };
    });

    if (notificationContext != null) {
      await Promise.all([
        this.notificationsService.createNotification({
          userId: notificationContext.attendeeId,
          type: NotificationType.PAYMENT,
          title: 'Payment confirmed',
          body: `Your payment for ${notificationContext.eventTitle} has been confirmed.`,
          resourceType: 'payment',
          resourceId: notificationContext.paymentId,
        }),
        this.notificationsService.createNotification({
          userId: notificationContext.bookingTargetUserId,
          type: NotificationType.BOOKING,
          title: 'New paid attendee registration',
          body: `${notificationContext.eventTitle} has a newly confirmed paid registration.`,
          resourceType: 'booking',
          resourceId: notificationContext.bookingId,
        }),
      ]);
    }
  }

  private async cancelInitiatedPayment(
    paymentId: string,
    attendeeId: string,
  ): Promise<void> {
    const shouldUseLock = this.dataSource.options.type !== 'sqljs';

    await this.dataSource.transaction(async (manager) => {
      const payment = await manager.findOne(Payment, {
        where: { id: paymentId },
        relations: {
          booking: true,
        },
        ...(shouldUseLock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
      });

      if (!payment || payment.payerId !== attendeeId) {
        return;
      }

      if (payment.status !== PaymentStatus.INITIATED) {
        return;
      }

      payment.status = PaymentStatus.FAILED;
      await manager.save(payment);

      const booking = payment.booking;
      booking.status = BookingStatus.CANCELLED;
      await manager.save(booking);

      const registration = await manager.findOne(Registration, {
        where: { id: booking.registrationId },
      });
      if (!registration) {
        return;
      }

      registration.status = RegistrationStatus.CANCELLED;
      await manager.save(registration);

      const ticketType = await manager.findOne(TicketType, {
        where: { id: registration.ticketTypeId },
        ...(shouldUseLock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
      });
      if (ticketType != null) {
        ticketType.remaining += registration.quantity;
        await manager.save(ticketType);
      }
    });
  }

  private async cancelInitiatedPaymentById(paymentId: string): Promise<void> {
    const payment = await this.paymentsRepository.findOne({
      where: { id: paymentId },
    });

    if (!payment) {
      return;
    }

    await this.cancelInitiatedPayment(payment.id, payment.payerId);
  }

  private toRegistrationResponse(
    registration: Registration,
  ): RegistrationResponseDto {
    return {
      id: registration.id,
      event: {
        id: registration.event.id,
        title: registration.event.title,
        city: registration.event.city,
        venue: registration.event.venue,
        startAt: registration.event.startAt,
        endAt: registration.event.endAt,
      },
      ticketType: {
        id: registration.ticketType.id,
        eventId: registration.ticketType.eventId,
        name: registration.ticketType.name,
        price: registration.ticketType.price,
        quantity: registration.ticketType.quantity,
        remaining: registration.ticketType.remaining,
        saleStartAt: registration.ticketType.saleStartAt,
        saleEndAt: registration.ticketType.saleEndAt,
      },
      quantity: registration.quantity,
      status: registration.status,
      createdAt: registration.createdAt,
    };
  }

  private normalizeReturnUrl(returnUrl: string | undefined, eventId: string): string {
    const fallback = this.defaultReturnUrl;
    const candidate =
      returnUrl != null && returnUrl.trim().length > 0 ? returnUrl.trim() : fallback;

    try {
      const url = new URL(candidate);
      if (!url.searchParams.has('eventId')) {
        url.searchParams.set('eventId', eventId);
      }
      return url.toString();
    } catch {
      const url = new URL(fallback);
      url.searchParams.set('eventId', eventId);
      return url.toString();
    }
  }

  private appendUrlParams(
    target: string,
    params: Record<string, string>,
  ): string {
    const url = new URL(target);
    for (const [key, value] of Object.entries(params)) {
      url.searchParams.set(key, value);
    }
    return url.toString();
  }

  private toStripeAmount(amount: string): number {
    const numeric = Number.parseFloat(amount);
    if (!Number.isFinite(numeric) || numeric <= 0) {
      throw new BadRequestException('Invalid payment amount');
    }
    return Math.round(numeric * 100);
  }
}
