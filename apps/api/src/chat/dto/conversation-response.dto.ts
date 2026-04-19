import { Role } from '../../common/enums/role.enum';
import { ConversationType, MessageType } from '../entities';

export class ChatUserSummaryDto {
  userId!: string;
  email!: string;
  role!: Role;
  fullName!: string | null;
}

export class MessageSenderSummaryDto {
  userId!: string;
  email!: string;
  role!: Role;
  fullName!: string | null;
}

export class MessageResponseDto {
  id!: string;
  conversationId!: string;
  sender!: MessageSenderSummaryDto;
  body!: string;
  messageType!: MessageType;
  createdAt!: Date;
}

export class ConversationResponseDto {
  id!: string;
  type!: ConversationType;
  participants!: ChatUserSummaryDto[];
  lastMessage!: MessageResponseDto | null;
  createdAt!: Date;
}
