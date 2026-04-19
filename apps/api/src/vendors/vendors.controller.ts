import {
  Body,
  Controller,
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
import { VendorsService } from './vendors.service';

@Controller('vendors')
export class VendorsController {
  constructor(private readonly vendorsService: VendorsService) {}

  @Get()
  listPublicVendors(
    @Query() query: ListVendorsQueryDto,
  ): Promise<VendorProfileResponseDto[]> {
    return this.vendorsService.listPublicVendors(query);
  }

  @Get(':id')
  getPublicVendor(
    @Param('id') vendorId: string,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.getPublicVendorProfile(vendorId);
  }

  @Get('me/profile')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  getMyVendorProfile(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<VendorProfileResponseDto | null> {
    return this.vendorsService.getMyVendorProfile(user.sub);
  }

  @Patch('me/profile')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  upsertMyVendorProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertVendorProfileDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.upsertMyVendorProfile(user.sub, user.role, dto);
  }

  @Patch('me/booking-preference')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  upsertBookingPreference(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertVendorBookingPreferenceDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.upsertMyBookingPreference(user.sub, user.role, dto);
  }

  @Post('me/services')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  createVendorService(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateVendorServiceDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.createVendorService(user.sub, user.role, dto);
  }

  @Patch('services/:id')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  updateVendorService(
    @Param('id') serviceId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateVendorServiceDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.updateVendorService(
      serviceId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Post('me/packages')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  createVendorPackage(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateVendorPackageDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.createVendorPackage(user.sub, user.role, dto);
  }

  @Patch('packages/:id')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  updateVendorPackage(
    @Param('id') packageId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateVendorPackageDto,
  ): Promise<VendorProfileResponseDto> {
    return this.vendorsService.updateVendorPackage(
      packageId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Post(':id/requests')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  createVendorRequest(
    @Param('id') vendorId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateVendorRequestDto,
  ): Promise<VendorRequestResponseDto> {
    return this.vendorsService.createVendorRequest(
      vendorId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Get('requests/my-organizer')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  listMyOrganizerRequests(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<VendorRequestResponseDto[]> {
    return this.vendorsService.listMyOrganizerRequests(user.sub, user.role);
  }

  @Get('requests/my-vendor')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  listMyVendorRequests(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<VendorRequestResponseDto[]> {
    return this.vendorsService.listMyVendorRequests(user.sub, user.role);
  }

  @Patch('requests/:id/respond')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.VENDOR, Role.ADMIN)
  respondToVendorRequest(
    @Param('id') requestId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RespondVendorRequestDto,
  ): Promise<VendorRequestResponseDto> {
    return this.vendorsService.respondToVendorRequest(
      requestId,
      user.sub,
      user.role,
      dto,
    );
  }

  @Patch('requests/:id/book')
  @UseGuards(AccessTokenGuard, RolesGuard)
  @Roles(Role.ORGANIZER, Role.ADMIN)
  markVendorRequestBooked(
    @Param('id') requestId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<VendorRequestResponseDto> {
    return this.vendorsService.markVendorRequestBooked(
      requestId,
      user.sub,
      user.role,
    );
  }
}
