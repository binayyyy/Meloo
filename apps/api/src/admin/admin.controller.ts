import { Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { EventResponseDto } from '../events/dto';
import { SponsorProfileResponseDto } from '../sponsors/dto';
import { SupportTicketResponseDto } from '../support/dto';
import { VendorProfileResponseDto } from '../vendors/dto';
import { AdminService } from './admin.service';
import { AdminOverviewDto, ModerateEventDto } from './dto';
import { Body } from '@nestjs/common';

@Controller('admin')
@UseGuards(AccessTokenGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('overview')
  getOverview(): Promise<AdminOverviewDto> {
    return this.adminService.getOverview();
  }

  @Get('vendors/pending')
  listPendingVendors(): Promise<VendorProfileResponseDto[]> {
    return this.adminService.listPendingVendors();
  }

  @Patch('vendors/:id/verify')
  verifyVendor(@Param('id') vendorId: string): Promise<VendorProfileResponseDto> {
    return this.adminService.verifyVendor(vendorId);
  }

  @Get('sponsors/pending')
  listPendingSponsors(): Promise<SponsorProfileResponseDto[]> {
    return this.adminService.listPendingSponsors();
  }

  @Patch('sponsors/:id/verify')
  verifySponsor(
    @Param('id') sponsorId: string,
  ): Promise<SponsorProfileResponseDto> {
    return this.adminService.verifySponsor(sponsorId);
  }

  @Get('events')
  listEventsForModeration(): Promise<EventResponseDto[]> {
    return this.adminService.listEventsForModeration();
  }

  @Patch('events/:id/moderate')
  moderateEvent(
    @Param('id') eventId: string,
    @Body() dto: ModerateEventDto,
  ): Promise<EventResponseDto> {
    return this.adminService.moderateEvent(eventId, dto);
  }

  @Get('support/tickets')
  listSupportTickets(): Promise<SupportTicketResponseDto[]> {
    return this.adminService.listSupportTickets();
  }

  @Patch('support/tickets/:id/assign')
  assignSupportTicket(
    @Param('id') ticketId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SupportTicketResponseDto> {
    return this.adminService.assignSupportTicket(ticketId, user.sub);
  }

  @Patch('support/tickets/:id/resolve')
  resolveSupportTicket(
    @Param('id') ticketId: string,
  ): Promise<SupportTicketResponseDto> {
    return this.adminService.resolveSupportTicket(ticketId);
  }
}
