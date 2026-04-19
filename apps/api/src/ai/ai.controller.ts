import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import {
  AiSupportRequestDto,
  AiSupportResponseDto,
  EventRecommendationResponseDto,
  OpportunityRecommendationResponseDto,
  PlanningAssistantRequestDto,
  PlanningAssistantResponseDto,
  VendorRecommendationResponseDto,
} from './dto';
import { AiService } from './ai.service';

@Controller('ai')
@UseGuards(AccessTokenGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('support/respond')
  generateSupportResponse(
    @Body() dto: AiSupportRequestDto,
  ): Promise<AiSupportResponseDto> {
    return this.aiService.generateSupportAssistance(dto.category, dto.message);
  }

  @Get('recommendations/events')
  recommendEvents(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventRecommendationResponseDto[]> {
    return this.aiService.recommendEventsForUser(user.sub);
  }

  @Get('recommendations/vendors')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  recommendVendors(
    @CurrentUser() user: AuthenticatedUser,
    @Query('eventId') eventId: string,
  ): Promise<VendorRecommendationResponseDto[]> {
    return this.aiService.recommendVendorsForEvent(user.sub, user.role, eventId);
  }

  @Get('recommendations/opportunities')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.SPONSOR, Role.ADMIN)
  recommendOpportunities(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpportunityRecommendationResponseDto[]> {
    return this.aiService.recommendOpportunitiesForSponsor(user.sub);
  }

  @Post('planning/organizer')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  generatePlanningBrief(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PlanningAssistantRequestDto,
  ): Promise<PlanningAssistantResponseDto> {
    return this.aiService.generatePlanningAssistant(
      user.sub,
      user.role,
      dto,
    );
  }
}
