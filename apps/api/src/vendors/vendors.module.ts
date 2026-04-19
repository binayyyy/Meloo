import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Event } from '../events/entities';
import { NotificationsModule } from '../notifications/notifications.module';
import {
  VendorBookingPreference,
  VendorPackage,
  VendorProfile,
  VendorRequest,
  VendorService,
} from './entities';
import { VendorsController } from './vendors.controller';
import { VendorsService } from './vendors.service';

@Module({
  imports: [
    AuthModule,
    NotificationsModule,
    TypeOrmModule.forFeature([
      Event,
      VendorProfile,
      VendorService,
      VendorPackage,
      VendorBookingPreference,
      VendorRequest,
    ]),
  ],
  controllers: [VendorsController],
  providers: [VendorsService],
  exports: [VendorsService],
})
export class VendorsModule {}
