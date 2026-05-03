import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConversationParticipant, ConversationType, Message, MessageType } from '../chat/entities';
import { Role } from '../common/enums/role.enum';
import {
  AiAssistantDraftIntent,
  AiAssistantDraftRequestDto,
  AiAssistantDraftResponseDto,
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
import { AiContextService } from './ai-context.service';
import { AiHarnessService } from './ai-harness.service';
import {
  hasCoordinates,
  haversineDistanceKm,
  toNullableNumber,
} from '../common/utils/distance.util';

type ConversationAiContext = {
  participants: ConversationParticipant[];
  counterpart: ConversationParticipant | null;
  recentMessages: Message[];
};

@Injectable()
export class AiService {
  constructor(
    private readonly aiGatewayService: AiGatewayService,
    private readonly aiHarnessService: AiHarnessService,
    private readonly aiContextService: AiContextService,
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
    @InjectRepository(ConversationParticipant)
    private readonly conversationParticipantsRepository: Repository<ConversationParticipant>,
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
  ) {}

  async generateSupportAssistance(
    category: string | undefined,
    message: string,
    options?: {
      requesterId?: string;
      actingRole?: Role;
      subject?: string;
    },
  ): Promise<AiSupportResponseDto> {
    const modelResponse = await this.aiHarnessService.generateSupportTriage({
      requesterId: options?.requesterId,
      actingRole: options?.actingRole,
      category,
      subject: options?.subject,
      message,
    });

    if (modelResponse != null) {
      const fallback = this.buildFallbackSupportAssistance(category, message);
      const normalizedCategory = category?.toLowerCase();
      if (this.shouldUseFallbackSupportSuggestion(normalizedCategory, modelResponse.suggestion)) {
        return fallback;
      }

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
    const locationSignals = this.extractLocationSignals(profileText);

    return events.map((event) => {
      let score = 0.48;
      const reasons: string[] = [];
      const eventText =
        `${event.title} ${event.description} ${event.category.name} ${event.city}`.toLowerCase();
      if (locationSignals.has(event.city.toLowerCase())) {
        score += 0.2;
        reasons.push(`profile mentions ${event.city}`);
      }
      if (profileText.includes(event.category.name.toLowerCase())) {
        score += 0.18;
        reasons.push(`profile interest aligns with ${event.category.name}`);
      }
      if (
        ['technology', 'business', 'music', 'food', 'culture', 'education', 'community']
          .some((term) => profileText.includes(term) && eventText.includes(term))
      ) {
        score += 0.08;
        reasons.push('theme overlap with profile interests');
      }
      const daysUntilStart =
        (event.startAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
      if (daysUntilStart >= 0 && daysUntilStart <= 30) {
        score += 0.06;
        reasons.push('happening soon');
      }
      return {
        score: Number(Math.max(0, Math.min(1, score)).toFixed(2)),
        reasonSummary:
          reasons.length > 0
            ? `${reasons.slice(0, 3).join(', ')}.`
            : 'Upcoming public event ranked for availability and category relevance.',
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
      .map((vendor) => this.toVendorRecommendation(vendor, event))
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
      relations: { event: { category: true } },
      order: { createdAt: 'DESC' },
      take: 8,
    });

    const profileText = [
      sponsorProfile?.industries ?? '',
      sponsorProfile?.description ?? '',
      sponsorProfile?.companyName ?? '',
    ]
      .join(' ')
      .toLowerCase();

    return opportunities
      .map((opportunity) => {
        const haystack = [
          opportunity.title,
          opportunity.description,
          opportunity.targetAudience,
          opportunity.benefitsOffered,
          opportunity.event.title,
          opportunity.event.city,
          opportunity.event.category?.name ?? '',
        ]
          .join(' ')
          .toLowerCase();
        let score = 0.46;
        const reasons: string[] = [];
        const industryMatches = profileText
          .split(',')
          .map((term) => term.trim())
          .filter((term) => term.length > 0 && haystack.includes(term));
        if (industryMatches.length > 0) {
          score += 0.22;
          reasons.push(`industry overlap with ${industryMatches.slice(0, 2).join(' and ')}`);
        }
        if (profileText.includes(opportunity.event.city.toLowerCase())) {
          score += 0.14;
          reasons.push(`profile context matches ${opportunity.event.city}`);
        }
        if (
          opportunity.event.category?.name &&
          profileText.includes(opportunity.event.category.name.toLowerCase())
        ) {
          score += 0.12;
          reasons.push(`category fit for ${opportunity.event.category.name}`);
        }
        if (Number.parseFloat(opportunity.requiredAmount) <= 5000) {
          score += 0.08;
          reasons.push('entry budget is comparatively accessible');
        }
        return {
          score: Number(Math.max(0, Math.min(1, score)).toFixed(2)),
          reasonSummary:
            reasons.length > 0
              ? `${reasons.slice(0, 3).join(', ')}.`
              : 'Open sponsorship opportunity ranked by availability and audience clarity.',
          opportunity: this.sponsorsService.toOpportunityResponse(opportunity),
        };
      })
      .sort((left, right) => right.score - left.score)
      .slice(0, 6);
  }

  async generateAssistantDraft(
    userId: string,
    role: Role,
    dto: AiAssistantDraftRequestDto,
  ): Promise<AiAssistantDraftResponseDto> {
    await this.aiContextService.requireAiActor(userId, role);

    switch (dto.intent) {
      case AiAssistantDraftIntent.CHAT_REPLY: {
        if (dto.conversationId == null) {
          throw new NotFoundException('Conversation is required for an AI reply draft');
        }

        return {
          intent: dto.intent,
          title: 'AI message draft',
          content:
            (await this.aiHarnessService.generateChatDraft({
              userId,
              role,
              conversationId: dto.conversationId,
              prompt: dto.prompt,
              intent: dto.intent,
              eventId: dto.eventId,
            })) ??
            (await this.generateConversationDraft(
              userId,
              role,
              dto.conversationId,
              dto.prompt,
              'Draft a concise reply for the user to send next. Keep it natural, specific, and under 120 words. Do not use markdown.',
            )),
        };
      }
      case AiAssistantDraftIntent.ORGANIZER_PLAN: {
        return {
          intent: dto.intent,
          title: 'Planning action draft',
          content: await this.generateOrganizerPlanDraft(userId, role, dto),
        };
      }
      case AiAssistantDraftIntent.VENDOR_PROPOSAL: {
        return {
          intent: dto.intent,
          title: 'Vendor proposal draft',
          content:
            (dto.conversationId != null
              ? await this.aiHarnessService.generateChatDraft({
                  userId,
                  role,
                  conversationId: dto.conversationId,
                  prompt: dto.prompt,
                  intent: dto.intent,
                  eventId: dto.eventId,
                })
              : null) ??
            (await this.generateProposalDraft(
              userId,
              role,
              dto,
              Role.VENDOR,
              'Draft a vendor proposal that can be sent directly in chat. Be concrete about scope, availability assumptions, pricing posture, and the next step. Keep it under 170 words and do not use markdown.',
            )),
        };
      }
      case AiAssistantDraftIntent.SPONSOR_PROPOSAL: {
        return {
          intent: dto.intent,
          title: 'Sponsor proposal draft',
          content:
            (dto.conversationId != null
              ? await this.aiHarnessService.generateChatDraft({
                  userId,
                  role,
                  conversationId: dto.conversationId,
                  prompt: dto.prompt,
                  intent: dto.intent,
                  eventId: dto.eventId,
                })
              : null) ??
            (await this.generateProposalDraft(
              userId,
              role,
              dto,
              Role.SPONSOR,
              'Draft a sponsor outreach or response proposal that can be sent directly in chat. Focus on audience fit, activation value, and a clear next step. Keep it under 170 words and do not use markdown.',
            )),
        };
      }
    }
  }

  async generateChatAutoReply(
    replyingUserId: string,
    role: Role,
    conversationId: string,
  ): Promise<string> {
    return this.generateConversationDraft(
      replyingUserId,
      role,
      conversationId,
      null,
      'Draft a short automatic acknowledgement reply for this user. Keep it to one or two sentences, be operationally helpful, and ask for the single most useful missing detail when relevant. Do not mention AI and do not use markdown.',
      true,
    );
  }

  async generatePlanningAssistant(
    requesterId: string,
    role: Role,
    dto: PlanningAssistantRequestDto,
  ): Promise<PlanningAssistantResponseDto> {
    const planningContext = await this.aiContextService.buildPlanningContext(
      requesterId,
      role,
      dto,
    );
    const event = planningContext.event;

    const categoryName = event?.category.name ?? 'general';
    const city = event?.city ?? 'your target city';
    const attendeeCount = dto.expectedAttendees ?? 150;
    const budgetValue = Number.parseFloat(dto.budget ?? '0');
    const budgetText =
      Number.isFinite(budgetValue) && budgetValue > 0
        ? `a working budget of ${budgetValue.toFixed(0)}`
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

    const modelResponse = await this.aiHarnessService.buildPlanningRuntimeContext(
      requesterId,
      role,
      [
        ...planningContext.sections,
        {
          label: 'Planning seed',
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
      ],
      'Generate the planning brief as structured JSON.',
      planningContext.cacheScope,
    );

    if (modelResponse == null) {
      return fallback;
    }

    return {
      overview:
        this.shouldUseFallbackPlanningOverview(
          event,
          city,
          modelResponse.overview,
        )
          ? fallback.overview
          : modelResponse.overview,
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
    event: Event,
  ): VendorRecommendationResponseDto {
    let score = vendor.verified ? 0.52 : 0.34;
    const reasons: string[] = [];
    if (vendor.verified) {
      reasons.push('verified profile');
    }

    const eventCategory = event.category.name.toLowerCase();
    const vendorCategory = vendor.category.toLowerCase();
    const vendorDescription = vendor.description.toLowerCase();
    const serviceText = vendor.services
      .map((service) => `${service.name} ${service.description}`.toLowerCase())
      .join(' ');
    const packageText = vendor.packages
      .map((item) => `${item.name} ${item.description}`.toLowerCase())
      .join(' ');

    const categoryAligned =
      vendorCategory.includes(eventCategory) ||
      eventCategory.includes(vendorCategory) ||
      vendorDescription.includes(eventCategory) ||
      serviceText.includes(eventCategory);
    if (categoryAligned) {
      score += 0.14;
      reasons.push(`category fit for ${event.category.name}`);
    }

    const coverageKeywords = this.pickVendorCategories(
      event.category.name,
      180,
    )
      .map((item) => item.toLowerCase())
      .filter((item) =>
        vendorCategory.includes(item) ||
        vendorDescription.includes(item) ||
        serviceText.includes(item) ||
        packageText.includes(item),
      );
    if (coverageKeywords.length > 0) {
      score += Math.min(0.16, coverageKeywords.length * 0.05);
      reasons.push(
        `service coverage matches ${coverageKeywords.slice(0, 2).join(' and ')}`,
      );
    }

    if (vendor.services.length > 0) {
      score += Math.min(0.08, vendor.services.length * 0.02);
    }

    if (vendor.packages.length > 0) {
      score += Math.min(0.06, vendor.packages.length * 0.02);
    }

    const distanceKm =
      hasCoordinates(event) && hasCoordinates(vendor)
        ? haversineDistanceKm(event, vendor)
        : null;
    const vendorTravelRadiusKm = toNullableNumber(vendor.travelRadiusKm);
    const eventMatchRadiusKm = toNullableNumber(event.vendorMatchRadiusKm);

    if (
      distanceKm != null &&
      vendorTravelRadiusKm != null &&
      eventMatchRadiusKm != null
    ) {
      const withinVendorRadius = distanceKm <= vendorTravelRadiusKm;
      const withinEventRadius = distanceKm <= eventMatchRadiusKm;
      if (withinVendorRadius && withinEventRadius) {
        score += 0.22;
        reasons.push(
          `${distanceKm.toFixed(1)} km away and inside both travel limits`,
        );
      } else if (withinVendorRadius || withinEventRadius) {
        score += 0.1;
        reasons.push(
          `${distanceKm.toFixed(1)} km away with partial radius overlap`,
        );
      } else {
        score -= 0.12;
        reasons.push(
          `${distanceKm.toFixed(1)} km away and outside preferred travel range`,
        );
      }
    } else if (vendor.serviceArea.toLowerCase().includes(event.city.toLowerCase())) {
      score += 0.14;
      reasons.push(`service area includes ${event.city}`);
    }

    if (vendor.bookingPreference?.allowDirectBooking === true) {
      score += 0.08;
      reasons.push('direct booking enabled');
    }

    const reasonSummary =
      reasons.length > 0
        ? `${reasons.slice(0, 3).join(', ')}.`
        : vendor.verified
          ? 'Verified vendor ranked above unverified profiles.'
          : 'Unverified vendor included because profile coverage is relevant.';

    return {
      score: Number(Math.max(0, Math.min(1, score)).toFixed(2)),
      reasonSummary,
      vendor: this.vendorsService.toVendorProfileResponse(vendor, {
        distanceKm,
        withinTravelRadius:
          distanceKm == null || vendorTravelRadiusKm == null
            ? null
            : distanceKm <= vendorTravelRadiusKm,
      }),
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

  private async generateConversationDraft(
    userId: string,
    role: Role,
    conversationId: string,
    prompt: string | null | undefined,
    instruction: string,
    isAutoReply = false,
  ): Promise<string> {
    const context = await this.getConversationAiContext(userId, conversationId);
    const me = context.participants.find((participant) => participant.userId === userId);
    if (!me) {
      throw new ForbiddenException('You are not part of this conversation');
    }

    const myName = this.participantName(me);
    const counterpartName = context.counterpart == null
      ? 'the other participant'
      : this.participantName(context.counterpart);
    const transcript = this.toTranscript(context.recentMessages);
    const modelReply = await this.aiGatewayService.generateText([
      {
        role: 'system',
        content: `${instruction} You are writing on behalf of a ${role} named ${myName}.`,
      },
      {
        role: 'user',
        content: JSON.stringify({
          autoReply: isAutoReply,
          prompt: prompt?.trim() || null,
          me: {
            name: myName,
            role,
          },
          counterpart: context.counterpart == null
            ? null
            : {
                name: counterpartName,
                role: context.counterpart.user.role,
              },
          transcript,
        }),
      },
    ]);

    if (modelReply != null) {
      return modelReply;
    }

    return this.buildFallbackConversationDraft(
      role,
      counterpartName,
      prompt,
      isAutoReply,
      context.recentMessages,
      userId,
    );
  }

  private async generateOrganizerPlanDraft(
    userId: string,
    role: Role,
    dto: AiAssistantDraftRequestDto,
  ): Promise<string> {
    if (role !== Role.ORGANIZER && role !== Role.ADMIN) {
      throw new ForbiddenException('Only organizers or admins can generate planning drafts');
    }

    let event: Event | null = null;
    if (dto.eventId != null) {
      event = await this.eventsRepository.findOne({
        where: { id: dto.eventId },
        relations: { category: true },
      });

      if (!event) {
        throw new NotFoundException('Event not found');
      }

      if (role !== Role.ADMIN && event.organizerId !== userId) {
        throw new ForbiddenException('You cannot generate a planning draft for this event');
      }
    }

    const modelReply = await this.aiGatewayService.generateText([
      {
        role: 'system',
        content:
          'You are an event-planning copilot. Draft a production-ready planning note with clear priorities, likely risks, and immediate next steps. Keep it under 220 words and do not use markdown.',
      },
      {
        role: 'user',
        content: JSON.stringify({
          eventTitle: event?.title ?? null,
          city: event?.city ?? null,
          category: event?.category.name ?? null,
          startAt: event?.startAt.toISOString() ?? null,
          endAt: event?.endAt.toISOString() ?? null,
          prompt: dto.prompt?.trim() || null,
        }),
      },
    ]);

    if (modelReply != null) {
      return modelReply;
    }

    const trimmedPrompt = dto.prompt?.trim();
    const eventLabel = event?.title ?? 'this event';
    const goal =
      trimmedPrompt != null && trimmedPrompt.length > 0
        ? trimmedPrompt
        : 'tighten execution and reduce day-of surprises';
    return `Priority plan for ${eventLabel}: lock owners for venue operations, attendee communications, and vendor coverage first. Then review ticket pacing, support escalation paths, and sponsor or vendor dependencies against the event timeline. For the next step, turn ${goal} into a dated checklist with one accountable owner per item and close the highest-risk gap this week.`;
  }

  private async generateProposalDraft(
    userId: string,
    role: Role,
    dto: AiAssistantDraftRequestDto,
    requiredRole: Role,
    instruction: string,
  ): Promise<string> {
    if (role !== requiredRole && role !== Role.ADMIN) {
      throw new ForbiddenException('This proposal draft is not available for your role');
    }

    if (dto.conversationId != null) {
      return this.generateConversationDraft(
        userId,
        role,
        dto.conversationId,
        dto.prompt,
        instruction,
      );
    }

    const modelReply = await this.aiGatewayService.generateText([
      {
        role: 'system',
        content: instruction,
      },
      {
        role: 'user',
        content: JSON.stringify({
          role,
          prompt: dto.prompt?.trim() || null,
        }),
      },
    ]);

    if (modelReply != null) {
      return modelReply;
    }

    if (requiredRole === Role.VENDOR) {
      return 'Thanks for the opportunity. Based on the scope shared so far, I can prepare a focused service proposal with availability, deliverables, and a pricing range once I have the event date, venue, guest count, and required coverage. If that works, send those details and I will turn around a final offer quickly.';
    }

    return 'Thanks for reaching out. I can shape a sponsorship proposal around audience fit, brand visibility, and on-site activation once I have the event timing, audience profile, and target outcome. Share those details and I will send a tighter package with recommended next steps.';
  }

  private async getConversationAiContext(
    userId: string,
    conversationId: string,
  ): Promise<ConversationAiContext> {
    const participants = await this.conversationParticipantsRepository.find({
      where: { conversationId },
      relations: {
        conversation: true,
        user: {
          profile: true,
        },
      },
    });

    if (participants.length == 0) {
      throw new NotFoundException('Conversation not found');
    }

    if (!participants.some((participant) => participant.userId === userId)) {
      throw new ForbiddenException('You are not part of this conversation');
    }

    if (participants[0].conversation.type !== ConversationType.DIRECT) {
      throw new ForbiddenException('AI drafting currently supports direct conversations only');
    }

    const recentMessages = (
      await this.messagesRepository.find({
        where: { conversationId },
        relations: {
          sender: {
            profile: true,
          },
        },
        order: { createdAt: 'DESC' },
        take: 8,
      })
    ).reverse();

    return {
      participants,
      counterpart:
        participants.find((participant) => participant.userId !== userId) ?? null,
      recentMessages,
    };
  }

  private toTranscript(messages: Message[]): string[] {
    return messages.map((message) => {
      const senderName =
        message.sender.profile?.fullName?.trim() || message.sender.email.trim();
      const kind = message.messageType === MessageType.ASSISTANT ? 'assistant' : message.messageType;
      return `${senderName} [${kind}]: ${message.body}`;
    });
  }

  private participantName(participant: ConversationParticipant): string {
    return participant.user.profile?.fullName?.trim() || participant.user.email.trim();
  }

  private buildFallbackConversationDraft(
    role: Role,
    counterpartName: string,
    prompt: string | null | undefined,
    isAutoReply: boolean,
    messages: Message[],
    currentUserId: string,
  ): string {
    const trimmedPrompt = prompt?.trim();
    const promptLead =
      trimmedPrompt != null && trimmedPrompt.length > 0
        ? `${trimmedPrompt} `
        : '';
    const latestInbound = [...messages]
      .reverse()
      .find((message) => message.senderId !== currentUserId);
    const latestInboundText = latestInbound?.body.toLowerCase() ?? '';
    const missingDetail = this.inferMostUsefulMissingDetail(latestInboundText);
    if (isAutoReply) {
      switch (role) {
        case Role.ORGANIZER:
          return `${promptLead}Thanks ${counterpartName}, I’m reviewing this now and will follow up with the next event step shortly. If you can send ${missingDetail}, I can respond faster with a concrete next step.`;
        case Role.VENDOR:
          return `${promptLead}Thanks ${counterpartName}, I can help with this. Send ${missingDetail} and I’ll reply with availability, scope, and the best next step.`;
        case Role.SPONSOR:
          return `${promptLead}Thanks ${counterpartName}, I’m reviewing the opportunity. Please share ${missingDetail} so I can tailor the response.`;
        case Role.ADMIN:
          return `${promptLead}Thanks ${counterpartName}, this has been noted and I’m reviewing the right next action now.`;
        case Role.ATTENDEE:
          return `${promptLead}Thanks ${counterpartName}, I saw your message and will get back to you shortly.`;
      }
    }

    switch (role) {
      case Role.ORGANIZER:
        return `${promptLead}Thanks ${counterpartName}. I’m aligning the event side of this now and can confirm the next decision once I’ve checked timing, capacity, and dependencies. Send ${missingDetail} if you have it so I can make the next step more concrete.`;
      case Role.VENDOR:
        return `${promptLead}Thanks ${counterpartName}. I can put together scope, availability, and pricing once I have ${missingDetail}.`;
      case Role.SPONSOR:
        return `${promptLead}Thanks ${counterpartName}. I can shape a stronger proposal once I have ${missingDetail}.`;
      case Role.ADMIN:
        return `${promptLead}Thanks ${counterpartName}. I’m reviewing this and will respond with the clearest next action shortly.`;
      case Role.ATTENDEE:
        return `${promptLead}Thanks ${counterpartName}. I’ve got the message and will follow up with the next step shortly.`;
    }
  }

  private inferMostUsefulMissingDetail(text: string): string {
    if (!text.includes('date') && !text.includes('time')) {
      return 'the event date and timing';
    }
    if (!text.includes('venue') && !text.includes('location')) {
      return 'the venue or location';
    }
    if (!text.includes('guest') && !text.includes('attendee') && !text.includes('audience')) {
      return 'the expected guest or audience size';
    }
    if (!text.includes('budget') && !text.includes('price')) {
      return 'the working budget or price range';
    }
    if (!text.includes('scope') && !text.includes('deliverable') && !text.includes('coverage')) {
      return 'the exact scope or deliverables';
    }
    return 'one or two missing operational details';
  }

  private shouldUseFallbackSupportSuggestion(
    normalizedCategory: string | undefined,
    suggestion: string,
  ): boolean {
    const normalizedSuggestion = suggestion.toLowerCase();
    if (normalizedSuggestion.trim().length < 60) {
      return true;
    }

    if (
      normalizedCategory === 'payment' &&
      !['payment', 'checkout', 'charge', 'refund', 'billing', 'stripe'].some(
        (term) => normalizedSuggestion.includes(term),
      )
    ) {
      return true;
    }

    if (
      normalizedCategory === 'technical' &&
      !['step', 'screen', 'reproduce', 'retry', 'error'].some((term) =>
        normalizedSuggestion.includes(term),
      )
    ) {
      return true;
    }

    return false;
  }

  private shouldUseFallbackPlanningOverview(
    event: Event | null,
    city: string,
    overview: string,
  ): boolean {
    const normalizedOverview = overview.toLowerCase().trim();
    if (normalizedOverview.length < 80) {
      return true;
    }

    if (event != null && !normalizedOverview.includes(event.title.toLowerCase())) {
      return true;
    }

    if (!normalizedOverview.includes(city.toLowerCase())) {
      return true;
    }

    return false;
  }

  private extractLocationSignals(text: string): Set<string> {
    const knownLocations = [
      'kathmandu',
      'lalitpur',
      'bhaktapur',
      'pokhara',
      'biratnagar',
      'dharan',
      'chitwan',
      'bharatpur',
      'butwal',
      'nepalgunj',
      'janakpur',
      'hetauda',
    ];

    return new Set(
      knownLocations.filter((location) => text.includes(location)),
    );
  }
}
