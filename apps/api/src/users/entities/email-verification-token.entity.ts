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

@Entity({ name: 'email_verification_tokens' })
export class EmailVerificationToken {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  @Column({ type: 'varchar', name: 'token_hash' })
  tokenHash!: string;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @Column({ type: DATE_COLUMN_TYPE, name: 'expires_at' })
  expiresAt!: Date;

  @Column({ type: DATE_COLUMN_TYPE, name: 'consumed_at', nullable: true })
  consumedAt!: Date | null;

  @ManyToOne(() => User, (user) => user.emailVerificationTokens, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user!: User;
}
