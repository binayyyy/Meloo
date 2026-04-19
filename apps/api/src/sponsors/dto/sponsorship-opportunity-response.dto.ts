import { SponsorshipOpportunityStatus } from '../entities';

export class SponsorshipOpportunityEventSummaryDto {
  id!: string;
  title!: string;
  city!: string;
  venue!: string;
  startAt!: Date;
  endAt!: Date;
}

export class SponsorshipOpportunityResponseDto {
  id!: string;
  event!: SponsorshipOpportunityEventSummaryDto;
  organizerId!: string;
  title!: string;
  description!: string;
  requiredAmount!: string;
  targetAudience!: string;
  benefitsOffered!: string;
  status!: SponsorshipOpportunityStatus;
  createdAt!: Date;
}

