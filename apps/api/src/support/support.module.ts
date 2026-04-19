import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiModule } from '../ai/ai.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { User } from '../users/entities';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { Escalation, SupportTicket } from './entities';

@Module({
  imports: [
    AiModule,
    AuthModule,
    NotificationsModule,
    TypeOrmModule.forFeature([SupportTicket, Escalation, User]),
  ],
  controllers: [SupportController],
  providers: [SupportService],
  exports: [SupportService],
})
export class SupportModule {}
