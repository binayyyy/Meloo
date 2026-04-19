import { RegistrationResponseDto } from '../../registrations/dto';
import { BookingStatus, BookingType, PaymentProvider, PaymentStatus } from '../entities';

export class BookingResponseDto {
  id!: string;
  type!: BookingType;
  requesterId!: string;
  targetUserId!: string;
  eventId!: string;
  registrationId!: string;
  status!: BookingStatus;
  amount!: string;
  currency!: string;
  createdAt!: Date;
}

export class PaymentResponseDto {
  id!: string;
  bookingId!: string;
  payerId!: string;
  provider!: PaymentProvider;
  providerRef!: string;
  amount!: string;
  currency!: string;
  status!: PaymentStatus;
  paidAt!: Date | null;
  createdAt!: Date;
}

export class PaymentCheckoutResponseDto {
  booking!: BookingResponseDto;
  payment!: PaymentResponseDto;
  registration!: RegistrationResponseDto;
  checkoutSessionId!: string | null;
  checkoutUrl!: string | null;
}
