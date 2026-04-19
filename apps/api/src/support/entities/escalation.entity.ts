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

export enum EscalationSourceType {
  SUPPORT_TICKET = 'support_ticket',
}

export enum EscalationStatus {
  OPEN = 'open',
  IN_REVIEW = 'in_review',
  RESOLVED = 'resolved',
}

@Entity({ name: 'escalations' })
export class Escalation {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: EscalationSourceType,
    name: 'source_type',
  })
  sourceType!: EscalationSourceType;

  @Column({ type: 'uuid', name: 'source_id' })
  sourceId!: string;

  @Column({ type: 'text' })
  reason!: string;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 2,
    name: 'ai_confidence',
  })
  aiConfidence!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: EscalationStatus,
    default: EscalationStatus.OPEN,
  })
  status!: EscalationStatus;

  @Column({ type: 'uuid', name: 'assigned_to', nullable: true })
  assignedTo!: string | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_to' })
  assignedAdmin!: User | null;
}
