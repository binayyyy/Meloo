import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { Event } from '../../events/entities';
import { User } from '../../users/entities';
import { TicketType } from './ticket-type.entity';

export enum RegistrationStatus {
  CONFIRMED = 'confirmed',
  PENDING_PAYMENT = 'pending_payment',
  CANCELLED = 'cancelled',
}

@Entity({ name: 'registrations' })
export class Registration {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'event_id' })
  eventId!: string;

  @Column({ type: 'uuid', name: 'attendee_id' })
  attendeeId!: string;

  @Column({ type: 'uuid', name: 'ticket_type_id' })
  ticketTypeId!: string;

  @Column({ type: 'integer' })
  quantity!: number;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: RegistrationStatus,
    default: RegistrationStatus.CONFIRMED,
  })
  status!: RegistrationStatus;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => Event, (event) => event.registrations, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'event_id' })
  event!: Event;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'attendee_id' })
  attendee!: User;

  @ManyToOne(() => TicketType, (ticketType) => ticketType.registrations, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'ticket_type_id' })
  ticketType!: TicketType;
}
