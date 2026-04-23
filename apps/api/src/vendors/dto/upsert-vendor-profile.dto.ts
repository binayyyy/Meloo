import { Type } from 'class-transformer';
import { IsNumber, IsOptional, IsString, IsUrl, Max, MaxLength, Min } from 'class-validator';

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

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(500)
  travelRadiusKm?: number;

  @IsOptional()
  @IsUrl()
  portfolioImageUrl?: string;

  @IsOptional()
  @IsUrl()
  verificationDocumentUrl?: string;
}
