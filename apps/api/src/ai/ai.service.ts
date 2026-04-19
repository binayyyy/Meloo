import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from '../common/enums/role.enum';
import {
  AiSupportResponseDto,
  EventRecommendationResponseDto,
  OpportunityRecommendationResponseDto,
  PlanningAssistantRequestDto,
  PlanningAssistantResponseDto,
  VendorRecommendationResponseDto,
} from './dto';
import { Event, EventStatus, EventVisibility } from '../events/entities';
import { EventsService } from '../events/events.service';
import { SponsorProfile, SponsorshipOpportunity, SponsorshipOpportunityStatus } from '../sponsors/entities';
import { SponsorsService } from '../sponsors/sponsors.service';
import { UserProfile } from '../users/entities';
import { VendorProfile } from '../vendors/entities';
import { VendorsService } from '../vendors/vendors.service';
import { AiGatewayService } from './ai-gateway.service';

@Injectable()
export class AiService {
  constructor(
    private readonly aiGatewayService: AiGatewayService,
    private readonly eventsService: EventsService,
    private readonly vendorsService: VendorsService,
    private readonly sponsorsService: SponsorsService,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(VendorProfile)
    private readonly vendorProfilesRepository: Repository<VendorProfile>,
    @InjectRepository(SponsorProfile)
    private readonly sponsorProfilesRepository: Repository<SponsorProfile>,
    @InjectRepository(SponsorshipOpportunity)
    private readonly sponsorshipOpportunitiesRepository: Repository<SponsorshipOpportunity>,
    @InjectRepository(UserProfile)
    private readonly userProfilesRepository: Repository<UserProfile>,
  ) {}

  async generateSupportAssistance(
    category: string | undefined,
    message: string,
  ): Promise<AiSupportResponseDto> {
    const modelResponse = await this.aiGatewayService.generateJson<AiSupportResponseDto>([
      {
        role: 'system',
        content:
          'You are an event-platform support triage assistant. Return strict JSON with keys: suggestion, confidence, priority, shouldEscalate, escalationReason. Confidence must be a string decimal from 0.00 to 1.00. Priority must be one of urgent, high, medium, low. Only escalate for payment, harassment, safety, refund/dispute, or explicit human-request cases.',
      },
      {
        role: 'user',
        content: JSON.stringify({
          category: category ?? null,
          message,
        }),
      },
    ]);

    if (modelResponse != null) {
      return {
        suggestion: modelResponse.suggestion,
        confidence: modelResponse.confidence,
        priority: modelResponse.priority,
        shouldEscalate: modelResponse.shouldEscalate,
        escalationReason: modelResponse.escalationReason,
      };
    }

    return this.buildFallbackSupportAssistance(category, message);
  }

  private buildFallbackSupportAssistance(
    category: string | undefined,
    message: string,
  ): AiSupportResponseDto {
    const normalized = message.toLowerCase();
    const normalizedCategory = category?.toLowerCase();
    const containsAny = (terms: string[]) => terms.some((term) => normalized.includes(term));

    const paymentIssue =
      normalizedCategory === 'payment' ||
      containsAny(['payment', 'charged', 'refund', 'card', 'billing', 'dispute']);
    const harassmentIssue =
      normalizedCategory === 'harassment' ||
      containsAny(['harassment', 'abuse', 'threat', 'unsafe', 'report']);
    const accountIssue =
      normalizedCategory === 'account' ||
      containsAny(['login', 'password', 'account', 'verify', 'locked']);
    const technicalIssue =
      normalizedCategory === 'technical' ||
      containsAny(['bug', 'error', 'crash', 'not working', 'failed']);
    const humanRequest = containsAny(['human', 'person', 'admin', 'agent']);

    if (paymentIssue) {
      return {
        suggestion:
          'A payment specialist should review this. Please avoid retrying the same charge until an admin confirms payment state.',
        confidence: '0.88',
        priority: 'urgent',
        shouldEscalate: true,
        escalationReason: 'Payment, refund, or billing issue requires manual review.',
      };
    }

    if (harassmentIssue) {
      return {
        suggestion:
          'Your report has been prioritized for human review. Avoid further direct contact until an admin responds.',
        confidence: '0.92',
        priority: 'urgent',
        shouldEscalate: true,
        escalationReason: 'Harassment or safety-related issue requires immediate admin handling.',
      };
    }

    if (humanRequest) {
      return {
        suggestion:
          'A human admin will review this ticket shortly. Include any booking IDs, event names, or participant names that will help triage faster.',
        confidence: '0.58',
        priority: 'high',
        shouldEscalate: true,
        escalationReason: 'User explicitly requested human support.',
      };
    }

    if (accountIssue) {
      return {
        suggestion:
          'Account issues are often resolved by resetting your password, checking the email used to sign in, and confirming your account status. An admin can step in if the issue persists.',
        confidence: '0.79',
        priority: 'high',
        shouldEscalate: false,
        escalationReason: null,
      };
    }

    if (technicalIssue) {
      return {
        suggestion:
          'Please retry on a stable connection and include the exact step where the issue occurred. If the problem is repeatable, mention the event or screen involved so support can reproduce it.',
        confidence: '0.74',
        priority: 'medium',
        shouldEscalate: false,
        escalationReason: null,
      };
    }

    return {
      suggestion:
        'Please include the event name, booking reference, or the exact workflow you were following. Support can respond faster when the impact and expected result are clear.',
      confidence: '0.64',
      priority: 'medium',
      shouldEscalate: false,
      escalationReason: null,
    };
  }

