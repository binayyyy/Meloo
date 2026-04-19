import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';
import { DATE_COLUMN_TYPE } from '../../database/database-column-types';

@Entity({ name: 'sessions' })
export class Session {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  @Column({ type: 'varchar', name: 'refresh_token_hash' })
  refreshTokenHash!: string;

  @Column({ type: 'varchar', name: 'device_info', nullable: true })
  deviceInfo!: string | null;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @Column({ type: DATE_COLUMN_TYPE, name: 'expires_at' })
  expiresAt!: Date;

  @ManyToOne(() => User, (user) => user.sessions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;
}
