import {
  Column,
  Entity,
  JoinColumn,
  OneToMany,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities';
import { VendorBookingPreference } from './vendor-booking-preference.entity';
import { VendorPackage } from './vendor-package.entity';
import { VendorService } from './vendor-service.entity';

@Entity({ name: 'vendor_profiles' })
export class VendorProfile {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id', unique: true })
  userId!: string;

  @Column({ type: 'varchar', name: 'business_name' })
  businessName!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'varchar' })
  category!: string;

  @Column({ type: 'varchar', name: 'service_area' })
  serviceArea!: string;

  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true })
  latitude!: string | null;

  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true })
  longitude!: string | null;

  @Column({
    type: 'numeric',
    precision: 6,
    scale: 2,
    name: 'travel_radius_km',
    nullable: true,
  })
  travelRadiusKm!: string | null;

  @Column({ type: 'varchar', name: 'portfolio_image_url', nullable: true })
  portfolioImageUrl!: string | null;

  @Column({ type: 'varchar', name: 'verification_document_url', nullable: true })
  verificationDocumentUrl!: string | null;

  @Column({ type: 'boolean', default: false })
  verified!: boolean;

  @Column({
    type: 'numeric',
    precision: 4,
    scale: 2,
    name: 'rating_average',
    default: '0.00',
  })
  ratingAverage!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @OneToMany(() => VendorService, (service) => service.vendorProfile)
  services!: VendorService[];

  @OneToMany(() => VendorPackage, (vendorPackage) => vendorPackage.vendorProfile)
  packages!: VendorPackage[];

  @OneToOne(
    () => VendorBookingPreference,
    (bookingPreference) => bookingPreference.vendorProfile,
  )
  bookingPreference!: VendorBookingPreference | null;
}
