import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { User } from '../../users/entities';
import { EventCategory } from './event-category.entity';
import { Registration } from '../../registrations/entities/registration.entity';
import { TicketType } from '../../registrations/entities/ticket-type.entity';

export enum EventStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  CANCELLED = 'cancelled',
  COMPLETED = 'completed',
}

export enum EventVisibility {
  PUBLIC = 'public',
  PRIVATE = 'private',
}

@Entity({ name: 'events' })
export class Event {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'organizer_id' })
  organizerId!: string;

  @Column({ type: 'varchar' })
  title!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'uuid', name: 'category_id' })
  categoryId!: string;

  @Column({ type: 'varchar' })
  venue!: string;

  @Column({ type: 'varchar' })
  city!: string;

  @Column({ type: DATE_COLUMN_TYPE, name: 'start_at' })
  startAt!: Date;

  @Column({ type: DATE_COLUMN_TYPE, name: 'end_at' })
  endAt!: Date;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: EventStatus,
    default: EventStatus.DRAFT,
  })
  status!: EventStatus;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: EventVisibility,
    default: EventVisibility.PUBLIC,
  })
  visibility!: EventVisibility;

  @Column({ type: 'varchar', name: 'cover_image_url', nullable: true })
  coverImageUrl!: string | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'organizer_id' })
  organizer!: User;

  @ManyToOne(() => EventCategory, (category) => category.events, {
    onDelete: 'RESTRICT',
  })
  @JoinColumn({ name: 'category_id' })
  category!: EventCategory;

  @OneToMany(() => TicketType, (ticketType) => ticketType.event)
  ticketTypes!: TicketType[];

  @OneToMany(() => Registration, (registration) => registration.event)
  registrations!: Registration[];
}
