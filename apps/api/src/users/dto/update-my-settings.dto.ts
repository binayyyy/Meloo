import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateMySettingsDto {
  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  marketingEnabled?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  privacyLevel?: string;

  @IsOptional()
  @IsBoolean()
  aiAssistEnabled?: boolean;
}

