import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  IsUrl,
  MaxLength,
} from 'class-validator';
import { EventStatus, EventVisibility } from '../entities';

export class CreateEventDto {
  @IsString()
  @MaxLength(160)
  title!: string;

  @IsString()
  @MaxLength(4000)
  description!: string;

  @IsUUID()
  categoryId!: string;

  @IsString()
  @MaxLength(160)
  venue!: string;

  @IsString()
  @MaxLength(120)
  city!: string;

  @IsDateString()
  startAt!: string;

  @IsDateString()
  endAt!: string;

  @IsOptional()
  @IsEnum(EventStatus)
  status?: EventStatus;

  @IsOptional()
  @IsEnum(EventVisibility)
  visibility?: EventVisibility;

  @IsOptional()
  @IsUrl()
  coverImageUrl?: string;
}

