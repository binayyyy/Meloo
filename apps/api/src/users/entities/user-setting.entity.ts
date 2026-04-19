import { Column, Entity, JoinColumn, OneToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity({ name: 'user_settings' })
export class UserSetting {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id', unique: true })
  userId!: string;

  @Column({ type: 'boolean', name: 'notifications_enabled', default: true })
  notificationsEnabled!: boolean;

  @Column({ type: 'boolean', name: 'marketing_enabled', default: false })
  marketingEnabled!: boolean;

  @Column({ type: 'varchar', name: 'privacy_level', default: 'contacts_only' })
  privacyLevel!: string;

  @Column({ type: 'boolean', name: 'ai_assist_enabled', default: true })
  aiAssistEnabled!: boolean;

  @OneToOne(() => User, (user) => user.setting, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;
}

