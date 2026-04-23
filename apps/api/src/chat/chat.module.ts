import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Session, User } from '../users/entities';
import { ChatRealtimeService } from './chat-realtime.service';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { Conversation, ConversationParticipant, Message } from './entities';

@Module({
  imports: [
    AuthModule,
    NotificationsModule,
    TypeOrmModule.forFeature([
      Conversation,
      ConversationParticipant,
      Message,
      Session,
      User,
    ]),
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatRealtimeService, ChatGateway],
  exports: [ChatService],
})
export class ChatModule {}
