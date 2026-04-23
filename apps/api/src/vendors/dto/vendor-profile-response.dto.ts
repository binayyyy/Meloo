import { VendorBookingPreferenceResponseDto } from './vendor-booking-preference-response.dto';
import { VendorPackageResponseDto } from './vendor-package-response.dto';
import { VendorServiceResponseDto } from './vendor-service-response.dto';

export class VendorProfileResponseDto {
  id!: string;
  userId!: string;
  businessName!: string;
  description!: string;
  category!: string;
  serviceArea!: string;
  latitude!: number | null;
  longitude!: number | null;
  travelRadiusKm!: number | null;
  distanceKm!: number | null;
  withinTravelRadius!: boolean | null;
  portfolioImageUrl!: string | null;
  verificationDocumentUrl!: string | null;
  verified!: boolean;
  ratingAverage!: string;
  services!: VendorServiceResponseDto[];
  packages!: VendorPackageResponseDto[];
  bookingPreference!: VendorBookingPreferenceResponseDto | null;
}
