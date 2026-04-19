import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, SelectQueryBuilder } from 'typeorm';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import { Role } from '../common/enums/role.enum';
import { TicketType } from '../registrations/entities';
import {
  CreateEventCategoryDto,
  CreateEventDto,
  EventCategoryResponseDto,
  EventFavoriteStateResponseDto,
  EventResponseDto,
  ListEventsQueryDto,
  UpdateEventDto,
} from './dto';
import {
  Event,
  EventCategory,
  EventFavorite,
  EventStatus,
  EventView,
  EventVisibility,
} from './entities';

const DEFAULT_CATEGORIES = [
  { name: 'Technology', slug: 'technology' },
  { name: 'Business', slug: 'business' },
  { name: 'Music', slug: 'music' },
  { name: 'Food & Culture', slug: 'food-culture' },
  { name: 'Education', slug: 'education' },
  { name: 'Community', slug: 'community' },
];

@Injectable()
export class EventsService implements OnModuleInit {
  constructor(
    private readonly notificationsService: NotificationsService,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
    @InjectRepository(EventCategory)
    private readonly eventCategoriesRepository: Repository<EventCategory>,
    @InjectRepository(EventFavorite)
    private readonly eventFavoritesRepository: Repository<EventFavorite>,
    @InjectRepository(EventView)
    private readonly eventViewsRepository: Repository<EventView>,
    @InjectRepository(TicketType)
    private readonly ticketTypesRepository: Repository<TicketType>,
  ) {}

  async onModuleInit(): Promise<void> {
    const categoryCount = await this.eventCategoriesRepository.count();
    if (categoryCount > 0) {
      return;
    }

    await this.eventCategoriesRepository.save(
      DEFAULT_CATEGORIES.map((category) =>
        this.eventCategoriesRepository.create(category),
      ),
    );
  }

  async listCategories(): Promise<EventCategoryResponseDto[]> {
    const categories = await this.eventCategoriesRepository.find({
      order: { name: 'ASC' },
    });

    return categories.map((category) => ({
      id: category.id,
      name: category.name,
      slug: category.slug,
    }));
  }

  async createCategory(
    dto: CreateEventCategoryDto,
  ): Promise<EventCategoryResponseDto> {
    const existing = await this.eventCategoriesRepository.findOne({
      where: [{ name: dto.name.trim() }, { slug: dto.slug.trim() }],
    });

    if (existing) {
      throw new ConflictException('Event category already exists');
    }

    const category = await this.eventCategoriesRepository.save(
      this.eventCategoriesRepository.create({
        name: dto.name.trim(),
        slug: dto.slug.trim(),
      }),
    );

    return {
      id: category.id,
      name: category.name,
      slug: category.slug,
    };
  }

  async listPublicEvents(
    query: ListEventsQueryDto,
  ): Promise<EventResponseDto[]> {
    const queryBuilder = this.eventsRepository
      .createQueryBuilder('event')
      .leftJoinAndSelect('event.category', 'category')
      .where('event.status = :status', { status: EventStatus.PUBLISHED })
      .andWhere('event.visibility = :visibility', {
        visibility: EventVisibility.PUBLIC,
      })
      .orderBy('event.startAt', 'ASC');

    this.applyPublicFilters(queryBuilder, query);

    const events = await queryBuilder.getMany();
    return events.map((event) => this.toEventResponse(event));
  }

  async listOwnedEvents(userId: string): Promise<EventResponseDto[]> {
    const events = await this.eventsRepository.find({
      where: { organizerId: userId },
      relations: { category: true },
      order: {
        updatedAt: 'DESC',
      },
    });

    return events.map((event) => this.toEventResponse(event));
  }

  async listFavoriteEvents(userId: string): Promise<EventResponseDto[]> {
    const favorites = await this.eventFavoritesRepository.find({
      where: { userId },
      relations: {
        event: {
          category: true,
        },
      },
      order: { createdAt: 'DESC' },
    });

    return favorites
      .map((favorite) => favorite.event)
      .filter((event): event is Event => event != null)
      .map((event) => this.toEventResponse(event));
  }

  async listRecentlyViewedEvents(userId: string): Promise<EventResponseDto[]> {
    const views = await this.eventViewsRepository.find({
      where: { userId },
      relations: {
        event: {
          category: true,
        },
      },
      order: { updatedAt: 'DESC' },
      take: 12,
    });

    return views
      .map((view) => view.event)
      .filter((event): event is Event => event != null)
      .map((event) => this.toEventResponse(event));
  }

