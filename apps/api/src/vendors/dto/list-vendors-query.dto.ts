import { Transform, Type } from 'class-transformer';
import { IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

function toOptionalNumber(value: unknown): unknown {
  if (value == null || value == '') {
    return undefined;
  }

  const parsed = Number(value);
  return Number.isNaN(parsed) ? value : parsed;
}

function roundOptionalNumber(
  value: unknown,
  maxDecimalPlaces: number,
): unknown {
  const parsed = toOptionalNumber(value);
  if (typeof parsed !== 'number') {
    return parsed;
  }

  return Number(parsed.toFixed(maxDecimalPlaces));
}

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

  @IsOptional()
  @Transform(({ value }) => roundOptionalNumber(value, 6))
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @Transform(({ value }) => roundOptionalNumber(value, 6))
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 6 })
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsOptional()
  @Transform(({ value }) => roundOptionalNumber(value, 2))
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(500)
  radiusKm?: number;
}
