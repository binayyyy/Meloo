import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { MessageResponseDto } from '../auth/dto';
import {
  CreateEventCategoryDto,
  CreateEventDto,
  EventCategoryResponseDto,
  EventFavoriteStateResponseDto,
  EventResponseDto,
  ListEventsQueryDto,
  UpdateEventDto,
} from './dto';
import { EventsService } from './events.service';

@Controller()
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Get('event-categories')
  listCategories(): Promise<EventCategoryResponseDto[]> {
    return this.eventsService.listCategories();
  }

  @Get('events')
  listPublicEvents(
    @Query() query: ListEventsQueryDto,
  ): Promise<EventResponseDto[]> {
    return this.eventsService.listPublicEvents(query);
  }

  @Get('events/my')
  @UseGuards(AccessTokenGuard)
  listOwnedEvents(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventResponseDto[]> {
    return this.eventsService.listOwnedEvents(user.sub);
  }

  @Get('events/my/favorites')
  @UseGuards(AccessTokenGuard)
  listFavoriteEvents(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventResponseDto[]> {
    return this.eventsService.listFavoriteEvents(user.sub);
  }

  @Get('events/my/recently-viewed')
  @UseGuards(AccessTokenGuard)
  listRecentlyViewedEvents(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventResponseDto[]> {
    return this.eventsService.listRecentlyViewedEvents(user.sub);
  }

  @Get('events/:id/manage')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  getOwnedEvent(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventResponseDto> {
    return this.eventsService.getOwnedEventOrFail(eventId, user.sub, user.role);
  }

  @Get('events/:id')
  getPublicEvent(@Param('id') eventId: string): Promise<EventResponseDto> {
    return this.eventsService.getPublicEventById(eventId);
  }

  @Post('events')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  createEvent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateEventDto,
  ): Promise<EventResponseDto> {
    return this.eventsService.createEvent(user.sub, dto);
  }

  @Post('events/:id/favorite')
  @UseGuards(AccessTokenGuard)
  favoriteEvent(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventFavoriteStateResponseDto> {
    return this.eventsService.favoriteEvent(eventId, user.sub);
  }

  @Delete('events/:id/favorite')
  @UseGuards(AccessTokenGuard)
  unfavoriteEvent(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<EventFavoriteStateResponseDto> {
    return this.eventsService.unfavoriteEvent(eventId, user.sub);
  }

  @Post('events/:id/view')
  @UseGuards(AccessTokenGuard)
  async recordEventView(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<MessageResponseDto> {
    await this.eventsService.recordEventView(eventId, user.sub);
    return { message: 'Event view recorded' };
  }

  @Patch('events/:id')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  updateEvent(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateEventDto,
  ): Promise<EventResponseDto> {
    return this.eventsService.updateEvent(eventId, user.sub, user.role, dto);
  }

  @Post('admin/event-categories')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ADMIN)
  createCategory(
    @Body() dto: CreateEventCategoryDto,
  ): Promise<EventCategoryResponseDto> {
    return this.eventsService.createCategory(dto);
  }
}
