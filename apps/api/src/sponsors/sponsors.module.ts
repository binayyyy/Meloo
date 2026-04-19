import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Event } from '../events/entities';
import { NotificationsModule } from '../notifications/notifications.module';
import {
  SponsorProfile,
  SponsorshipInterest,
  SponsorshipOpportunity,
} from './entities';
import { SponsorsController } from './sponsors.controller';
import { SponsorsService } from './sponsors.service';

@Module({
  imports: [
    AuthModule,
    NotificationsModule,
    TypeOrmModule.forFeature([
      SponsorProfile,
      SponsorshipOpportunity,
      SponsorshipInterest,
      Event,
    ]),
  ],
  controllers: [SponsorsController],
  providers: [SponsorsService],
  exports: [SponsorsService],
})
export class SponsorsModule {}
