import { Column, Entity, JoinColumn, OneToOne, PrimaryGeneratedColumn } from 'typeorm';
import { VendorProfile } from './vendor-profile.entity';

@Entity({ name: 'vendor_booking_preferences' })
export class VendorBookingPreference {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'vendor_id', unique: true })
  vendorId!: string;

  @Column({ type: 'boolean', name: 'allow_direct_booking', default: false })
  allowDirectBooking!: boolean;

  @Column({ type: 'boolean', name: 'allow_request_booking', default: true })
  allowRequestBooking!: boolean;

  @OneToOne(
    () => VendorProfile,
    (vendorProfile) => vendorProfile.bookingPreference,
    { onDelete: 'CASCADE' },
  )
  @JoinColumn({ name: 'vendor_id' })
  vendorProfile!: VendorProfile;
}

