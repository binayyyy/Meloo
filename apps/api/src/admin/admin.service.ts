import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, MoreThan, Repository } from 'typeorm';
import { UserStatus } from '../common/enums/user-status.enum';
import { EventResponseDto } from '../events/dto';
import { Event, EventStatus } from '../events/entities';
import { EventsService } from '../events/events.service';
import { SponsorProfileResponseDto } from '../sponsors/dto';
import { SponsorProfile } from '../sponsors/entities';
import {
  EscalationResponseDto,
  SupportTicketResponseDto,
} from '../support/dto';
import {
  Escalation,
  EscalationStatus,
  SupportTicket,
  SupportTicketStatus,
} from '../support/entities';
import { SupportService } from '../support/support.service';
import { Session, User } from '../users/entities';
import { VendorProfileResponseDto } from '../vendors/dto';
import { VendorProfile } from '../vendors/entities';
import { VendorsService } from '../vendors/vendors.service';
import {
  AdminActivityItemDto,
  AdminOverviewDto,
  AdminSystemHealthDto,
  AdminUserResponseDto,
  ModerateEventDto,
  UpdateAdminUserStatusDto,
} from './dto';

@Injectable()
export class AdminService {
  constructor(
    private readonly configService: ConfigService,
    private readonly dataSource: DataSource,
    private readonly eventsService: EventsService,
    private readonly supportService: SupportService,
    private readonly vendorsService: VendorsService,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(VendorProfile)
    private readonly vendorProfilesRepository: Repository<VendorProfile>,
    @InjectRepository(SponsorProfile)
    private readonly sponsorProfilesRepository: Repository<SponsorProfile>,
    @InjectRepository(SupportTicket)
    private readonly supportTicketsRepository: Repository<SupportTicket>,
    @InjectRepository(Escalation)
    private readonly escalationsRepository: Repository<Escalation>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(Session)
    private readonly sessionsRepository: Repository<Session>,
  ) {}

  async getOverview(): Promise<AdminOverviewDto> {
    const now = new Date();
    const [
      totalUserCount,
      activeUserCount,
      suspendedUserCount,
      activeSessionCount,
      totalEventCount,
      publishedEventCount,
      draftEventCount,
      cancelledEventCount,
      pendingVendorVerificationCount,
      pendingSponsorVerificationCount,
      openSupportTicketCount,
      openEscalationCount,
    ] = await Promise.all([
      this.usersRepository.count(),
      this.usersRepository.count({
        where: { status: UserStatus.ACTIVE },
      }),
      this.usersRepository.count({
        where: { status: UserStatus.SUSPENDED },
      }),
      this.sessionsRepository.count({
        where: { expiresAt: MoreThan(now) },
      }),
      this.eventsRepository.count(),
      this.eventsRepository.count({
        where: { status: EventStatus.PUBLISHED },
      }),
      this.eventsRepository.count({
        where: { status: EventStatus.DRAFT },
      }),
      this.eventsRepository.count({
        where: { status: EventStatus.CANCELLED },
      }),
      this.vendorProfilesRepository.count({
        where: { verified: false },
      }),
      this.sponsorProfilesRepository.count({
        where: { verified: false },
      }),
      this.supportTicketsRepository.count({
        where: [
          { status: SupportTicketStatus.OPEN },
          { status: SupportTicketStatus.IN_PROGRESS },
        ],
      }),
      this.escalationsRepository.count({
        where: [
          { status: EscalationStatus.OPEN },
          { status: EscalationStatus.IN_REVIEW },
        ],
      }),
    ]);

    return {
      totalUserCount,
      activeUserCount,
      suspendedUserCount,
      activeSessionCount,
      totalEventCount,
      publishedEventCount,
      draftEventCount,
      cancelledEventCount,
      pendingVendorVerificationCount,
      pendingSponsorVerificationCount,
      openSupportTicketCount,
      openEscalationCount,
    };
  }

  async listUsers(): Promise<AdminUserResponseDto[]> {
    const [users, vendorProfiles, sponsorProfiles] = await Promise.all([
      this.usersRepository.find({
        relations: {
          profile: true,
          sessions: true,
        },
        order: { updatedAt: 'DESC' },
      }),
      this.vendorProfilesRepository.find(),
      this.sponsorProfilesRepository.find(),
    ]);

    const vendorByUserId = new Map(vendorProfiles.map((profile) => [profile.userId, profile]));
    const sponsorByUserId = new Map(
      sponsorProfiles.map((profile) => [profile.userId, profile]),
    );

    return users.map((user) =>
      this.toAdminUserResponse(
        user,
        vendorByUserId.get(user.id) ?? null,
        sponsorByUserId.get(user.id) ?? null,
      ),
    );
  }

