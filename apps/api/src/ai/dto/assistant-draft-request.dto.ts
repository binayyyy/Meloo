import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export enum AiAssistantDraftIntent {
  CHAT_REPLY = 'chat_reply',
  ORGANIZER_PLAN = 'organizer_plan',
  VENDOR_PROPOSAL = 'vendor_proposal',
  SPONSOR_PROPOSAL = 'sponsor_proposal',
}

export class AiAssistantDraftRequestDto {
  @IsEnum(AiAssistantDraftIntent)
  intent!: AiAssistantDraftIntent;

  @IsOptional()
  @IsUUID()
  conversationId?: string;

  @IsOptional()
  @IsUUID()
  eventId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(3000)
  prompt?: string;
}
