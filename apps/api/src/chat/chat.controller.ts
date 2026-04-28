import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import {
  ConversationResponseDto,
  CreateDirectConversationDto,
  MessageResponseDto,
  SendMessageDto,
} from './dto';
import { ChatService } from './chat.service';

@Controller('chat')
@UseGuards(AccessTokenGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('conversations/my')
  listMyConversations(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ConversationResponseDto[]> {
    return this.chatService.listMyConversations(user.sub);
  }

  @Post('conversations/direct')
  createDirectConversation(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateDirectConversationDto,
  ): Promise<ConversationResponseDto> {
    return this.chatService.createDirectConversation(user.sub, dto);
  }

  @Get('conversations/:id/messages')
  listMessages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') conversationId: string,
  ): Promise<MessageResponseDto[]> {
    return this.chatService.listMessages(user.sub, conversationId);
  }

  @Post('conversations/:id/messages')
  sendMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') conversationId: string,
    @Body() dto: SendMessageDto,
  ): Promise<MessageResponseDto> {
    return this.chatService.sendMessage(user.sub, conversationId, dto);
  }
}
