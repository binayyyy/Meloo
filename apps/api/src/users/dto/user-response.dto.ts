import { Role } from '../../common/enums/role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { UserProfileDto } from './user-profile.dto';
import { UserSettingDto } from './user-setting.dto';

export class UserResponseDto {
  id!: string;
  email!: string;
  role!: Role;
  status!: UserStatus;
  profile!: UserProfileDto | null;
  settings!: UserSettingDto | null;
  createdAt!: Date;
  updatedAt!: Date;
}

