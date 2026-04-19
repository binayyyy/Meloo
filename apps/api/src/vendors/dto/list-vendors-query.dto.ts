import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ListVendorsQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  category?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  serviceArea?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  search?: string;
}

