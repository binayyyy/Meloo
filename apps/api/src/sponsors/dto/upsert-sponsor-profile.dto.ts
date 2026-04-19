import { IsString, MaxLength } from 'class-validator';

export class UpsertSponsorProfileDto {
  @IsString()
  @MaxLength(160)
  companyName!: string;

  @IsString()
  @MaxLength(3000)
  description!: string;

  @IsString()
  @MaxLength(240)
  industries!: string;
}

