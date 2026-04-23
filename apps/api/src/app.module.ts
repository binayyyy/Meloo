import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import aiConfig from './config/ai.config';
import appConfig from './config/app.config';
import authConfig from './config/auth.config';
import databaseConfig from './config/database.config';
import paymentsConfig from './config/payments.config';
import uploadsConfig from './config/uploads.config';
import { AiModule } from './ai/ai.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { ChatModule } from './chat/chat.module';
import { CommonModule } from './common/common.module';
import { DatabaseModule } from './database/database.module';
import { EventsModule } from './events/events.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PaymentsModule } from './payments/payments.module';
import { RegistrationsModule } from './registrations/registrations.module';
import { SponsorsModule } from './sponsors/sponsors.module';
import { SupportModule } from './support/support.module';
import { UploadsModule } from './uploads/uploads.module';
import { UsersModule } from './users/users.module';
import { VendorsModule } from './vendors/vendors.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [
        appConfig,
        authConfig,
        databaseConfig,
        paymentsConfig,
        aiConfig,
        uploadsConfig,
      ],
    }),
    CommonModule,
    DatabaseModule,
    AdminModule,
    AiModule,
    AuthModule,
    ChatModule,
    UsersModule,
    EventsModule,
    NotificationsModule,
    PaymentsModule,
    RegistrationsModule,
    SponsorsModule,
    SupportModule,
    UploadsModule,
    VendorsModule,
  ],
})
export class AppModule {}
