import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class BootstrapLocalAdminDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  fullName?: string;
}
