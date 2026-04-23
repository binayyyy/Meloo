import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Role } from '../common/enums/role.enum';
import {
  hasCoordinates,
  haversineDistanceKm,
  toNullableNumber,
} from '../common/utils/distance.util';
import { Event } from '../events/entities';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CreateVendorPackageDto,
  CreateVendorRequestDto,
  CreateVendorServiceDto,
  ListVendorsQueryDto,
  RespondVendorRequestDto,
  UpdateVendorPackageDto,
  UpdateVendorServiceDto,
  UpsertVendorBookingPreferenceDto,
  UpsertVendorProfileDto,
  VendorProfileResponseDto,
  VendorRequestResponseDto,
} from './dto';
import {
  VendorBookingPreference,
  VendorPackage,
  VendorProfile,
  VendorRequest,
  VendorRequestStatus,
  VendorService,
} from './entities';

@Injectable()
export class VendorsService {
  constructor(
    private readonly notificationsService: NotificationsService,
    @InjectRepository(VendorProfile)
    private readonly vendorProfilesRepository: Repository<VendorProfile>,
    @InjectRepository(VendorService)
    private readonly vendorServicesRepository: Repository<VendorService>,
    @InjectRepository(VendorPackage)
    private readonly vendorPackagesRepository: Repository<VendorPackage>,
    @InjectRepository(VendorBookingPreference)
    private readonly vendorBookingPreferencesRepository: Repository<VendorBookingPreference>,
    @InjectRepository(VendorRequest)
    private readonly vendorRequestsRepository: Repository<VendorRequest>,
    @InjectRepository(Event)
    private readonly eventsRepository: Repository<Event>,
  ) {}

  async listPublicVendors(
    query: ListVendorsQueryDto,
  ): Promise<VendorProfileResponseDto[]> {
    const queryBuilder = this.vendorProfilesRepository
      .createQueryBuilder('vendor')
      .leftJoinAndSelect('vendor.services', 'services')
      .leftJoinAndSelect('vendor.packages', 'packages')
      .leftJoinAndSelect('vendor.bookingPreference', 'bookingPreference')
      .orderBy('vendor.verified', 'DESC')
      .addOrderBy('vendor.businessName', 'ASC');

    if (query.category != null && query.category.trim().length > 0) {
      queryBuilder.andWhere('vendor.category ILIKE :category', {
        category: `%${query.category.trim()}%`,
      });
    }

    if (query.serviceArea != null && query.serviceArea.trim().length > 0) {
      queryBuilder.andWhere('vendor.serviceArea ILIKE :serviceArea', {
        serviceArea: `%${query.serviceArea.trim()}%`,
      });
    }

    if (query.search != null && query.search.trim().length > 0) {
      queryBuilder.andWhere(
        '(vendor.businessName ILIKE :search OR vendor.description ILIKE :search OR vendor.category ILIKE :search)',
        { search: `%${query.search.trim()}%` },
      );
    }

    const vendors = await queryBuilder.getMany();
    const origin =
      query.latitude != null && query.longitude != null
        ? {
            latitude: query.latitude,
            longitude: query.longitude,
          }
        : null;

    return vendors
      .map((vendor) => {
        const distanceKm =
          origin != null && hasCoordinates(vendor)
            ? haversineDistanceKm(origin, vendor)
            : null;
        const travelRadiusKm = toNullableNumber(vendor.travelRadiusKm);
        const withinTravelRadius =
          distanceKm == null || travelRadiusKm == null
            ? null
            : distanceKm <= travelRadiusKm;

        return this.toVendorProfileResponse(vendor, {
          distanceKm,
          withinTravelRadius,
        });
      })
      .filter(
        (vendor) => query.radiusKm == null || vendor.distanceKm == null || vendor.distanceKm <= query.radiusKm,
      )
      .sort((left, right) => {
        if (left.verified !== right.verified) {
          return left.verified ? -1 : 1;
        }
        if (left.distanceKm != null && right.distanceKm != null) {
          return left.distanceKm - right.distanceKm;
        }
        if (left.distanceKm != null) {
          return -1;
        }
        if (right.distanceKm != null) {
          return 1;
        }
        return left.businessName.localeCompare(right.businessName);
      });
  }

