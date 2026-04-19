import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SupportTicketResponseDto } from '../support/dto';
import { SupportService } from '../support/support.service';
import {
  Escalation,
  EscalationStatus,
  SupportTicket,
  SupportTicketStatus,
} from '../support/entities';
import { EventResponseDto } from '../events/dto';
import { Event, EventStatus } from '../events/entities';
import { EventsService } from '../events/events.service';
import { SponsorProfileResponseDto } from '../sponsors/dto';
import { SponsorProfile } from '../sponsors/entities';
import { VendorProfileResponseDto } from '../vendors/dto';
import { VendorProfile } from '../vendors/entities';
import { VendorsService } from '../vendors/vendors.service';
import { AdminOverviewDto, ModerateEventDto } from './dto';

@Injectable()
export class AdminService {
  constructor(
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
  ) {}

  async getOverview(): Promise<AdminOverviewDto> {
    const [
      publishedEventCount,
      pendingVendorVerificationCount,
      pendingSponsorVerificationCount,
      openSupportTicketCount,
      openEscalationCount,
    ] = await Promise.all([
      this.eventsRepository.count({
        where: { status: EventStatus.PUBLISHED },
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
      publishedEventCount,
      pendingVendorVerificationCount,
      pendingSponsorVerificationCount,
      openSupportTicketCount,
      openEscalationCount,
    };
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

    return vendors.map((vendor) => this.vendorsService.toVendorProfileResponse(vendor));
  }

  async verifyVendor(vendorId: string): Promise<VendorProfileResponseDto> {
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

    vendor.verified = true;
    await this.vendorProfilesRepository.save(vendor);
    return this.vendorsService.toVendorProfileResponse(vendor);
  }

  async listPendingSponsors(): Promise<SponsorProfileResponseDto[]> {
    const sponsors = await this.sponsorProfilesRepository.find({
      where: { verified: false },
      order: { companyName: 'ASC' },
    });

    return sponsors.map((sponsor) => ({
      id: sponsor.id,
      userId: sponsor.userId,
      companyName: sponsor.companyName,
      description: sponsor.description,
      industries: sponsor.industries,
      verified: sponsor.verified,
    }));
  }

  async verifySponsor(sponsorId: string): Promise<SponsorProfileResponseDto> {
    const sponsor = await this.sponsorProfilesRepository.findOne({
      where: { id: sponsorId },
    });

    if (!sponsor) {
      throw new NotFoundException('Sponsor profile not found');
    }

    sponsor.verified = true;
    await this.sponsorProfilesRepository.save(sponsor);
    return {
      id: sponsor.id,
      userId: sponsor.userId,
      companyName: sponsor.companyName,
      description: sponsor.description,
      industries: sponsor.industries,
      verified: sponsor.verified,
    };
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

  assignSupportTicket(
    ticketId: string,
    adminUserId: string,
  ): Promise<SupportTicketResponseDto> {
    return this.supportService.assignTicket(ticketId, adminUserId);
  }

  resolveSupportTicket(ticketId: string): Promise<SupportTicketResponseDto> {
    return this.supportService.resolveTicket(ticketId);
  }
}
