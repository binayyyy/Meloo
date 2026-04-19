import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class ListEventsQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  search?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;
}

