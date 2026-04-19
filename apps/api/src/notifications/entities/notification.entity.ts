import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { User } from '../../users/entities';

export enum NotificationType {
  SYSTEM = 'system',
  BOOKING = 'booking',
  PAYMENT = 'payment',
  VENDOR = 'vendor',
  SPONSOR = 'sponsor',
  CHAT = 'chat',
  SUPPORT = 'support',
}

@Entity({ name: 'notifications' })
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: NotificationType,
  })
  type!: NotificationType;

  @Column({ type: 'varchar' })
  title!: string;

  @Column({ type: 'text' })
  body!: string;

  @Column({ type: 'varchar', name: 'resource_type', nullable: true })
  resourceType!: string | null;

  @Column({ type: 'uuid', name: 'resource_id', nullable: true })
  resourceId!: string | null;

  @Column({ type: DATE_COLUMN_TYPE, name: 'read_at', nullable: true })
  readAt!: Date | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;
}
