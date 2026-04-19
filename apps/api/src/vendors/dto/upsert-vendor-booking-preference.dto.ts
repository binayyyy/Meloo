import { IsBoolean } from 'class-validator';

export class UpsertVendorBookingPreferenceDto {
  @IsBoolean()
  allowDirectBooking!: boolean;

  @IsBoolean()
  allowRequestBooking!: boolean;
}

