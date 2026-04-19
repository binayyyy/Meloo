import { IsString, MaxLength } from 'class-validator';

export class UpsertVendorProfileDto {
  @IsString()
  @MaxLength(140)
  businessName!: string;

  @IsString()
  @MaxLength(3000)
  description!: string;

  @IsString()
  @MaxLength(120)
  category!: string;

  @IsString()
  @MaxLength(160)
  serviceArea!: string;
}

