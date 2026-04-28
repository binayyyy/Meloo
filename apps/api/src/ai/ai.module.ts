import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { EventsModule } from '../events/events.module';
import { Event } from '../events/entities';
import { SponsorsModule } from '../sponsors/sponsors.module';
import { SponsorProfile, SponsorshipOpportunity } from '../sponsors/entities';
import { ConversationParticipant, Message } from '../chat/entities';
import { UserProfile } from '../users/entities';
import { VendorsModule } from '../vendors/vendors.module';
import { VendorProfile } from '../vendors/entities';
import { AiController } from './ai.controller';
import { AiGatewayService } from './ai-gateway.service';
import { AiService } from './ai.service';

@Module({
  imports: [
    AuthModule,
    EventsModule,
    SponsorsModule,
    VendorsModule,
    TypeOrmModule.forFeature([
      Event,
      SponsorProfile,
      SponsorshipOpportunity,
      UserProfile,
      VendorProfile,
      ConversationParticipant,
      Message,
    ]),
  ],
  controllers: [AiController],
  providers: [AiService, AiGatewayService],
  exports: [AiService],
})
export class AiModule {}
