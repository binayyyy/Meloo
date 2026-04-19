import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { EventsModule } from '../events/events.module';
import { Event } from '../events/entities';
import { SupportModule } from '../support/support.module';
import { Escalation, SupportTicket } from '../support/entities';
import { SponsorProfile } from '../sponsors/entities';
import { VendorsModule } from '../vendors/vendors.module';
import { VendorProfile } from '../vendors/entities';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [
    AuthModule,
    EventsModule,
    SupportModule,
    VendorsModule,
    TypeOrmModule.forFeature([
      Event,
      VendorProfile,
      SponsorProfile,
      SupportTicket,
      Escalation,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