  async updateUserStatus(
    userId: string,
    dto: UpdateAdminUserStatusDto,
    actingAdminUserId: string,
  ): Promise<AdminUserResponseDto> {
    if (userId === actingAdminUserId && dto.status !== UserStatus.ACTIVE) {
      throw new BadRequestException(
        'Admins cannot suspend or deactivate themselves from the admin console',
      );
    }

    const user = await this.getAdminUserOrFail(userId);
    user.status = dto.status;
    await this.usersRepository.save(user);

    if (dto.status !== UserStatus.ACTIVE) {
      await this.sessionsRepository.delete({ userId });
      user.sessions = [];
    }

    return this.toAdminUserResponseWithLookup(user);
  }

  async revokeUserSessions(
    userId: string,
    actingAdminUserId: string,
  ): Promise<AdminUserResponseDto> {
    if (userId === actingAdminUserId) {
      throw new BadRequestException(
        'Use sign out from your own session instead of revoking your current admin sessions here',
      );
    }

    const user = await this.getAdminUserOrFail(userId);
    await this.sessionsRepository.delete({ userId });
    user.sessions = [];
    return this.toAdminUserResponseWithLookup(user);
  }

  async getSystemHealth(): Promise<AdminSystemHealthDto> {
    const appConfig =
      this.configService.get<{
        nodeEnv?: string;
        apiPrefix?: string;
        corsOrigin?: string;
      }>('app') ?? {};
    const aiConfig =
      this.configService.get<{
        enabled?: boolean;
        provider?: string;
        model?: string;
        baseUrl?: string;
      }>('ai') ?? {};
    const paymentsConfig =
      this.configService.get<{
        stripeSecretKey?: string;
        stripeWebhookSecret?: string;
        stripeCurrency?: string;
      }>('payments') ?? {};

    const memoryUsage = process.memoryUsage();
    const now = new Date();
    const [users, activeSessions, publishedEvents, openSupportTickets, openEscalations] =
      await Promise.all([
        this.usersRepository.count(),
        this.sessionsRepository.count({
          where: { expiresAt: MoreThan(now) },
        }),
        this.eventsRepository.count({
          where: { status: EventStatus.PUBLISHED },
        }),
        this.supportTicketsRepository.count({
          where: [
            { status: SupportTicketStatus.OPEN },
            { status: SupportTicketStatus.IN_PROGRESS },
          ],
        }),
        this.escalationsRepository.count({
          where: [
            { status: EscalationStatus.OPEN },
            { status: EscalationStatus.IN_REVIEW },
          ],
        }),
      ]);

    const aiEnabled = aiConfig.enabled ?? false;
    const aiConfigured = aiEnabled && Boolean(aiConfig.baseUrl) && Boolean(aiConfig.model);
    const stripeConfigured = Boolean(paymentsConfig.stripeSecretKey);
    const stripeWebhookConfigured = Boolean(paymentsConfig.stripeWebhookSecret);

    return {
      nodeEnv: appConfig.nodeEnv ?? 'development',
      apiPrefix: appConfig.apiPrefix ?? 'api',
      corsOrigin: appConfig.corsOrigin ?? '*',
      uptimeSeconds: Math.round(process.uptime()),
      databaseConnected: this.dataSource.isInitialized,
      memory: {
        rssMb: this.toMb(memoryUsage.rss),
        heapUsedMb: this.toMb(memoryUsage.heapUsed),
        heapTotalMb: this.toMb(memoryUsage.heapTotal),
      },
      ai: {
        configured: aiConfigured,
        detail: aiConfigured
          ? 'AI gateway is configured'
          : 'AI is disabled or missing provider settings',
        enabled: aiEnabled,
        provider: aiConfig.provider ?? 'unknown',
        model: aiConfig.model ?? '',
        baseUrl: aiConfig.baseUrl ?? '',
      },
      payments: {
        configured: stripeConfigured,
        detail: stripeConfigured
          ? 'Stripe secret key is configured'
          : 'Stripe secret key is missing',
        currency: paymentsConfig.stripeCurrency ?? 'usd',
        webhookConfigured: stripeWebhookConfigured,
      },
      totals: {
        users,
        activeSessions,
        publishedEvents,
        openSupportTickets,
        openEscalations,
      },
    };
  }

