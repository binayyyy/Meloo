import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { EventResponseDto } from '../events/dto';
import { SponsorProfileResponseDto } from '../sponsors/dto';
import { EscalationResponseDto, SupportTicketResponseDto } from '../support/dto';
import { VendorProfileResponseDto } from '../vendors/dto';
import { AdminService } from './admin.service';
import {
  AdminActivityItemDto,
  AdminOverviewDto,
  AdminSystemHealthDto,
  AdminUserResponseDto,
  ModerateEventDto,
  UpdateAdminUserStatusDto,
} from './dto';

@Controller('admin')
@UseGuards(AccessTokenGuard, RolesGuard)
@Roles(Role.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('overview')
  getOverview(): Promise<AdminOverviewDto> {
    return this.adminService.getOverview();
  }

  @Get('users')
  listUsers(): Promise<AdminUserResponseDto[]> {
    return this.adminService.listUsers();
  }

  @Patch('users/:id/status')
  updateUserStatus(
    @Param('id') userId: string,
    @Body() dto: UpdateAdminUserStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AdminUserResponseDto> {
    return this.adminService.updateUserStatus(userId, dto, user.sub);
  }

  @Patch('users/:id/revoke-sessions')
  revokeUserSessions(
    @Param('id') userId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AdminUserResponseDto> {
    return this.adminService.revokeUserSessions(userId, user.sub);
  }

  @Get('system/health')
  getSystemHealth(): Promise<AdminSystemHealthDto> {
    return this.adminService.getSystemHealth();
  }

  @Get('activity')
  listActivity(): Promise<AdminActivityItemDto[]> {
    return this.adminService.listActivity();
  }

  @Get('vendors/pending')
  listPendingVendors(): Promise<VendorProfileResponseDto[]> {
    return this.adminService.listPendingVendors();
  }

  @Patch('vendors/:id/verify')
  verifyVendor(@Param('id') vendorId: string): Promise<VendorProfileResponseDto> {
    return this.adminService.verifyVendor(vendorId);
  }

  @Patch('vendors/:id/unverify')
  unverifyVendor(
    @Param('id') vendorId: string,
  ): Promise<VendorProfileResponseDto> {
    return this.adminService.unverifyVendor(vendorId);
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

  @Patch('sponsors/:id/unverify')
  unverifySponsor(
    @Param('id') sponsorId: string,
  ): Promise<SponsorProfileResponseDto> {
    return this.adminService.unverifySponsor(sponsorId);
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

  @Get('support/escalations')
  listEscalations(): Promise<EscalationResponseDto[]> {
    return this.adminService.listEscalations();
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