  async recommendEventsForUser(userId: string): Promise<EventRecommendationResponseDto[]> {
    const events = await this.eventsRepository.find({
      where: {
        status: EventStatus.PUBLISHED,
        visibility: EventVisibility.PUBLIC,
      },
      relations: { category: true },
      order: { startAt: 'ASC' },
      take: 6,
    });

    const profile = await this.userProfilesRepository.findOne({ where: { userId } });
    const profileText = `${profile?.bio ?? ''} ${profile?.fullName ?? ''}`.toLowerCase();

    return events.map((event) => {
      let score = 0.6;
      let reasonSummary = 'Upcoming public event ranked for near-term availability.';
      if (profileText.includes(event.city.toLowerCase())) {
        score += 0.2;
        reasonSummary = `Matches your profile context for ${event.city}.`;
      }
      if (profileText.includes(event.category.name.toLowerCase())) {
        score += 0.15;
        reasonSummary = `Matches interests mentioned in your profile and the ${event.category.name} category.`;
      }
      return {
        score: Number(score.toFixed(2)),
        reasonSummary,
        event: this.eventsService.toEventResponse(event),
      };
    });
  }

  async recommendVendorsForEvent(
    requesterId: string,
    role: Role,
    eventId: string,
  ): Promise<VendorRecommendationResponseDto[]> {
    const event = await this.eventsRepository.findOne({
      where: { id: eventId },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (role !== Role.ADMIN && event.organizerId !== requesterId) {
      throw new ForbiddenException('You cannot request vendor recommendations for this event');
    }

    const vendors = await this.vendorProfilesRepository.find({
      relations: {
        services: true,
        packages: true,
        bookingPreference: true,
      },
      order: { verified: 'DESC', businessName: 'ASC' },
      take: 8,
    });

    return vendors
      .map((vendor) => this.toVendorRecommendation(vendor, event.city))
      .sort((left, right) => right.score - left.score)
      .slice(0, 6);
  }

  async recommendOpportunitiesForSponsor(
    userId: string,
  ): Promise<OpportunityRecommendationResponseDto[]> {
    const sponsorProfile = await this.sponsorProfilesRepository.findOne({
      where: { userId },
    });

    const opportunities = await this.sponsorshipOpportunitiesRepository.find({
      where: { status: SponsorshipOpportunityStatus.OPEN },
      relations: { event: true },
      order: { createdAt: 'DESC' },
      take: 8,
    });

    const industries = sponsorProfile?.industries.toLowerCase() ?? '';

    return opportunities
      .map((opportunity) => {
        const haystack =
          `${opportunity.title} ${opportunity.description} ${opportunity.targetAudience}`.toLowerCase();
        let score = 0.58;
        let reasonSummary =
          'Open sponsorship opportunity ranked by active availability and audience clarity.';
        if (industries.length > 0 && industries.split(',').some((term) => haystack.includes(term.trim()))) {
          score += 0.22;
          reasonSummary =
            'Opportunity audience or description matches industries listed in your sponsor profile.';
        }
        if (Number.parseFloat(opportunity.requiredAmount) <= 5000) {
          score += 0.08;
        }
        return {
          score: Number(score.toFixed(2)),
          reasonSummary,
          opportunity: this.sponsorsService.toOpportunityResponse(opportunity),
        };
      })
      .sort((left, right) => right.score - left.score)
      .slice(0, 6);
  }

  async generatePlanningAssistant(
    requesterId: string,
    role: Role,
    dto: PlanningAssistantRequestDto,
  ): Promise<PlanningAssistantResponseDto> {
    let event: Event | null = null;
    if (dto.eventId != null) {
      event = await this.eventsRepository.findOne({
        where: { id: dto.eventId },
        relations: { category: true },
      });

      if (!event) {
        throw new NotFoundException('Event not found');
      }

      if (role !== Role.ADMIN && event.organizerId !== requesterId) {
        throw new ForbiddenException('You cannot generate a planning brief for this event');
      }
    }

    const categoryName = event?.category.name ?? 'general';
    const city = event?.city ?? 'your target city';
    const attendeeCount = dto.expectedAttendees ?? 150;
    const budgetValue = Number.parseFloat(dto.budget ?? '0');
    const budgetText =
      Number.isFinite(budgetValue) && budgetValue > 0
        ? `around ${budgetValue.toFixed(2)} USD`
        : 'an unspecific working budget';
    const planningGoal = dto.planningGoal?.trim() ?? 'deliver a smooth attendee experience';

    const vendorCategories = this.pickVendorCategories(categoryName, attendeeCount);
    const timelineMilestones = this.buildTimeline(event?.startAt, attendeeCount);
    const fallback = this.buildFallbackPlanningAssistant(
      event,
      categoryName,
      city,
      attendeeCount,
      budgetText,
      planningGoal,
      vendorCategories,
      timelineMilestones,
    );

    const modelResponse =
      await this.aiGatewayService.generateJson<PlanningAssistantResponseDto>([
        {
          role: 'system',
          content:
            'You are an event-planning copilot for organizers. Return strict JSON with keys: overview, checklist, vendorCategories, timelineMilestones, sponsorshipAngles, budgetGuidance, operationalRisks. Each list should contain concise, practical bullets for a real production event workflow.',
        },
        {
          role: 'user',
          content: JSON.stringify({
            eventTitle: event?.title ?? null,
            categoryName,
            city,
            attendeeCount,
            budgetText,
            planningGoal,
            seededVendorCategories: vendorCategories,
            seededTimelineMilestones: timelineMilestones,
          }),
        },
      ]);

    if (modelResponse == null) {
      return fallback;
    }

    return {
      overview: modelResponse.overview,
      vendorCategories:
        modelResponse.vendorCategories.length > 0
          ? modelResponse.vendorCategories
          : fallback.vendorCategories,
      timelineMilestones:
        modelResponse.timelineMilestones.length > 0
          ? modelResponse.timelineMilestones
          : fallback.timelineMilestones,
      sponsorshipAngles:
        modelResponse.sponsorshipAngles.length > 0
          ? modelResponse.sponsorshipAngles
          : fallback.sponsorshipAngles,
      budgetGuidance:
        modelResponse.budgetGuidance.length > 0
          ? modelResponse.budgetGuidance
          : fallback.budgetGuidance,
      operationalRisks:
        modelResponse.operationalRisks.length > 0
          ? modelResponse.operationalRisks
          : fallback.operationalRisks,
      checklist:
        modelResponse.checklist.length > 0
          ? modelResponse.checklist
          : fallback.checklist,
    };
  }

  private buildFallbackPlanningAssistant(
    event: Event | null,
    categoryName: string,
    city: string,
    attendeeCount: number,
    budgetText: string,
    planningGoal: string,
    vendorCategories: string[],
    timelineMilestones: string[],
  ): PlanningAssistantResponseDto {
    return {
      overview:
        event == null
          ? `Plan for a ${categoryName} event in ${city} with ${attendeeCount} attendees and ${budgetText}. The current goal is to ${planningGoal}.`
          : `${event.title} should focus on a controlled rollout for ${attendeeCount} attendees in ${city}. The main objective is to ${planningGoal} without losing schedule discipline.`,
      checklist: [
        'Confirm venue access window, staffing ownership, and final run-of-show.',
        'Lock ticket sales checkpoints and monitor inventory daily once sales open.',
        `Confirm vendor coverage for ${vendorCategories.slice(0, 3).join(', ')}, then assign owners for each dependency.`,
        'Prepare attendee communications for confirmation, reminder, and day-of logistics.',
        'Set escalation contacts for payment issues, no-show vendors, and urgent support.',
      ],
      vendorCategories,
      timelineMilestones,
      sponsorshipAngles: [
        `Pitch sponsors on audience fit, especially if the event is aligned with ${categoryName}.`,
        `Use ${city} as a local relevance angle in sponsorship outreach and partner decks.`,
        'Package sponsor benefits into visibility, attendee engagement, and on-site placement tiers.',
      ],
      budgetGuidance: [
        `Treat ${budgetText} as a control limit and reserve at least 10% for operational contingencies.`,
        'Prioritize venue, attendee experience, and critical vendors before decorative scope.',
        attendeeCount >= 250
          ? 'Add explicit staffing and crowd-flow coverage into the operating budget.'
          : 'Keep staffing lean but assign one owner to attendee check-in and issue handling.',
      ],
      operationalRisks: [
        'Late vendor confirmation can break setup sequencing and attendee communications.',
        'Weak payment/support escalation coverage will create avoidable churn close to event day.',
        attendeeCount >= 250
          ? 'Higher attendee volume increases queue, support, and capacity risk.'
          : 'Smaller events still fail when sponsor, vendor, and venue owners are not clearly assigned.',
      ],
    };
  }

  private toVendorRecommendation(
    vendor: VendorProfile,
    eventCity: string,
  ): VendorRecommendationResponseDto {
    let score = vendor.verified ? 0.7 : 0.48;
    let reasonSummary = vendor.verified
      ? 'Verified vendor ranked above unverified profiles.'
      : 'Unverified vendor included because profile coverage is relevant.';

    if (vendor.serviceArea.toLowerCase().includes(eventCity.toLowerCase())) {
      score += 0.18;
      reasonSummary = `Service area includes ${eventCity}, which aligns with the event location.`;
    }

    if (vendor.bookingPreference?.allowDirectBooking === true) {
      score += 0.08;
    }

    return {
      score: Number(score.toFixed(2)),
      reasonSummary,
      vendor: this.vendorsService.toVendorProfileResponse(vendor),
    };
  }

  private pickVendorCategories(categoryName: string, attendeeCount: number): string[] {
    const normalizedCategory = categoryName.toLowerCase();
    const base = ['Venue operations', 'Photography', 'AV / production'];

    if (normalizedCategory.includes('music')) {
      base.push('Stage management', 'Lighting', 'Security');
    } else if (normalizedCategory.includes('food')) {
      base.push('Catering', 'Guest experience', 'Logistics');
    } else if (normalizedCategory.includes('business') || normalizedCategory.includes('education')) {
      base.push('Registration desk', 'Branding / signage', 'Streaming support');
    } else {
      base.push('Catering', 'Guest experience');
    }

    if (attendeeCount >= 250) {
      base.push('Crowd management');
    }

    return Array.from(new Set(base));
  }

  private buildTimeline(startAt: Date | undefined, attendeeCount: number): string[] {
    const daysOut = attendeeCount >= 250 ? [56, 35, 14, 7, 1] : [42, 21, 10, 3, 1];
    return daysOut.map((days) => {
      if (startAt == null) {
        return `${days} days before launch: confirm owners, dependencies, and communication checkpoints.`;
      }

      const milestoneDate = new Date(startAt.getTime() - days * 24 * 60 * 60 * 1000);
      return `${milestoneDate.toISOString().slice(0, 10)}: finalize the ${days}-day planning checkpoint.`;
    });
  }
}
