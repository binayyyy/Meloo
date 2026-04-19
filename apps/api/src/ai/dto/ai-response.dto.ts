import { EventResponseDto } from '../../events/dto';
import { SponsorshipOpportunityResponseDto } from '../../sponsors/dto';
import { VendorProfileResponseDto } from '../../vendors/dto';

export class AiSupportResponseDto {
  suggestion!: string;
  confidence!: string;
  priority!: string;
  shouldEscalate!: boolean;
  escalationReason!: string | null;
}

export class EventRecommendationResponseDto {
  score!: number;
  reasonSummary!: string;
  event!: EventResponseDto;
}

export class VendorRecommendationResponseDto {
  score!: number;
  reasonSummary!: string;
  vendor!: VendorProfileResponseDto;
}

export class OpportunityRecommendationResponseDto {
  score!: number;
  reasonSummary!: string;
  opportunity!: SponsorshipOpportunityResponseDto;
}
