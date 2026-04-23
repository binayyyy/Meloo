import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from '../common/enums/role.enum';
import { Event } from '../events/entities';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CreateSponsorshipInterestDto,
  CreateSponsorshipOpportunityDto,
  SponsorProfileResponseDto,
  SponsorshipInterestResponseDto,
  SponsorshipOpportunityResponseDto,
  UpsertSponsorProfileDto,
} from './dto';
import {
  SponsorProfile,
  SponsorshipInterest,
  SponsorshipInterestStatus,
  SponsorshipOpportunity,
  SponsorshipOpportunityStatus,
} from './entities';

@Injectable()
export class SponsorsService {
  constructor(
    private readonly notificationsService: NotificationsService,
    @InjectRepository(SponsorProfile)
    private readonly sponsorProfilesRepository: Repository<SponsorProfile>,
    @InjectRepository(SponsorshipOpportunity)
    private readonly sponsorshipOpportunitiesRepository: Repository<SponsorshipOpportunity>,
    @InjectRepository(SponsorshipInterest)
    private readonly sponsorshipInterestsRepository: Repository<SponsorshipInterest>,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
  ) {}

  async getMySponsorProfile(userId: string): Promise<SponsorProfileResponseDto | null> {
    const profile = await this.sponsorProfilesRepository.findOne({
      where: { userId },
    });
    return profile ? this.toSponsorProfileResponse(profile) : null;
  }

  async upsertMySponsorProfile(
    userId: string,
    role: Role,
    dto: UpsertSponsorProfileDto,
  ): Promise<SponsorProfileResponseDto> {
    this.assertSponsorRole(role);
    const existing = await this.sponsorProfilesRepository.findOne({
      where: { userId },
    });

    const profile = await this.sponsorProfilesRepository.save(
      this.sponsorProfilesRepository.create({
        id: existing?.id,
        userId,
        companyName: dto.companyName.trim(),
        description: dto.description.trim(),
        industries: dto.industries.trim(),
        logoUrl: dto.logoUrl?.trim() || null,
        websiteUrl: dto.websiteUrl?.trim() || null,
        verificationDocumentUrl: dto.verificationDocumentUrl?.trim() || null,
        verified: existing?.verified ?? false,
      }),
    );

    return this.toSponsorProfileResponse(profile);
  }

  async listOpenOpportunities(): Promise<SponsorshipOpportunityResponseDto[]> {
    const opportunities = await this.sponsorshipOpportunitiesRepository.find({
      where: { status: SponsorshipOpportunityStatus.OPEN },
      relations: { event: true },
      order: { createdAt: 'DESC' },
    });
    return opportunities.map((opportunity) =>
      this.toOpportunityResponse(opportunity),
    );
  }

  async listMyOpportunities(
    organizerId: string,
  ): Promise<SponsorshipOpportunityResponseDto[]> {
    const opportunities = await this.sponsorshipOpportunitiesRepository.find({
      where: { organizerId },
      relations: { event: true },
      order: { createdAt: 'DESC' },
    });
    return opportunities.map((opportunity) =>
      this.toOpportunityResponse(opportunity),
    );
  }

  async createOpportunity(
    eventId: string,
    organizerId: string,
    role: Role,
    dto: CreateSponsorshipOpportunityDto,
  ): Promise<SponsorshipOpportunityResponseDto> {
    const event = await this.eventsRepository.findOne({ where: { id: eventId } });
    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (role != Role.ADMIN && event.organizerId != organizerId) {
      throw new ForbiddenException(
        'You cannot create sponsorship opportunities for this event',
      );
    }

    const opportunity = await this.sponsorshipOpportunitiesRepository.save(
      this.sponsorshipOpportunitiesRepository.create({
        eventId,
        organizerId: event.organizerId,
        title: dto.title.trim(),
        description: dto.description.trim(),
        requiredAmount: this.normalizeMoney(dto.requiredAmount),
        targetAudience: dto.targetAudience.trim(),
        benefitsOffered: dto.benefitsOffered.trim(),
        status: dto.status,
      }),
    );

    return this.getOpportunityOrFail(opportunity.id);
  }

  async expressInterest(
    opportunityId: string,
    userId: string,
    role: Role,
    dto: CreateSponsorshipInterestDto,
  ): Promise<SponsorshipInterestResponseDto> {
    this.assertSponsorRole(role);
    const sponsorProfile = await this.sponsorProfilesRepository.findOne({
      where: { userId },
    });

    if (!sponsorProfile) {
      throw new NotFoundException('Create your sponsor profile first');
    }

    const opportunity = await this.sponsorshipOpportunitiesRepository.findOne({
      where: { id: opportunityId },
      relations: { event: true },
    });

    if (!opportunity || opportunity.status != SponsorshipOpportunityStatus.OPEN) {
      throw new NotFoundException('Sponsorship opportunity not found');
    }

    const existingInterest = await this.sponsorshipInterestsRepository.findOne({
      where: {
        sponsorId: sponsorProfile.id,
        opportunityId,
      },
    });

    if (existingInterest) {
      throw new BadRequestException(
        'You have already expressed interest in this opportunity',
      );
    }

    const interest = await this.sponsorshipInterestsRepository.save(
      this.sponsorshipInterestsRepository.create({
        sponsorId: sponsorProfile.id,
        opportunityId,
        status: SponsorshipInterestStatus.EXPRESSED,
        message: dto.message.trim(),
      }),
    );

    await this.notificationsService.createNotification({
      userId: opportunity.organizerId,
      type: NotificationType.SPONSOR,
      title: 'New sponsor interest',
      body: `${sponsorProfile.companyName} responded to ${opportunity.title}.`,
      resourceType: 'sponsorship-interest',
      resourceId: interest.id,
    });

    return this.getInterestOrFail(interest.id, sponsorProfile.id);
  }

