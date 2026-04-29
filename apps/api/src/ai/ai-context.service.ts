import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConversationParticipant, ConversationType, Message, MessageType } from '../chat/entities';
import { Role } from '../common/enums/role.enum';
import { Event } from '../events/entities';
import { SponsorProfile } from '../sponsors/entities';
import {
  User,
  UserProfile,
} from '../users/entities';
import { VendorProfile } from '../vendors/entities';
import { SupportTicket } from '../support/entities';
import { AiAssistantDraftIntent, PlanningAssistantRequestDto } from './dto';
import { AiContextScopeType } from './entities';
import { AiMemoryService } from './ai-memory.service';

type AiContextSection = {
  label: string;
  content: string;
};

type AiActor = User & {
  profile: UserProfile | null;
};

type ChatDraftContext = {
  actor: AiActor;
  counterpartName: string;
  sections: AiContextSection[];
  retrievalQuery: string;
  cacheScope: string;
};

type PlanningContext = {
  actor: AiActor;
  event: Event | null;
  sections: AiContextSection[];
  retrievalQuery: string;
  cacheScope: string;
};

type SupportTriageContext = {
  sections: AiContextSection[];
  retrievalQuery: string;
  cacheScope: string;
};

@Injectable()
export class AiContextService {
  constructor(
    private readonly aiMemoryService: AiMemoryService,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(VendorProfile)
    private readonly vendorProfilesRepository: Repository<VendorProfile>,
    @InjectRepository(SponsorProfile)
    private readonly sponsorProfilesRepository: Repository<SponsorProfile>,
    @InjectRepository(SupportTicket)
    private readonly supportTicketsRepository: Repository<SupportTicket>,
    @InjectRepository(ConversationParticipant)
    private readonly conversationParticipantsRepository: Repository<ConversationParticipant>,
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
  ) {}

  async requireAiActor(
    userId: string,
    role: Role,
  ): Promise<AiActor> {
    const actor = await this.usersRepository.findOne({
      where: { id: userId },
      relations: {
        profile: true,
        setting: true,
      },
    });

    if (!actor) {
      throw new NotFoundException('User not found');
    }

    if (actor.role !== role) {
      throw new ForbiddenException('Invalid AI access context');
    }

    if (actor.setting?.aiAssistEnabled !== true) {
      throw new ForbiddenException('AI assist is disabled for this account');
    }

    return actor as AiActor;
  }

  async buildChatDraftContext(params: {
    userId: string;
    role: Role;
    conversationId: string;
    prompt?: string | null;
    intent: AiAssistantDraftIntent;
    eventId?: string;
  }): Promise<ChatDraftContext> {
    const actor = await this.requireAiActor(params.userId, params.role);
    const participants = await this.conversationParticipantsRepository.find({
      where: { conversationId: params.conversationId },
      relations: {
        conversation: true,
        user: {
          profile: true,
          setting: true,
        },
      },
    });

    if (participants.length === 0) {
      throw new NotFoundException('Conversation not found');
    }

    if (!participants.some((participant) => participant.userId === params.userId)) {
      throw new ForbiddenException('You are not part of this conversation');
    }

    if (participants[0].conversation.type !== ConversationType.DIRECT) {
      throw new ForbiddenException('AI drafting supports direct conversations only');
    }

    const recentMessages = (
      await this.messagesRepository.find({
        where: { conversationId: params.conversationId },
        relations: {
          sender: {
            profile: true,
          },
        },
        order: { createdAt: 'DESC' },
        take: 12,
      })
    ).reverse();

    const counterpart =
      participants.find((participant) => participant.userId !== params.userId) ?? null;
    const counterpartName = counterpart == null
      ? 'the other participant'
      : this.displayName(counterpart.user);

    const event = params.eventId
      ? await this.eventsRepository.findOne({
          where: { id: params.eventId },
          relations: { category: true },
        })
      : null;

    const actorProfile = this.buildActorProfile(actor);
    const counterpartProfile =
      counterpart == null ? null : this.buildParticipantProfile(counterpart.user);
    const transcript = this.toTranscript(recentMessages);
    const roleProfile = await this.buildRoleProfile(params.userId, params.role);

    await this.aiMemoryService.upsertDocuments([
      {
        scopeType: AiContextScopeType.CONVERSATION,
        scopeId: params.conversationId,
        sourceType: 'recent_transcript',
        title: 'Recent conversation transcript',
        body: transcript,
        keywords: [
          params.role,
          counterpart?.user.role ?? '',
          params.intent,
          params.prompt ?? '',
        ],
      },
      {
        scopeType: AiContextScopeType.USER,
        scopeId: params.userId,
        sourceType: 'actor_profile',
        title: 'AI actor profile',
        body: actorProfile,
        keywords: [params.role, actor.email],
      },
      ...(counterpartProfile == null || counterpart == null
        ? []
        : [
            {
              scopeType: AiContextScopeType.USER,
              scopeId: counterpart.userId,
              sourceType: 'counterpart_profile',
              title: 'Conversation counterpart profile',
              body: counterpartProfile,
              keywords: [counterpart.user.role, counterpart.user.email],
            },
          ]),
      ...(roleProfile == null
        ? []
        : [
            {
              scopeType: AiContextScopeType.USER,
              scopeId: params.userId,
              sourceType: 'role_profile',
              title: 'Role-specific business context',
              body: roleProfile,
              keywords: [params.role],
            },
          ]),
      ...(event == null
        ? []
        : [
            {
              scopeType: AiContextScopeType.EVENT,
              scopeId: event.id,
              sourceType: 'event_snapshot',
              title: 'Related event snapshot',
              body: this.buildEventSnapshot(event),
              keywords: [event.title, event.city, event.category.name],
            },
          ]),
    ]);

    const retrievedDocs = await this.aiMemoryService.retrieveDocuments({
      query: [params.prompt, transcript, roleProfile].filter(Boolean).join('\n'),
      scopeIds: [
        params.conversationId,
        params.userId,
        counterpart?.userId,
        event?.id,
      ].filter((value): value is string => Boolean(value)),
      limit: 5,
    });

    return {
      actor,
      counterpartName,
      retrievalQuery: [params.prompt, transcript].filter(Boolean).join('\n'),
      cacheScope: params.conversationId,
      sections: [
        {
          label: 'AI actor',
          content: actorProfile,
        },
        ...(counterpartProfile == null
          ? []
          : [
              {
                label: 'Counterpart',
                content: counterpartProfile,
              },
            ]),
        ...(roleProfile == null
          ? []
          : [
              {
                label: 'Role context',
                content: roleProfile,
              },
            ]),
        ...(event == null
          ? []
          : [
              {
                label: 'Related event',
                content: this.buildEventSnapshot(event),
              },
            ]),
        {
          label: 'Recent conversation',
          content: transcript,
        },
        ...retrievedDocs.map((doc) => ({
          label: `Retrieved memory: ${doc.title}`,
          content: doc.body,
        })),
      ],
    };
  }