  async getPublicVendorProfile(vendorId: string): Promise<VendorProfileResponseDto> {
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

    return this.toVendorProfileResponse(vendor);
  }

  async getMyVendorProfile(userId: string): Promise<VendorProfileResponseDto | null> {
    const vendor = await this.vendorProfilesRepository.findOne({
      where: { userId },
      relations: {
        services: true,
        packages: true,
        bookingPreference: true,
      },
    });

    return vendor ? this.toVendorProfileResponse(vendor) : null;
  }

  async upsertMyVendorProfile(
    userId: string,
    role: Role,
    dto: UpsertVendorProfileDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const existingProfile = await this.vendorProfilesRepository.findOne({
      where: { userId },
      relations: {
        services: true,
        packages: true,
        bookingPreference: true,
      },
    });

    const vendor = await this.vendorProfilesRepository.save(
      this.vendorProfilesRepository.create({
        id: existingProfile?.id,
        userId,
        businessName: dto.businessName.trim(),
        description: dto.description.trim(),
        category: dto.category.trim(),
        serviceArea: dto.serviceArea.trim(),
        latitude: this.formatOptionalCoordinate(dto.latitude),
        longitude: this.formatOptionalCoordinate(dto.longitude),
        travelRadiusKm: this.formatOptionalRadius(
          dto.travelRadiusKm,
          dto.latitude,
          dto.longitude,
        ),
        portfolioImageUrl: dto.portfolioImageUrl?.trim() || null,
        verificationDocumentUrl: dto.verificationDocumentUrl?.trim() || null,
        verified: existingProfile?.verified ?? false,
        ratingAverage: existingProfile?.ratingAverage ?? '0.00',
      }),
    );

    return this.getMyVendorProfileOrFail(userId);
  }

  async upsertMyBookingPreference(
    userId: string,
    role: Role,
    dto: UpsertVendorBookingPreferenceDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const vendor = await this.getVendorEntityByUserIdOrFail(userId);

    await this.vendorBookingPreferencesRepository.save(
      this.vendorBookingPreferencesRepository.create({
        id: vendor.bookingPreference?.id,
        vendorId: vendor.id,
        allowDirectBooking: dto.allowDirectBooking,
        allowRequestBooking: dto.allowRequestBooking,
      }),
    );

    return this.getMyVendorProfileOrFail(userId);
  }

  async createVendorService(
    userId: string,
    role: Role,
    dto: CreateVendorServiceDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const vendor = await this.getVendorEntityByUserIdOrFail(userId);

    await this.vendorServicesRepository.save(
      this.vendorServicesRepository.create({
        vendorId: vendor.id,
        name: dto.name.trim(),
        description: dto.description.trim(),
        basePrice: this.normalizeMoney(dto.basePrice),
        pricingModel: dto.pricingModel.trim(),
      }),
    );

    return this.getMyVendorProfileOrFail(userId);
  }

  async updateVendorService(
    serviceId: string,
    userId: string,
    role: Role,
    dto: UpdateVendorServiceDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const service = await this.vendorServicesRepository.findOne({
      where: { id: serviceId },
    });

    if (!service) {
      throw new NotFoundException('Vendor service not found');
    }

    const vendor = await this.getVendorEntityByUserIdOrFail(userId);
    if (service.vendorId != vendor.id) {
      throw new ForbiddenException('You cannot edit this vendor service');
    }

    await this.vendorServicesRepository.save({
      ...service,
      name: dto.name?.trim() ?? service.name,
      description: dto.description?.trim() ?? service.description,
      pricingModel: dto.pricingModel?.trim() ?? service.pricingModel,
      basePrice:
        dto.basePrice != null
          ? this.normalizeMoney(dto.basePrice)
          : service.basePrice,
    });

    return this.getMyVendorProfileOrFail(userId);
  }

  async createVendorPackage(
    userId: string,
    role: Role,
    dto: CreateVendorPackageDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const vendor = await this.getVendorEntityByUserIdOrFail(userId);

    await this.vendorPackagesRepository.save(
      this.vendorPackagesRepository.create({
        vendorId: vendor.id,
        name: dto.name.trim(),
        description: dto.description.trim(),
        price: this.normalizeMoney(dto.price),
      }),
    );

    return this.getMyVendorProfileOrFail(userId);
  }