  async listActivity(): Promise<AdminActivityItemDto[]> {
    const [users, sessions, events, supportTickets, escalations] = await Promise.all([
      this.usersRepository.find({
        relations: { profile: true },
        order: { createdAt: 'DESC' },
        take: 8,
      }),
      this.sessionsRepository.find({
        relations: {
          user: {
            profile: true,
          },
        },
        order: { createdAt: 'DESC' },
        take: 8,
      }),
      this.eventsRepository.find({
        relations: {
          category: true,
          organizer: {
            profile: true,
          },
        },
        order: { updatedAt: 'DESC' },
        take: 8,
      }),
      this.supportTicketsRepository.find({
        relations: {
          user: {
            profile: true,
          },
          assignedAdmin: {
            profile: true,
          },
        },
        order: { updatedAt: 'DESC' },
        take: 8,
      }),
      this.escalationsRepository.find({
        relations: {
          assignedAdmin: {
            profile: true,
          },
        },
        order: { updatedAt: 'DESC' },
        take: 8,
      }),
    ]);

    const activity: AdminActivityItemDto[] = [
      ...users.map((user) => ({
        id: `user-${user.id}`,
        type: 'user',
        title: 'New account created',
        detail: `${this.userLabel(user)} joined as ${user.role}`,
        status: user.status,
        actorLabel: this.userLabel(user),
        createdAt: user.createdAt.toISOString(),
        resourceType: 'user',
        resourceId: user.id,
      })),
      ...sessions.map((session) => ({
        id: `session-${session.id}`,
        type: 'session',
        title: 'Session created',
        detail: `${this.userLabel(session.user)} signed in${
          session.deviceInfo ? ` on ${session.deviceInfo}` : ''
        }`,
        status: null,
        actorLabel: this.userLabel(session.user),
        createdAt: session.createdAt.toISOString(),
        resourceType: 'session',
        resourceId: session.id,
      })),
      ...events.map((event) => ({
        id: `event-${event.id}`,
        type: 'event',
        title: 'Event updated',
        detail: `${event.title} is ${event.status} (${event.visibility}) in ${event.city}`,
        status: event.status,
        actorLabel: this.userLabel(event.organizer),
        createdAt: event.updatedAt.toISOString(),
        resourceType: 'event',
        resourceId: event.id,
      })),
      ...supportTickets.map((ticket) => ({
        id: `support-${ticket.id}`,
        type: 'support',
        title: 'Support ticket activity',
        detail: `${ticket.subject} is ${ticket.status}${
          ticket.assignedAdmin ? ` with ${this.userLabel(ticket.assignedAdmin)}` : ''
        }`,
        status: ticket.status,
        actorLabel: this.userLabel(ticket.user),
        createdAt: ticket.updatedAt.toISOString(),
        resourceType: 'support-ticket',
        resourceId: ticket.id,
      })),
      ...escalations.map((escalation) => ({
        id: `escalation-${escalation.id}`,
        type: 'escalation',
        title: 'Escalation updated',
        detail: escalation.reason,
        status: escalation.status,
        actorLabel: escalation.assignedAdmin
          ? this.userLabel(escalation.assignedAdmin)
          : null,
        createdAt: escalation.updatedAt.toISOString(),
        resourceType: 'escalation',
        resourceId: escalation.id,
      })),
    ];

    return activity
      .sort(
        (left, right) =>
          new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime(),
      )
      .slice(0, 24);
  }

  async listPendingVendors(): Promise<VendorProfileResponseDto[]> {
    const vendors = await this.vendorProfilesRepository.find({
      where: { verified: false },
      relations: {
        services: true,
        packages: true,
        bookingPreference: true,
      },
      order: { businessName: 'ASC' },
    });

    return vendors.map((vendor) =>
      this.vendorsService.toVendorProfileResponse(vendor),
    );
  }

  async verifyVendor(vendorId: string): Promise<VendorProfileResponseDto> {
    return this.updateVendorVerification(vendorId, true);
  }

  async unverifyVendor(vendorId: string): Promise<VendorProfileResponseDto> {
    return this.updateVendorVerification(vendorId, false);
  }

  async listPendingSponsors(): Promise<SponsorProfileResponseDto[]> {
    const sponsors = await this.sponsorProfilesRepository.find({
      where: { verified: false },
      order: { companyName: 'ASC' },
    });

    return sponsors.map((sponsor) => this.toSponsorProfileResponse(sponsor));
  }

  async verifySponsor(sponsorId: string): Promise<SponsorProfileResponseDto> {
    return this.updateSponsorVerification(sponsorId, true);
  }

  async unverifySponsor(sponsorId: string): Promise<SponsorProfileResponseDto> {
    return this.updateSponsorVerification(sponsorId, false);
  }

  async listEventsForModeration(): Promise<EventResponseDto[]> {
    const events = await this.eventsRepository.find({
      relations: { category: true },
      order: { updatedAt: 'DESC' },
    });

    return events.map((event) => this.eventsService.toEventResponse(event));
  }

