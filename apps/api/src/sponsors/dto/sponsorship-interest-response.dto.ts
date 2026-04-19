import { SponsorshipInterestStatus } from '../entities';
import { SponsorProfileResponseDto } from './sponsor-profile-response.dto';
import { SponsorshipOpportunityResponseDto } from './sponsorship-opportunity-response.dto';

export class SponsorshipInterestResponseDto {
  id!: string;
  sponsor!: SponsorProfileResponseDto;
  opportunity!: SponsorshipOpportunityResponseDto;
  status!: SponsorshipInterestStatus;
  message!: string;
  createdAt!: Date;
}

