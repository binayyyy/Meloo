import { RegistrationStatus } from '../entities';
import { TicketTypeResponseDto } from './ticket-type-response.dto';

export class RegistrationEventSummaryDto {
  id!: string;
  title!: string;
  city!: string;
  venue!: string;
  startAt!: Date;
  endAt!: Date;
}

export class RegistrationResponseDto {
  id!: string;
  event!: RegistrationEventSummaryDto;
  ticketType!: TicketTypeResponseDto;
  quantity!: number;
  status!: RegistrationStatus;
  createdAt!: Date;
}

