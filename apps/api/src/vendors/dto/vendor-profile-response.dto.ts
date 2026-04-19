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
  verified!: boolean;
  ratingAverage!: string;
  services!: VendorServiceResponseDto[];
  packages!: VendorPackageResponseDto[];
  bookingPreference!: VendorBookingPreferenceResponseDto | null;
}

