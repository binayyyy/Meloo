import {
  IsEmail,
  IsEnum,
  IsNotIn,
  IsString,
  MinLength,
} from 'class-validator';
import { Role } from '../../common/enums/role.enum';

export class SignUpDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsEnum(Role)
  @IsNotIn([Role.ADMIN], {
    message: 'Admin accounts cannot be created through public sign up',
  })
  role!: Role;
}