  async listMyInterests(userId: string): Promise<SponsorshipInterestResponseDto[]> {
    const sponsorProfile = await this.sponsorProfilesRepository.findOne({
      where: { userId },
    });

    if (!sponsorProfile) {
      return [];
    }

    const interests = await this.sponsorshipInterestsRepository.find({
      where: { sponsorId: sponsorProfile.id },
      relations: {
        sponsorProfile: true,
        opportunity: {
          event: true,
        },
      },
      order: { createdAt: 'DESC' },
    });

    return interests.map((interest) => this.toInterestResponse(interest));
  }

  async listOpportunityInterests(
    opportunityId: string,
    organizerId: string,
    role: Role,
  ): Promise<SponsorshipInterestResponseDto[]> {
    const opportunity = await this.sponsorshipOpportunitiesRepository.findOne({
      where: { id: opportunityId },
      relations: { event: true },
    });

    if (!opportunity) {
      throw new NotFoundException('Sponsorship opportunity not found');
    }

    if (role != Role.ADMIN && opportunity.organizerId != organizerId) {
      throw new ForbiddenException('You cannot view interests for this opportunity');
    }

    const interests = await this.sponsorshipInterestsRepository.find({
      where: { opportunityId },
      relations: {
        sponsorProfile: true,
        opportunity: {
          event: true,
        },
      },
      order: { createdAt: 'DESC' },
    });

    return interests.map((interest) => this.toInterestResponse(interest));
  }

  private async getOpportunityOrFail(
    opportunityId: string,
  ): Promise<SponsorshipOpportunityResponseDto> {
    const opportunity = await this.sponsorshipOpportunitiesRepository.findOne({
      where: { id: opportunityId },
      relations: { event: true },
    });

    if (!opportunity) {
      throw new NotFoundException('Sponsorship opportunity not found');
    }

    return this.toOpportunityResponse(opportunity);
  }

  private async getInterestOrFail(
    interestId: string,
    sponsorId: string,
  ): Promise<SponsorshipInterestResponseDto> {
    const interest = await this.sponsorshipInterestsRepository.findOne({
      where: { id: interestId, sponsorId },
      relations: {
        sponsorProfile: true,
        opportunity: { event: true },
      },
    });

    if (!interest) {
      throw new NotFoundException('Sponsorship interest not found');
    }

    return this.toInterestResponse(interest);
  }

  private assertSponsorRole(role: Role): void {
    if (role != Role.SPONSOR && role != Role.ADMIN) {
      throw new ForbiddenException('Only sponsors can manage sponsor profiles');
    }
  }

  private normalizeMoney(value: string): string {
    const parsed = Number.parseFloat(value);
    if (!Number.isFinite(parsed) || parsed < 0) {
      throw new BadRequestException('Amount must be zero or greater');
    }
    return parsed.toFixed(2);
  }

  toSponsorProfileResponse(profile: SponsorProfile): SponsorProfileResponseDto {
    return {
      id: profile.id,
      userId: profile.userId,
      companyName: profile.companyName,
      description: profile.description,
      industries: profile.industries,
      logoUrl: profile.logoUrl,
      websiteUrl: profile.websiteUrl,
      verificationDocumentUrl: profile.verificationDocumentUrl,
      verified: profile.verified,
    };
  }

  toOpportunityResponse(
    opportunity: SponsorshipOpportunity,
  ): SponsorshipOpportunityResponseDto {
    return {
      id: opportunity.id,
      event: {
        id: opportunity.event.id,
        title: opportunity.event.title,
        city: opportunity.event.city,
        venue: opportunity.event.venue,
        startAt: opportunity.event.startAt,
        endAt: opportunity.event.endAt,
      },
      organizerId: opportunity.organizerId,
      title: opportunity.title,
      description: opportunity.description,
      requiredAmount: opportunity.requiredAmount,
      targetAudience: opportunity.targetAudience,
      benefitsOffered: opportunity.benefitsOffered,
      status: opportunity.status,
      createdAt: opportunity.createdAt,
    };
  }

  toInterestResponse(
    interest: SponsorshipInterest,
  ): SponsorshipInterestResponseDto {
    return {
      id: interest.id,
      sponsor: this.toSponsorProfileResponse(interest.sponsorProfile),
      opportunity: this.toOpportunityResponse(interest.opportunity),
      status: interest.status,
      message: interest.message,
      createdAt: interest.createdAt,
    };
  }
}