  async createVendorRequest(
    vendorId: string,
    organizerId: string,
    role: Role,
    dto: CreateVendorRequestDto,
  ): Promise<VendorRequestResponseDto> {
    if (role != Role.ORGANIZER && role != Role.ADMIN) {
      throw new ForbiddenException('Only organizers can create vendor requests');
    }

    const event = await this.eventsRepository.findOne({
      where: { id: dto.eventId },
    });
    if (!event) {
      throw new NotFoundException('Event not found');
    }
    if (role != Role.ADMIN && event.organizerId != organizerId) {
      throw new ForbiddenException('You cannot use this event for vendor outreach');
    }

    const vendor = await this.vendorProfilesRepository.findOne({
      where: { id: vendorId },
      relations: { bookingPreference: true },
    });
    if (!vendor) {
      throw new NotFoundException('Vendor profile not found');
    }

    const directBookingPreferred = dto.directBookingPreferred ?? false;
    const initialStatus =
      directBookingPreferred && vendor.bookingPreference?.allowDirectBooking === true
        ? VendorRequestStatus.BOOKED
        : VendorRequestStatus.PENDING;

    const vendorRequest = await this.vendorRequestsRepository.save(
      this.vendorRequestsRepository.create({
        eventId: event.id,
        organizerId: event.organizerId,
        vendorId: vendor.id,
        status: initialStatus,
        message: dto.message.trim(),
        proposedBudget: this.normalizeMoney(dto.proposedBudget),
      }),
    );

    await this.notificationsService.createNotification({
      userId: vendor.userId,
      type: NotificationType.VENDOR,
      title: initialStatus === VendorRequestStatus.BOOKED ? 'New vendor booking' : 'New vendor request',
      body:
        initialStatus === VendorRequestStatus.BOOKED
          ? `${event.title} booked your services directly.`
          : `${event.title} sent a vendor request for your review.`,
      resourceType: 'vendor-request',
      resourceId: vendorRequest.id,
    });

    return this.getVendorRequestOrFail(vendorRequest.id, organizerId, role);
  }

  async listMyOrganizerRequests(
    organizerId: string,
    role: Role,
  ): Promise<VendorRequestResponseDto[]> {
    const vendorRequests = await this.vendorRequestsRepository.find({
      where: role == Role.ADMIN ? {} : { organizerId },
      relations: {
        event: true,
        vendorProfile: true,
      },
      order: { createdAt: 'DESC' },
    });

    return vendorRequests.map((vendorRequest) =>
      this.toVendorRequestResponse(vendorRequest),
    );
  }

  async listMyVendorRequests(
    userId: string,
    role: Role,
  ): Promise<VendorRequestResponseDto[]> {
    const vendorId =
      role == Role.ADMIN
        ? undefined
        : (await this.getVendorEntityByUserIdOrFail(userId)).id;
    const vendorRequests = await this.vendorRequestsRepository.find({
      where: role == Role.ADMIN ? {} : { vendorId },
      relations: {
        event: true,
        vendorProfile: true,
      },
      order: { createdAt: 'DESC' },
    });

    return vendorRequests.map((vendorRequest) =>
      this.toVendorRequestResponse(vendorRequest),
    );
  }

