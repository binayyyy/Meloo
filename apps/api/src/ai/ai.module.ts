import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { EventsModule } from '../events/events.module';
import { Event } from '../events/entities';
import { SponsorsModule } from '../sponsors/sponsors.module';
import { SponsorProfile, SponsorshipOpportunity } from '../sponsors/entities';
import { ConversationParticipant, Message } from '../chat/entities';
import { SupportTicket } from '../support/entities';
import { User, UserProfile } from '../users/entities';
import { VendorsModule } from '../vendors/vendors.module';
import { VendorProfile } from '../vendors/entities';
import { AiController } from './ai.controller';
import { AiContextService } from './ai-context.service';
import { AiGatewayService } from './ai-gateway.service';
import { AiHarnessService } from './ai-harness.service';
import { AiMemoryService } from './ai-memory.service';
import { AiPolicyService } from './ai-policy.service';
import { AiService } from './ai.service';
import { AiContextDocument, AiResponseCache } from './entities';

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
      User,
      VendorProfile,
      SupportTicket,
      ConversationParticipant,
      Message,
      AiContextDocument,
      AiResponseCache,
    ]),
  ],
  controllers: [AiController],
  providers: [
    AiService,
    AiGatewayService,
    AiMemoryService,
    AiContextService,
    AiPolicyService,
    AiHarnessService,
  ],
  exports: [AiService],
})
export class AiModule {}
