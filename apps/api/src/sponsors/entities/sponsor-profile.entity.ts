import { Column, Entity, JoinColumn, OneToMany, OneToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities';
import { SponsorshipInterest } from './sponsorship-interest.entity';

@Entity({ name: 'sponsor_profiles' })
export class SponsorProfile {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'user_id', unique: true })
  userId!: string;

  @Column({ type: 'varchar', name: 'company_name' })
  companyName!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'varchar' })
  industries!: string;

  @Column({ type: 'varchar', name: 'logo_url', nullable: true })
  logoUrl!: string | null;

  @Column({ type: 'varchar', name: 'website_url', nullable: true })
  websiteUrl!: string | null;

  @Column({ type: 'varchar', name: 'verification_document_url', nullable: true })
  verificationDocumentUrl!: string | null;

  @Column({ type: 'boolean', default: false })
  verified!: boolean;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @OneToMany(() => SponsorshipInterest, (interest) => interest.sponsorProfile)
  interests!: SponsorshipInterest[];
}
