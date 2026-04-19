import { IsNumberString, IsString, MaxLength } from 'class-validator';

export class CreateVendorServiceDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(2000)
  description!: string;

  @IsNumberString()
  basePrice!: string;

  @IsString()
  @MaxLength(80)
  pricingModel!: string;
}

