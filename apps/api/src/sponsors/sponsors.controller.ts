import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import {
  CreateSponsorshipInterestDto,
  CreateSponsorshipOpportunityDto,
  SponsorProfileResponseDto,
  SponsorshipInterestResponseDto,
  SponsorshipOpportunityResponseDto,
  UpsertSponsorProfileDto,
} from './dto';
import { SponsorsService } from './sponsors.service';

@Controller()
export class SponsorsController {
  constructor(private readonly sponsorsService: SponsorsService) {}

  @Get('sponsors/me/profile')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.SPONSOR, Role.ADMIN)
  getMySponsorProfile(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SponsorProfileResponseDto | null> {
    return this.sponsorsService.getMySponsorProfile(user.sub);
  }

  @Patch('sponsors/me/profile')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.SPONSOR, Role.ADMIN)
  upsertMySponsorProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertSponsorProfileDto,
  ): Promise<SponsorProfileResponseDto> {
    return this.sponsorsService.upsertMySponsorProfile(user.sub, user.role, dto);
  }

  @Get('sponsorship-opportunities')
  listOpenOpportunities(): Promise<SponsorshipOpportunityResponseDto[]> {
    return this.sponsorsService.listOpenOpportunities();
  }

  @Get('sponsorship-opportunities/my')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  listMyOpportunities(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SponsorshipOpportunityResponseDto[]> {
    return this.sponsorsService.listMyOpportunities(user.sub);
  }

  @Post('events/:id/sponsorship-opportunities')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  createOpportunity(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSponsorshipOpportunityDto,
  ): Promise<SponsorshipOpportunityResponseDto> {
    return this.sponsorsService.createOpportunity(eventId, user.sub, user.role, dto);
  }

  @Post('sponsorship-opportunities/:id/interests')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.SPONSOR, Role.ADMIN)
  expressInterest(
    @Param('id') opportunityId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSponsorshipInterestDto,
  ): Promise<SponsorshipInterestResponseDto> {
    return this.sponsorsService.expressInterest(
      opportunityId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Get('sponsorship-interests/my')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.SPONSOR, Role.ADMIN)
  listMyInterests(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SponsorshipInterestResponseDto[]> {
    return this.sponsorsService.listMyInterests(user.sub);
  }

  @Get('sponsorship-opportunities/:id/interests')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  listOpportunityInterests(
    @Param('id') opportunityId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SponsorshipInterestResponseDto[]> {
    return this.sponsorsService.listOpportunityInterests(
      opportunityId,
      user.sub,
      user.role,
    );
  }
}