  async moderateEvent(
    eventId: string,
    dto: ModerateEventDto,
  ): Promise<EventResponseDto> {
    const event = await this.eventsRepository.findOne({
      where: { id: eventId },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (dto.status != null) {
      event.status = dto.status;
    }

    if (dto.visibility != null) {
      event.visibility = dto.visibility;
    }

    await this.eventsRepository.save(event);
    return this.eventsService.toEventResponse(event);
  }

  listSupportTickets(): Promise<SupportTicketResponseDto[]> {
    return this.supportService.listAllTickets();
  }

  listEscalations(): Promise<EscalationResponseDto[]> {
    return this.supportService.listEscalations();
  }

  assignSupportTicket(
    ticketId: string,
    adminUserId: string,
  ): Promise<SupportTicketResponseDto> {
    return this.supportService.assignTicket(ticketId, adminUserId);
  }

  resolveSupportTicket(ticketId: string): Promise<SupportTicketResponseDto> {
    return this.supportService.resolveTicket(ticketId);
  }

  private async updateVendorVerification(
    vendorId: string,
    verified: boolean,
  ): Promise<VendorProfileResponseDto> {
    const vendor = await this.vendorProfilesRepository.findOne({
      where: { id: vendorId },
      relations: {
        services: true,
        packages: true,
        bookingPreference: true,
      },
    });

    if (!vendor) {
      throw new NotFoundException('Vendor profile not found');
    }

    vendor.verified = verified;
    await this.vendorProfilesRepository.save(vendor);
    return this.vendorsService.toVendorProfileResponse(vendor);
  }

  private async updateSponsorVerification(
    sponsorId: string,
    verified: boolean,
  ): Promise<SponsorProfileResponseDto> {
    const sponsor = await this.sponsorProfilesRepository.findOne({
      where: { id: sponsorId },
    });

    if (!sponsor) {
      throw new NotFoundException('Sponsor profile not found');
    }

    sponsor.verified = verified;
    await this.sponsorProfilesRepository.save(sponsor);
    return this.toSponsorProfileResponse(sponsor);
  }

  private async getAdminUserOrFail(userId: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: {
        profile: true,
        sessions: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async toAdminUserResponseWithLookup(
    user: User,
  ): Promise<AdminUserResponseDto> {
    const [vendorProfile, sponsorProfile, freshSessions] = await Promise.all([
      this.vendorProfilesRepository.findOne({
        where: { userId: user.id },
      }),
      this.sponsorProfilesRepository.findOne({
        where: { userId: user.id },
      }),
      this.sessionsRepository.find({
        where: { userId: user.id },
      }),
    ]);

    user.sessions = freshSessions;
    return this.toAdminUserResponse(user, vendorProfile, sponsorProfile);
  }

  private toAdminUserResponse(
    user: User,
    vendorProfile: VendorProfile | null,
    sponsorProfile: SponsorProfile | null,
  ): AdminUserResponseDto {
    const now = Date.now();
    const activeSessions = user.sessions.filter(
      (session) => session.expiresAt.getTime() > now,
    );
    const lastSession =
      [...user.sessions].sort(
        (left, right) => right.createdAt.getTime() - left.createdAt.getTime(),
      )[0] ?? null;

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      fullName: user.profile?.fullName ?? null,
      avatarUrl: user.profile?.avatarUrl ?? null,
      phone: user.profile?.phone ?? null,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
      activeSessionCount: activeSessions.length,
      lastSessionAt: lastSession?.createdAt.toISOString() ?? null,
      vendorProfileId: vendorProfile?.id ?? null,
      sponsorProfileId: sponsorProfile?.id ?? null,
      vendorVerified: vendorProfile?.verified ?? false,
      sponsorVerified: sponsorProfile?.verified ?? false,
    };
  }

  private toSponsorProfileResponse(
    sponsor: SponsorProfile,
  ): SponsorProfileResponseDto {
    return {
      id: sponsor.id,
      userId: sponsor.userId,
      companyName: sponsor.companyName,
      description: sponsor.description,
      industries: sponsor.industries,
      logoUrl: sponsor.logoUrl,
      websiteUrl: sponsor.websiteUrl,
      verificationDocumentUrl: sponsor.verificationDocumentUrl,
      verified: sponsor.verified,
    };
  }

  private userLabel(user: User | null | undefined): string {
    if (!user) {
      return 'Unknown user';
    }

    return user.profile?.fullName?.trim() || user.email;
  }

  private toMb(value: number): number {
    return Math.round((value / (1024 * 1024)) * 10) / 10;
  }
}
