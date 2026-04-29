import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE } from '../../database/database-column-types';

export enum AiContextScopeType {
  CONVERSATION = 'conversation',
  EVENT = 'event',
  SUPPORT_TICKET = 'support_ticket',
  USER = 'user',
}

@Entity({ name: 'ai_context_documents' })
@Index(['scopeType', 'scopeId', 'sourceType'], { unique: true })
export class AiContextDocument {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', name: 'scope_type' })
  scopeType!: AiContextScopeType;

  @Column({ type: 'varchar', name: 'scope_id' })
  scopeId!: string;

  @Column({ type: 'varchar', name: 'source_type' })
  sourceType!: string;

  @Column({ type: 'varchar' })
  title!: string;

  @Column({ type: 'text' })
  body!: string;

  @Column({ type: 'simple-array', nullable: true })
  keywords!: string[] | null;

  @Column({ type: 'simple-json', nullable: true })
  metadata!: Record<string, unknown> | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;
}
