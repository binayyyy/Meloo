import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { Event } from '../../events/entities';
import { User } from '../../users/entities';
import { VendorProfile } from './vendor-profile.entity';

export enum VendorRequestStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  DECLINED = 'declined',
  BOOKED = 'booked',
  CANCELLED = 'cancelled',
}

@Entity({ name: 'vendor_requests' })
export class VendorRequest {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'event_id' })
  eventId!: string;

  @Column({ type: 'uuid', name: 'organizer_id' })
  organizerId!: string;

  @Column({ type: 'uuid', name: 'vendor_id' })
  vendorId!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: VendorRequestStatus,
    default: VendorRequestStatus.PENDING,
  })
  status!: VendorRequestStatus;

  @Column({ type: 'text' })
  message!: string;

  @Column({
    type: 'numeric',
    precision: 12,
    scale: 2,
    name: 'proposed_budget',
  })
  proposedBudget!: string;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => Event, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'event_id' })
  event!: Event;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'organizer_id' })
  organizer!: User;

  @ManyToOne(() => VendorProfile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'vendor_id' })
  vendorProfile!: VendorProfile;
}
