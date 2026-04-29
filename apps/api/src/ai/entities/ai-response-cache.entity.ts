import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE } from '../../database/database-column-types';

@Entity({ name: 'ai_response_cache' })
@Index(['cacheKey'], { unique: true })
export class AiResponseCache {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', name: 'cache_key' })
  cacheKey!: string;

  @Column({ type: 'varchar', name: 'use_case' })
  useCase!: string;

  @Column({ type: 'uuid', name: 'user_id', nullable: true })
  userId!: string | null;

  @Column({ type: 'varchar', nullable: true })
  role!: string | null;

  @Column({ type: 'varchar' })
  provider!: string;

  @Column({ type: 'varchar' })
  model!: string;

  @Column({ type: 'text', name: 'payload_json' })
  payloadJson!: string;

  @Column({ type: 'varchar', name: 'context_digest' })
  contextDigest!: string;

  @Column({ type: DATE_COLUMN_TYPE, name: 'expires_at' })
  expiresAt!: Date;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;
}
