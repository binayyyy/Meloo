import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { User } from '../../users/entities';
import { Booking } from './booking.entity';
import { Refund } from './refund.entity';

export enum PaymentProvider {
  STRIPE = 'stripe',
}

export enum PaymentStatus {
  INITIATED = 'initiated',
  PAID = 'paid',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

@Entity({ name: 'payments' })
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'booking_id' })
  bookingId!: string;

  @Column({ type: 'uuid', name: 'payer_id' })
  payerId!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: PaymentProvider,
  })
  provider!: PaymentProvider;

  @Column({ type: 'varchar', name: 'provider_ref' })
  providerRef!: string;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  amount!: string;

  @Column({ type: 'varchar', default: 'USD' })
  currency!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: PaymentStatus,
    default: PaymentStatus.INITIATED,
  })
  status!: PaymentStatus;

  @Column({ type: DATE_COLUMN_TYPE, name: 'paid_at', nullable: true })
  paidAt!: Date | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => Booking, (booking) => booking.payments, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'booking_id' })
  booking!: Booking;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'payer_id' })
  payer!: User;

  @OneToMany(() => Refund, (refund) => refund.payment)
  refunds!: Refund[];
}
