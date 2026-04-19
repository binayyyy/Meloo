import { IsNumberString, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateVendorServiceDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsNumberString()
  basePrice?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  pricingModel?: string;
}

