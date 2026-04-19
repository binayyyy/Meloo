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
import { DATE_COLUMN_TYPE } from '../../database/database-column-types';
import { Event } from '../../events/entities';
import { Registration } from './registration.entity';

@Entity({ name: 'ticket_types' })
export class TicketType {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'event_id' })
  eventId!: string;

  @Column({ type: 'varchar' })
  name!: string;

  @Column({ type: 'numeric', precision: 10, scale: 2 })
  price!: string;

  @Column({ type: 'integer' })
  quantity!: number;

  @Column({ type: 'integer' })
  remaining!: number;

  @Column({ type: DATE_COLUMN_TYPE, name: 'sale_start_at' })
  saleStartAt!: Date;

  @Column({ type: DATE_COLUMN_TYPE, name: 'sale_end_at' })
  saleEndAt!: Date;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => Event, (event) => event.ticketTypes, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'event_id' })
  event!: Event;

  @OneToMany(() => Registration, (registration) => registration.ticketType)
  registrations!: Registration[];
}