  async getPublicEventById(eventId: string): Promise<EventResponseDto> {
    const event = await this.eventsRepository.findOne({
      where: {
        id: eventId,
        status: EventStatus.PUBLISHED,
        visibility: EventVisibility.PUBLIC,
      },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return this.toEventResponse(event);
  }

  async createEvent(
    organizerId: string,
    dto: CreateEventDto,
  ): Promise<EventResponseDto> {
    await this.getCategoryOrFail(dto.categoryId);
    this.assertValidTimeWindow(dto.startAt, dto.endAt);

    const event = await this.eventsRepository.save(
      this.eventsRepository.create({
        organizerId,
        title: dto.title.trim(),
        description: dto.description.trim(),
        categoryId: dto.categoryId,
        venue: dto.venue.trim(),
        city: dto.city.trim(),
        startAt: new Date(dto.startAt),
        endAt: new Date(dto.endAt),
        status: dto.status ?? EventStatus.DRAFT,
        visibility: dto.visibility ?? EventVisibility.PUBLIC,
        coverImageUrl: dto.coverImageUrl ?? null,
      }),
    );

    const createdEvent = await this.getOwnedEventOrFail(event.id, organizerId, Role.ORGANIZER);
    await this.notificationsService.createNotification({
      userId: organizerId,
      type: NotificationType.SYSTEM,
      title: 'Event created',
      body: `${createdEvent.title} is now in your event pipeline.`,
      resourceType: 'event',
      resourceId: createdEvent.id,
    });
    return createdEvent;
  }

  async updateEvent(
    eventId: string,
    userId: string,
    role: Role,
    dto: UpdateEventDto,
  ): Promise<EventResponseDto> {
    const event = await this.eventsRepository.findOne({
      where: { id: eventId },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    const canManage = role == Role.ADMIN || event.organizerId == userId;
    if (!canManage) {
      throw new ForbiddenException('You cannot modify this event');
    }

    if (dto.categoryId != null) {
      await this.getCategoryOrFail(dto.categoryId);
      event.categoryId = dto.categoryId;
    }

    const nextStartAt = dto.startAt ?? event.startAt.toISOString();
    const nextEndAt = dto.endAt ?? event.endAt.toISOString();
    this.assertValidTimeWindow(nextStartAt, nextEndAt);

    if (dto.title != null) {
      event.title = dto.title.trim();
    }
    if (dto.description != null) {
      event.description = dto.description.trim();
    }
    if (dto.venue != null) {
      event.venue = dto.venue.trim();
    }
    if (dto.city != null) {
      event.city = dto.city.trim();
    }
    if (dto.startAt != null) {
      event.startAt = new Date(dto.startAt);
    }
    if (dto.endAt != null) {
      event.endAt = new Date(dto.endAt);
    }
    if (dto.status != null) {
      event.status = dto.status;
    }
    if (dto.visibility != null) {
      event.visibility = dto.visibility;
    }
    if (dto.coverImageUrl != null) {
      event.coverImageUrl = dto.coverImageUrl;
    }

    await this.eventsRepository.save(event);
    return this.getOwnedEventOrFail(event.id, userId, role);
  }

  async favoriteEvent(
    eventId: string,
    userId: string,
  ): Promise<EventFavoriteStateResponseDto> {
    await this.getPublicEventEntityOrFail(eventId);

    const existing = await this.eventFavoritesRepository.findOne({
      where: { eventId, userId },
    });

    if (!existing) {
      await this.eventFavoritesRepository.save(
        this.eventFavoritesRepository.create({
          eventId,
          userId,
        }),
      );
    }

    return {
      eventId,
      isFavorite: true,
    };
  }

  async unfavoriteEvent(
    eventId: string,
    userId: string,
  ): Promise<EventFavoriteStateResponseDto> {
    await this.eventFavoritesRepository.delete({ eventId, userId });
    return {
      eventId,
      isFavorite: false,
    };
  }

  async recordEventView(eventId: string, userId: string): Promise<void> {
    await this.getPublicEventEntityOrFail(eventId);

    const existing = await this.eventViewsRepository.findOne({
      where: { eventId, userId },
    });

    if (!existing) {
      await this.eventViewsRepository.save(
        this.eventViewsRepository.create({
          eventId,
          userId,
          viewCount: 1,
        }),
      );
      return;
    }

    existing.viewCount += 1;
    await this.eventViewsRepository.save(existing);
  }

  async getOwnedEventOrFail(
    eventId: string,
    userId: string,
    role: Role,
  ): Promise<EventResponseDto> {
    const event = await this.eventsRepository.findOne({
      where: { id: eventId },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    if (role != Role.ADMIN && event.organizerId != userId) {
      throw new ForbiddenException('You cannot view this event');
    }

    return this.toEventResponse(event);
  }

  toEventResponse(event: Event): EventResponseDto {
    return {
      id: event.id,
      organizerId: event.organizerId,
      title: event.title,
      description: event.description,
      category: {
        id: event.category.id,
        name: event.category.name,
        slug: event.category.slug,
      },
      venue: event.venue,
      city: event.city,
      startAt: event.startAt,
      endAt: event.endAt,
      status: event.status,
      visibility: event.visibility,
      coverImageUrl: event.coverImageUrl,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    };
  }

  private async getPublicEventEntityOrFail(eventId: string): Promise<Event> {
    const event = await this.eventsRepository.findOne({
      where: {
        id: eventId,
        status: EventStatus.PUBLISHED,
        visibility: EventVisibility.PUBLIC,
      },
      relations: { category: true },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return event;
  }

  private async getCategoryOrFail(categoryId: string): Promise<EventCategory> {
    const category = await this.eventCategoriesRepository.findOne({
      where: { id: categoryId },
    });

    if (!category) {
      throw new NotFoundException('Event category not found');
    }

    return category;
  }

  private assertValidTimeWindow(startAt: string, endAt: string): void {
    const start = new Date(startAt);
    const end = new Date(endAt);

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw new BadRequestException('Invalid event date range');
    }

    if (end.getTime() <= start.getTime()) {
      throw new BadRequestException('Event end time must be after the start time');
    }
  }

  private applyPublicFilters(
    queryBuilder: SelectQueryBuilder<Event>,
    query: ListEventsQueryDto,
  ): void {
    if (query.city != null && query.city.trim().length > 0) {
      queryBuilder.andWhere('LOWER(event.city) = LOWER(:city)', {
        city: query.city.trim(),
      });
    }

    if (query.categoryId != null) {
      queryBuilder.andWhere('event.categoryId = :categoryId', {
        categoryId: query.categoryId,
      });
    }

    if (query.search != null && query.search.trim().length > 0) {
      queryBuilder.andWhere(
        '(event.title ILIKE :search OR event.description ILIKE :search OR event.venue ILIKE :search)',
        {
          search: `%${query.search.trim()}%`,
        },
      );
    }
  }
}
