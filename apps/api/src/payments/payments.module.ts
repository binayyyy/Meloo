import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { Event } from '../events/entities';
import { NotificationsModule } from '../notifications/notifications.module';
import { Registration, TicketType } from '../registrations/entities';
import { User } from '../users/entities';
import { Booking, Payment, Refund } from './entities';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

@Module({
  imports: [
    AuthModule,
    NotificationsModule,
    TypeOrmModule.forFeature([
      Booking,
      Payment,
      Refund,
      Event,
      Registration,
      TicketType,
      User,
    ]),
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
