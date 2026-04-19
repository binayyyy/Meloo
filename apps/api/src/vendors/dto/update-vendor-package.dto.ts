import { IsNumberString, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateVendorPackageDto {
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
  price?: string;
}

