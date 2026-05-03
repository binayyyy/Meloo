import { IsEmail, IsOptional, IsUUID } from 'class-validator';

export class CreateDirectConversationDto {
  @IsOptional()
  @IsUUID()
  participantUserId?: string;

  @IsOptional()
  @IsEmail()
  participantEmail?: string;
}