  async respondToVendorRequest(
    requestId: string,
    userId: string,
    role: Role,
    dto: RespondVendorRequestDto,
  ): Promise<VendorRequestResponseDto> {
    const vendorRequest = await this.vendorRequestsRepository.findOne({
      where: { id: requestId },
      relations: {
        event: true,
        vendorProfile: true,
      },
    });

    if (!vendorRequest) {
      throw new NotFoundException('Vendor request not found');
    }

    if (role != Role.ADMIN) {
      const vendor = await this.getVendorEntityByUserIdOrFail(userId);
      if (vendorRequest.vendorId != vendor.id) {
        throw new ForbiddenException('You cannot respond to this request');
      }
    }

    if (
      dto.status != VendorRequestStatus.ACCEPTED &&
      dto.status != VendorRequestStatus.DECLINED
    ) {
      throw new BadRequestException('Vendors can only accept or decline requests');
    }

    vendorRequest.status = dto.status;
    await this.vendorRequestsRepository.save(vendorRequest);
    await this.notificationsService.createNotification({
      userId: vendorRequest.organizerId,
      type: NotificationType.VENDOR,
      title: 'Vendor request updated',
      body: `${vendorRequest.vendorProfile.businessName} ${dto.status} your vendor request.`,
      resourceType: 'vendor-request',
      resourceId: vendorRequest.id,
    });
    return this.toVendorRequestResponse(vendorRequest);
  }

  async markVendorRequestBooked(
    requestId: string,
    organizerId: string,
    role: Role,
  ): Promise<VendorRequestResponseDto> {
    const vendorRequest = await this.vendorRequestsRepository.findOne({
      where: { id: requestId },
      relations: {
        event: true,
        vendorProfile: true,
      },
    });

    if (!vendorRequest) {
      throw new NotFoundException('Vendor request not found');
    }

    if (role != Role.ADMIN && vendorRequest.organizerId != organizerId) {
      throw new ForbiddenException('You cannot book this vendor request');
    }

    if (
      vendorRequest.status != VendorRequestStatus.ACCEPTED &&
      vendorRequest.status != VendorRequestStatus.BOOKED
    ) {
      throw new BadRequestException('Only accepted vendor requests can be booked');
    }

    vendorRequest.status = VendorRequestStatus.BOOKED;
    await this.vendorRequestsRepository.save(vendorRequest);
    await this.notificationsService.createNotification({
      userId: vendorRequest.vendorProfile.userId,
      type: NotificationType.VENDOR,
      title: 'Vendor booking confirmed',
      body: `${vendorRequest.event.title} marked your accepted request as booked.`,
      resourceType: 'vendor-request',
      resourceId: vendorRequest.id,
    });
    return this.toVendorRequestResponse(vendorRequest);
  }

  async updateVendorPackage(
    packageId: string,
    userId: string,
    role: Role,
    dto: UpdateVendorPackageDto,
  ): Promise<VendorProfileResponseDto> {
    this.assertVendorRole(role);
    const vendorPackage = await this.vendorPackagesRepository.findOne({
      where: { id: packageId },
    });

    if (!vendorPackage) {
      throw new NotFoundException('Vendor package not found');
    }

    const vendor = await this.getVendorEntityByUserIdOrFail(userId);
    if (vendorPackage.vendorId != vendor.id) {
      throw new ForbiddenException('You cannot edit this vendor package');
    }

    await this.vendorPackagesRepository.save({
      ...vendorPackage,
      name: dto.name?.trim() ?? vendorPackage.name,
      description: dto.description?.trim() ?? vendorPackage.description,
      price:
        dto.price != null ? this.normalizeMoney(dto.price) : vendorPackage.price,
    });

    return this.getMyVendorProfileOrFail(userId);
  }

  private async getVendorEntityByUserIdOrFail(userId: string): Promise<VendorProfile> {
    const vendor = await this.vendorProfilesRepository.findOne({
      where: { userId },
      relations: { bookingPreference: true },
    });

    if (!vendor) {
      throw new NotFoundException('Create your vendor profile first');
    }

    return vendor;
  }

  private async getVendorRequestOrFail(
    requestId: string,
    userId: string,
    role: Role,
  ): Promise<VendorRequestResponseDto> {
    const vendorRequest = await this.vendorRequestsRepository.findOne({
      where: { id: requestId },
      relations: {
        event: true,
        vendorProfile: true,
      },
    });

    if (!vendorRequest) {
      throw new NotFoundException('Vendor request not found');
    }

    if (
      role != Role.ADMIN &&
      vendorRequest.organizerId != userId &&
      vendorRequest.vendorProfile.userId != userId
    ) {
      throw new ForbiddenException('You cannot view this vendor request');
    }

    return this.toVendorRequestResponse(vendorRequest);
  }

