import { IsUUID } from 'class-validator';

export class CreateDirectConversationDto {
  @IsUUID()
  participantUserId!: string;
}
