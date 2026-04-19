import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { Event } from '../../events/entities';
import { User } from '../../users/entities';
import { SponsorshipInterest } from './sponsorship-interest.entity';

export enum SponsorshipOpportunityStatus {
  OPEN = 'open',
  CLOSED = 'closed',
  FILLED = 'filled',
}

@Entity({ name: 'sponsorship_opportunities' })
export class SponsorshipOpportunity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'event_id' })
  eventId!: string;

  @Column({ type: 'uuid', name: 'organizer_id' })
  organizerId!: string;

  @Column({ type: 'varchar' })
  title!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({ type: 'numeric', precision: 12, scale: 2, name: 'required_amount' })
  requiredAmount!: string;

  @Column({ type: 'varchar', name: 'target_audience' })
  targetAudience!: string;

  @Column({ type: 'text', name: 'benefits_offered' })
  benefitsOffered!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: SponsorshipOpportunityStatus,
    default: SponsorshipOpportunityStatus.OPEN,
  })
  status!: SponsorshipOpportunityStatus;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: DATE_COLUMN_TYPE, name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => Event, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'event_id' })
  event!: Event;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'organizer_id' })
  organizer!: User;

  @OneToMany(() => SponsorshipInterest, (interest) => interest.opportunity)
  interests!: SponsorshipInterest[];
}
