import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { Role } from '../common/enums/role.enum';
import { Event, EventStatus, EventVisibility } from '../events/entities';
import {
  CreateRegistrationDto,
  CreateTicketTypeDto,
  RegistrationResponseDto,
  TicketTypeResponseDto,
  UpdateTicketTypeDto,
} from './dto';
import {
  Registration,
  RegistrationStatus,
  TicketType,
} from './entities';

@Injectable()
export class RegistrationsService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(TicketType)
    private readonly ticketTypesRepository: Repository<TicketType>,
    @InjectRepository(Registration)
    private readonly registrationsRepository: Repository<Registration>,
  ) {}

  async listPublicTicketTypes(eventId: string): Promise<TicketTypeResponseDto[]> {
    const event = await this.eventsRepository.findOne({
      where: {
        id: eventId,
        status: EventStatus.PUBLISHED,
        visibility: EventVisibility.PUBLIC,
      },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    const ticketTypes = await this.ticketTypesRepository.find({
      where: { eventId },
      order: { saleStartAt: 'ASC' },
    });

    return ticketTypes
      .filter((ticketType) => ticketType.remaining > 0)
      .map((ticketType) => this.toTicketTypeResponse(ticketType));
  }

  async listManageTicketTypes(
    eventId: string,
    userId: string,
    role: Role,
  ): Promise<TicketTypeResponseDto[]> {
    await this.getManageableEventOrFail(eventId, userId, role);
    const ticketTypes = await this.ticketTypesRepository.find({
      where: { eventId },
      order: { createdAt: 'ASC' },
    });
    return ticketTypes.map((ticketType) => this.toTicketTypeResponse(ticketType));
  }

  async createTicketType(
    eventId: string,
    userId: string,
    role: Role,
    dto: CreateTicketTypeDto,
  ): Promise<TicketTypeResponseDto> {
    const event = await this.getManageableEventOrFail(eventId, userId, role);
    this.assertSaleWindow(dto.saleStartAt, dto.saleEndAt);

    const ticketType = await this.ticketTypesRepository.save(
      this.ticketTypesRepository.create({
        eventId: event.id,
        name: dto.name.trim(),
        price: this.normalizePrice(dto.price),
        quantity: dto.quantity,
        remaining: dto.quantity,
        saleStartAt: new Date(dto.saleStartAt),
        saleEndAt: new Date(dto.saleEndAt),
      }),
    );

    return this.toTicketTypeResponse(ticketType);
  }

  async updateTicketType(
    ticketTypeId: string,
    userId: string,
    role: Role,
    dto: UpdateTicketTypeDto,
  ): Promise<TicketTypeResponseDto> {
    const ticketType = await this.ticketTypesRepository.findOne({
      where: { id: ticketTypeId },
      relations: { event: true },
    });

    if (!ticketType) {
      throw new NotFoundException('Ticket type not found');
    }

    await this.getManageableEventOrFail(ticketType.eventId, userId, role);

    if (dto.saleStartAt != null || dto.saleEndAt != null) {
      this.assertSaleWindow(
        dto.saleStartAt ?? ticketType.saleStartAt.toISOString(),
        dto.saleEndAt ?? ticketType.saleEndAt.toISOString(),
      );
    }

    if (dto.name != null) {
      ticketType.name = dto.name.trim();
    }
    if (dto.price != null) {
      ticketType.price = this.normalizePrice(dto.price);
    }
    if (dto.quantity != null) {
      const sold = ticketType.quantity - ticketType.remaining;
      if (dto.quantity < sold) {
        throw new BadRequestException('Quantity cannot be less than tickets already booked');
      }
      ticketType.quantity = dto.quantity;
      ticketType.remaining = dto.quantity - sold;
    }
    if (dto.saleStartAt != null) {
      ticketType.saleStartAt = new Date(dto.saleStartAt);
    }
    if (dto.saleEndAt != null) {
      ticketType.saleEndAt = new Date(dto.saleEndAt);
    }

    await this.ticketTypesRepository.save(ticketType);
    return this.toTicketTypeResponse(ticketType);
  }

  async createRegistration(
    eventId: string,
    attendeeId: string,
    dto: CreateRegistrationDto,
  ): Promise<RegistrationResponseDto> {
    const shouldUseLock = this.dataSource.options.type !== 'sqljs';
    const registration = await this.dataSource.transaction(async (manager) => {
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
        where: {
          id: dto.ticketTypeId,
          eventId,
        },
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

      if (Number.parseFloat(ticketType.price) > 0) {
        throw new BadRequestException(
          'Use the Stripe checkout session endpoint for paid ticket types.',
        );
      }

      if (ticketType.remaining < dto.quantity) {
        throw new BadRequestException('Not enough tickets remaining');
      }

      ticketType.remaining -= dto.quantity;
      await manager.save(ticketType);

      return manager.save(
        Registration,
        manager.create(Registration, {
          eventId,
          attendeeId,
          ticketTypeId: ticketType.id,
          quantity: dto.quantity,
          status: RegistrationStatus.CONFIRMED,
        }),
      );
    });

    return this.getRegistrationByIdOrFail(registration.id, attendeeId);
  }

  async listMyRegistrations(attendeeId: string): Promise<RegistrationResponseDto[]> {
    const registrations = await this.registrationsRepository.find({
      where: { attendeeId },
      relations: {
        event: true,
        ticketType: true,
      },
      order: { createdAt: 'DESC' },
    });

    return registrations.map((registration) =>
      this.toRegistrationResponse(registration),
    );
  }

  async getRegistrationByIdOrFail(
    registrationId: string,
    attendeeId: string,
  ): Promise<RegistrationResponseDto> {
    const registration = await this.registrationsRepository.findOne({
      where: { id: registrationId, attendeeId },
      relations: {
        event: true,
        ticketType: true,
      },
    });

    if (!registration) {
      throw new NotFoundException('Registration not found');
    }

    return this.toRegistrationResponse(registration);
  }

  toTicketTypeResponse(ticketType: TicketType): TicketTypeResponseDto {
    return {
      id: ticketType.id,
      eventId: ticketType.eventId,
      name: ticketType.name,
      price: ticketType.price,
      quantity: ticketType.quantity,
      remaining: ticketType.remaining,
      saleStartAt: ticketType.saleStartAt,
      saleEndAt: ticketType.saleEndAt,
    };
  }

  toRegistrationResponse(registration: Registration): RegistrationResponseDto {
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
      ticketType: this.toTicketTypeResponse(registration.ticketType),
      quantity: registration.quantity,
      status: registration.status,
      createdAt: registration.createdAt,
    };
  }

  private async getManageableEventOrFail(
    eventId: string,
    userId: string,
    role: Role,
  ): Promise<Event> {
    const event = await this.eventsRepository.findOne({ where: { id: eventId } });
    if (!event) {
      throw new NotFoundException('Event not found');
    }
    if (role != Role.ADMIN && event.organizerId != userId) {
      throw new ForbiddenException('You cannot manage tickets for this event');
    }
    return event;
  }

  private assertSaleWindow(startAt: string, endAt: string): void {
    const start = new Date(startAt);
    const end = new Date(endAt);

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw new BadRequestException('Invalid ticket sale window');
    }

    if (end.getTime() <= start.getTime()) {
      throw new BadRequestException('Ticket sale end must be after the start');
    }
  }

  private normalizePrice(price: string): string {
    const value = Number.parseFloat(price);
    if (!Number.isFinite(value) || value < 0) {
      throw new BadRequestException('Ticket price must be zero or greater');
    }

    return value.toFixed(2);
  }
}
