import { Type } from 'class-transformer';
import { IsOptional, ValidateNested } from 'class-validator';
import { UpdateMyProfileDto } from './update-my-profile.dto';
import { UpdateMySettingsDto } from './update-my-settings.dto';

export class UpdateMeDto {
  @IsOptional()
  @ValidateNested()
  @Type(() => UpdateMyProfileDto)
  profile?: UpdateMyProfileDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => UpdateMySettingsDto)
  settings?: UpdateMySettingsDto;
}

