import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

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

  @IsOptional()
  @IsUrl()
  logoUrl?: string;

  @IsOptional()
  @IsUrl()
  websiteUrl?: string;

  @IsOptional()
  @IsUrl()
  verificationDocumentUrl?: string;
}
