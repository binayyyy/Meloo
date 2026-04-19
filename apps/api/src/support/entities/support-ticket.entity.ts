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
import { User } from '../../users/entities';

export enum SupportTicketCategory {
  GENERAL = 'general',
  BOOKING = 'booking',
  PAYMENT = 'payment',
  ACCOUNT = 'account',
  HARASSMENT = 'harassment',
  TECHNICAL = 'technical',
}

export enum SupportTicketStatus {
  OPEN = 'open',
  IN_PROGRESS = 'in_progress',
  RESOLVED = 'resolved',
  CLOSED = 'closed',
}

export enum SupportTicketPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent',
}

@Entity({ name: 'support_tickets' })
export class SupportTicket {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: SupportTicketCategory,
  })
  category!: SupportTicketCategory;

  @Column({ type: 'varchar' })
  subject!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: SupportTicketStatus,
    default: SupportTicketStatus.OPEN,
  })
  status!: SupportTicketStatus;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: SupportTicketPriority,
    default: SupportTicketPriority.MEDIUM,
  })
  priority!: SupportTicketPriority;

  @Column({ type: 'uuid', name: 'assigned_admin_id', nullable: true })
  assignedAdminId!: string | null;

  @Column({ type: 'text', name: 'assistant_suggestion', nullable: true })
  assistantSuggestion!: string | null;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 2,
    name: 'ai_confidence',
    nullable: true,
  })
  aiConfidence!: string | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_admin_id' })
  assignedAdmin!: User | null;
}
