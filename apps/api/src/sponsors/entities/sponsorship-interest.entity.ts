import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { SponsorProfile } from './sponsor-profile.entity';
import { SponsorshipOpportunity } from './sponsorship-opportunity.entity';

export enum SponsorshipInterestStatus {
  EXPRESSED = 'expressed',
  REVIEWING = 'reviewing',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
}

@Entity({ name: 'sponsorship_interests' })
export class SponsorshipInterest {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'sponsor_id' })
  sponsorId!: string;

  @Column({ type: 'uuid', name: 'opportunity_id' })
  opportunityId!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: SponsorshipInterestStatus,
    default: SponsorshipInterestStatus.EXPRESSED,
  })
  status!: SponsorshipInterestStatus;

  @Column({ type: 'text' })
  message!: string;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => SponsorProfile, (sponsorProfile) => sponsorProfile.interests, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'sponsor_id' })
  sponsorProfile!: SponsorProfile;

  @ManyToOne(
    () => SponsorshipOpportunity,
    (opportunity) => opportunity.interests,
    { onDelete: 'CASCADE' },
  )
  @JoinColumn({ name: 'opportunity_id' })
  opportunity!: SponsorshipOpportunity;
}
