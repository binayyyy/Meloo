import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { VendorProfile } from './vendor-profile.entity';

@Entity({ name: 'vendor_services' })
export class VendorService {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'vendor_id' })
  vendorId!: string;

  @Column({ type: 'varchar' })
  name!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'numeric', precision: 10, scale: 2, name: 'base_price' })
  basePrice!: string;

  @Column({ type: 'varchar', name: 'pricing_model' })
  pricingModel!: string;

  @ManyToOne(() => VendorProfile, (vendorProfile) => vendorProfile.services, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'vendor_id' })
  vendorProfile!: VendorProfile;
}

