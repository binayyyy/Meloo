import { IsEnum, IsNumberString, IsString, MaxLength } from 'class-validator';
import { SponsorshipOpportunityStatus } from '../entities';

export class CreateSponsorshipOpportunityDto {
  @IsString()
  @MaxLength(160)
  title!: string;

  @IsString()
  @MaxLength(3000)
  description!: string;

  @IsNumberString()
  requiredAmount!: string;

  @IsString()
  @MaxLength(240)
  targetAudience!: string;

  @IsString()
  @MaxLength(3000)
  benefitsOffered!: string;

  @IsEnum(SponsorshipOpportunityStatus)
  status!: SponsorshipOpportunityStatus;
}