  private async getMyVendorProfileOrFail(
    userId: string,
  ): Promise<VendorProfileResponseDto> {
    const profile = await this.getMyVendorProfile(userId);
    if (!profile) {
      throw new NotFoundException('Vendor profile not found');
    }
    return profile;
  }

  private assertVendorRole(role: Role): void {
    if (role != Role.VENDOR && role != Role.ADMIN) {
      throw new ForbiddenException('Only vendors can manage vendor profiles');
    }
  }

  private normalizeMoney(value: string): string {
    const parsed = Number.parseFloat(value);
    if (!Number.isFinite(parsed) || parsed < 0) {
      throw new BadRequestException('Amount must be zero or greater');
    }

    return parsed.toFixed(2);
  }

  toVendorProfileResponse(
    vendor: VendorProfile,
    options?: {
      distanceKm?: number | null;
      withinTravelRadius?: boolean | null;
    },
  ): VendorProfileResponseDto {
    return {
      id: vendor.id,
      userId: vendor.userId,
      businessName: vendor.businessName,
      description: vendor.description,
      category: vendor.category,
      serviceArea: vendor.serviceArea,
      latitude: toNullableNumber(vendor.latitude),
      longitude: toNullableNumber(vendor.longitude),
      travelRadiusKm: toNullableNumber(vendor.travelRadiusKm),
      distanceKm: options?.distanceKm ?? null,
      withinTravelRadius: options?.withinTravelRadius ?? null,
      portfolioImageUrl: vendor.portfolioImageUrl,
      verificationDocumentUrl: vendor.verificationDocumentUrl,
      verified: vendor.verified,
      ratingAverage: vendor.ratingAverage,
      services: (vendor.services ?? []).map((service) => ({
        id: service.id,
        name: service.name,
        description: service.description,
        basePrice: service.basePrice,
        pricingModel: service.pricingModel,
      })),
      packages: (vendor.packages ?? []).map((vendorPackage) => ({
        id: vendorPackage.id,
        name: vendorPackage.name,
        description: vendorPackage.description,
        price: vendorPackage.price,
      })),
      bookingPreference: vendor.bookingPreference
          ? {
              allowDirectBooking: vendor.bookingPreference.allowDirectBooking,
              allowRequestBooking: vendor.bookingPreference.allowRequestBooking,
            }
        : null,
    };
  }

  toVendorRequestResponse(vendorRequest: VendorRequest): VendorRequestResponseDto {
    return {
      id: vendorRequest.id,
      event: {
        id: vendorRequest.event.id,
        title: vendorRequest.event.title,
        city: vendorRequest.event.city,
        venue: vendorRequest.event.venue,
        startAt: vendorRequest.event.startAt,
        endAt: vendorRequest.event.endAt,
      },
      organizerId: vendorRequest.organizerId,
      vendor: {
        id: vendorRequest.vendorProfile.id,
        userId: vendorRequest.vendorProfile.userId,
        businessName: vendorRequest.vendorProfile.businessName,
        category: vendorRequest.vendorProfile.category,
        serviceArea: vendorRequest.vendorProfile.serviceArea,
        verified: vendorRequest.vendorProfile.verified,
      },
      status: vendorRequest.status,
      message: vendorRequest.message,
      proposedBudget: vendorRequest.proposedBudget,
      createdAt: vendorRequest.createdAt,
      updatedAt: vendorRequest.updatedAt,
    };
  }

  private formatOptionalCoordinate(value: number | null | undefined): string | null {
    if (value == null) {
      return null;
    }

    return value.toFixed(6);
  }

  private formatOptionalRadius(
    radiusKm: number | null | undefined,
    latitude: number | null | undefined,
    longitude: number | null | undefined,
  ): string | null {
    const hasLatitude = latitude != null;
    const hasLongitude = longitude != null;

    if (hasLatitude !== hasLongitude) {
      throw new BadRequestException(
        'Vendor base location requires both latitude and longitude',
      );
    }

    if (!hasLatitude) {
      if (radiusKm != null) {
        throw new BadRequestException(
          'Travel radius requires a vendor base location',
        );
      }
      return null;
    }

    return (radiusKm ?? 80).toFixed(2);
  }
}