  async buildPlanningContext(
    userId: string,
    role: Role,
    dto: PlanningAssistantRequestDto,
  ): Promise<PlanningContext> {
    const actor = await this.requireAiActor(userId, role);
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
        throw new ForbiddenException('You cannot generate a planning brief for this event');
      }
    }

    const actorProfile = this.buildActorProfile(actor);
    const planningRequest = [
      `Expected attendees: ${dto.expectedAttendees ?? 'not specified'}`,
      `Budget: ${dto.budget ?? 'not specified'}`,
      `Planning goal: ${dto.planningGoal?.trim() || 'not specified'}`,
    ].join('\n');

    await this.aiMemoryService.upsertDocuments([
      {
        scopeType: AiContextScopeType.USER,
        scopeId: userId,
        sourceType: 'actor_profile',
        title: 'Organizer profile',
        body: actorProfile,
        keywords: [role, actor.email],
      },
      ...(event == null
        ? []
        : [
            {
              scopeType: AiContextScopeType.EVENT,
              scopeId: event.id,
              sourceType: 'event_snapshot',
              title: 'Planning event snapshot',
              body: this.buildEventSnapshot(event),
              keywords: [event.title, event.city, event.category.name],
            },
          ]),
    ]);

    const retrievedDocs = await this.aiMemoryService.retrieveDocuments({
      query: [planningRequest, event?.title, event?.city, event?.category.name]
        .filter(Boolean)
        .join('\n'),
      scopeIds: [userId, event?.id].filter((value): value is string => Boolean(value)),
      limit: 4,
    });

    return {
      actor,
      event,
      retrievalQuery: [planningRequest, event?.title].filter(Boolean).join('\n'),
      cacheScope: event?.id ?? userId,
      sections: [
        {
          label: 'Organizer profile',
          content: actorProfile,
        },
        ...(event == null
          ? []
          : [
              {
                label: 'Event snapshot',
                content: this.buildEventSnapshot(event),
              },
            ]),
        {
          label: 'Planner input',
          content: planningRequest,
        },
        ...retrievedDocs.map((doc) => ({
          label: `Retrieved memory: ${doc.title}`,
          content: doc.body,
        })),
      ],
    };
  }

  async buildSupportTriageContext(params: {
    requesterId?: string;
    category?: string;
    subject?: string;
    message: string;
  }): Promise<SupportTriageContext> {
    const requester = params.requesterId
      ? await this.usersRepository.findOne({
          where: { id: params.requesterId },
          relations: {
            profile: true,
          },
        })
      : null;

    const recentTickets = params.requesterId
      ? await this.supportTicketsRepository.find({
          where: { userId: params.requesterId },
          order: { createdAt: 'DESC' },
          take: 5,
        })
      : [];

    const requesterProfile =
      requester == null ? null : this.buildActorProfile(requester as AiActor);
    const recentTicketSummary = recentTickets.length === 0
      ? null
      : recentTickets
          .map(
            (ticket) =>
              `${ticket.createdAt.toISOString().slice(0, 10)} ${ticket.status} ${ticket.category}: ${ticket.subject}`,
          )
          .join('\n');

    await this.aiMemoryService.upsertDocuments([
      ...(requesterProfile == null || !params.requesterId
        ? []
        : [
            {
              scopeType: AiContextScopeType.USER,
              scopeId: params.requesterId,
              sourceType: 'support_requester_profile',
              title: 'Support requester profile',
              body: requesterProfile,
              keywords: [requester?.role ?? '', requester?.email ?? ''],
            },
          ]),
    ]);

    const retrievedDocs =
      params.requesterId == null
        ? []
        : await this.aiMemoryService.retrieveDocuments({
            query: [params.subject, params.category, params.message].filter(Boolean).join('\n'),
            scopeIds: [params.requesterId],
            scopeTypes: [AiContextScopeType.USER],
            limit: 3,
          });

    return {
      retrievalQuery: [
        params.subject,
        params.category,
        params.message,
        recentTicketSummary,
      ]
        .filter(Boolean)
        .join('\n'),
      cacheScope: params.requesterId ?? 'support',
      sections: [
        {
          label: 'Support issue',
          content: [
            `Subject: ${params.subject?.trim() || 'Not provided'}`,
            `Category: ${params.category?.trim() || 'Not provided'}`,
            `Message: ${params.message.trim()}`,
          ].join('\n'),
        },
        ...(requesterProfile == null
          ? []
          : [
              {
                label: 'Requester profile',
                content: requesterProfile,
              },
            ]),
        ...(recentTicketSummary == null
          ? []
          : [
              {
                label: 'Recent support history',
                content: recentTicketSummary,
              },
            ]),
        ...retrievedDocs.map((doc) => ({
          label: `Retrieved memory: ${doc.title}`,
          content: doc.body,
        })),
      ],
    };
  }

  private buildActorProfile(user: AiActor): string {
    return [
      `Role: ${user.role}`,
      `Email: ${user.email}`,
      `Full name: ${user.profile?.fullName?.trim() || 'Not provided'}`,
      `Phone: ${user.profile?.phone?.trim() || 'Not provided'}`,
      `Bio: ${user.profile?.bio?.trim() || 'Not provided'}`,
    ].join('\n');
  }

  private buildParticipantProfile(user: User): string {
    return [
      `Role: ${user.role}`,
      `Display name: ${this.displayName(user)}`,
      `Email: ${user.email}`,
      `Bio: ${user.profile?.bio?.trim() || 'Not provided'}`,
    ].join('\n');
  }

  private buildEventSnapshot(event: Event): string {
    return [
      `Title: ${event.title}`,
      `Category: ${event.category.name}`,
      `City: ${event.city}`,
      `Venue: ${event.venue}`,
      `Status: ${event.status}`,
      `Visibility: ${event.visibility}`,
      `Starts at: ${event.startAt.toISOString()}`,
      `Ends at: ${event.endAt.toISOString()}`,
      `Description: ${event.description}`,
    ].join('\n');
  }

  private async buildRoleProfile(
    userId: string,
    role: Role,
  ): Promise<string | null> {
    if (role === Role.VENDOR) {
      const vendor = await this.vendorProfilesRepository.findOne({
        where: { userId },
        relations: {
          services: true,
          packages: true,
          bookingPreference: true,
        },
      });

      if (!vendor) {
        return null;
      }

      return [
        `Business name: ${vendor.businessName}`,
        `Category: ${vendor.category}`,
        `Service area: ${vendor.serviceArea}`,
        `Description: ${vendor.description}`,
        `Verified: ${vendor.verified ? 'yes' : 'no'}`,
        `Services: ${vendor.services.map((item) => item.name).join(', ') || 'none listed'}`,
        `Packages: ${vendor.packages.map((item) => item.name).join(', ') || 'none listed'}`,
      ].join('\n');
    }

    if (role === Role.SPONSOR) {
      const sponsor = await this.sponsorProfilesRepository.findOne({
        where: { userId },
      });

      if (!sponsor) {
        return null;
      }

      return [
        `Company name: ${sponsor.companyName}`,
        `Industries: ${sponsor.industries}`,
        `Description: ${sponsor.description}`,
        `Verified: ${sponsor.verified ? 'yes' : 'no'}`,
        `Website: ${sponsor.websiteUrl ?? 'Not provided'}`,
      ].join('\n');
    }

    return null;
  }

  private toTranscript(messages: Message[]): string {
    return messages
      .map((message) => {
        const senderName =
          message.sender.profile?.fullName?.trim() || message.sender.email.trim();
        const kind =
          message.messageType === MessageType.ASSISTANT ? 'draft' : message.messageType;
        return `${senderName} [${kind}]: ${message.body}`;
      })
      .join('\n');
  }

  private displayName(user: User): string {
    return user.profile?.fullName?.trim() || user.email.trim();
  }
}
