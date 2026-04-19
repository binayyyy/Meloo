import { IsNumberString, IsString, MaxLength } from 'class-validator';

export class CreateVendorPackageDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(2000)
  description!: string;

  @IsNumberString()
  price!: string;
}

