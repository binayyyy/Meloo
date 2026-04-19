import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Role } from '../../common/enums/role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { EmailVerificationToken } from './email-verification-token.entity';
import { PasswordResetToken } from './password-reset-token.entity';
import { Session } from './session.entity';
import { UserProfile } from './user-profile.entity';
import { UserSetting } from './user-setting.entity';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', unique: true })
  email!: string;

  @Column({ type: 'varchar', name: 'password_hash' })
  passwordHash!: string;

  @Column({ type: ENUM_COLUMN_TYPE, enum: Role })
  role!: Role;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: UserStatus,
    default: UserStatus.PENDING_VERIFICATION,
  })
  status!: UserStatus;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @OneToOne(() => UserProfile, (profile) => profile.user)
  profile!: UserProfile | null;

  @OneToOne(() => UserSetting, (setting) => setting.user)
  setting!: UserSetting | null;

  @OneToMany(() => Session, (session) => session.user)
  sessions!: Session[];

  @OneToMany(() => PasswordResetToken, (token) => token.user)
  passwordResetTokens!: PasswordResetToken[];

  @OneToMany(() => EmailVerificationToken, (token) => token.user)
  emailVerificationTokens!: EmailVerificationToken[];
}
