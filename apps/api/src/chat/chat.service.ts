import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { NotificationType } from '../notifications/entities';
import { NotificationsService } from '../notifications/notifications.service';
import { User } from '../users/entities';
import {
  ConversationResponseDto,
  CreateDirectConversationDto,
  MessageResponseDto,
  SendMessageDto,
} from './dto';
import { ChatRealtimeService } from './chat-realtime.service';
import {
  Conversation,
  ConversationParticipant,
  ConversationType,
  Message,
  MessageType,
} from './entities';

@Injectable()
export class ChatService {
  constructor(
    private readonly aiService: AiService,
    private readonly chatRealtimeService: ChatRealtimeService,
    private readonly notificationsService: NotificationsService,
    @InjectRepository(Conversation)
    private readonly conversationsRepository: Repository<Conversation>,
    @InjectRepository(ConversationParticipant)
    private readonly participantsRepository: Repository<ConversationParticipant>,
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async listMyConversations(userId: string): Promise<ConversationResponseDto[]> {
    const memberships = await this.participantsRepository.find({
      where: { userId },
      relations: {
        conversation: {
          participants: {
            user: {
              profile: true,
            },
          },
        },
      },
      order: {
        joinedAt: 'DESC',
      },
    });

    const conversations = memberships.map((membership) => membership.conversation);
    const lastMessages = await Promise.all(
      conversations.map((conversation) => this.findLastMessage(conversation.id)),
    );

    return conversations
      .map((conversation, index) =>
        this.toConversationResponse(conversation, lastMessages[index]),
      )
      .sort((left, right) => {
        const leftTime = left.lastMessage?.createdAt ?? left.createdAt;
        const rightTime = right.lastMessage?.createdAt ?? right.createdAt;
        return rightTime.getTime() - leftTime.getTime();
      });
  }

  async createDirectConversation(
    userId: string,
    dto: CreateDirectConversationDto,
  ): Promise<ConversationResponseDto> {
    if (dto.participantUserId === userId) {
      throw new ForbiddenException('You cannot start a conversation with yourself');
    }

    const [me, otherUser] = await Promise.all([
      this.usersRepository.findOne({
        where: { id: userId },
        relations: { profile: true },
      }),
      this.usersRepository.findOne({
        where: { id: dto.participantUserId },
        relations: { profile: true },
      }),
    ]);

    if (!me || !otherUser) {
      throw new NotFoundException('User not found');
    }

    const existingMemberships = await this.participantsRepository.find({
      where: { userId },
      relations: {
        conversation: {
          participants: true,
        },
      },
    });

    const existingConversation = existingMemberships
      .map((membership) => membership.conversation)
      .find(
        (conversation) =>
          conversation.type === ConversationType.DIRECT &&
          conversation.participants.length === 2 &&
          conversation.participants.some(
            (participant) => participant.userId === dto.participantUserId,
          ),
      );

    if (existingConversation) {
      return this.getConversationOrFail(existingConversation.id, userId);
    }

    const conversation = await this.conversationsRepository.save(
      this.conversationsRepository.create({
        type: ConversationType.DIRECT,
      }),
    );

    await this.participantsRepository.save([
      this.participantsRepository.create({
        conversationId: conversation.id,
        userId,
      }),
      this.participantsRepository.create({
        conversationId: conversation.id,
        userId: dto.participantUserId,
      }),
    ]);

    const systemMessage = await this.messagesRepository.save(
      this.messagesRepository.create({
        conversationId: conversation.id,
        senderId: userId,
        body: 'Conversation started',
        messageType: MessageType.SYSTEM,
      }),
    );

    return this.getConversationOrFail(conversation.id, userId, systemMessage.id);
  }

  async getConversationOrFail(
    conversationId: string,
    userId: string,
    lastMessageId?: string,
  ): Promise<ConversationResponseDto> {
    const conversation = await this.findConversationWithParticipants(conversationId);
    await this.assertConversationParticipant(conversationId, userId);
    const lastMessage = lastMessageId
      ? await this.getMessageByIdOrFail(lastMessageId, conversationId)
      : await this.findLastMessage(conversationId);

    return this.toConversationResponse(conversation, lastMessage);
  }

  async listMessages(
    userId: string,
    conversationId: string,
  ): Promise<MessageResponseDto[]> {
    await this.assertConversationParticipant(conversationId, userId);
    const messages = await this.messagesRepository.find({
      where: { conversationId },
      relations: {
        sender: {
          profile: true,
        },
      },
      order: {
        createdAt: 'ASC',
      },
    });

    return messages.map((message) => this.toMessageResponse(message));
  }

  async sendMessage(
    userId: string,
    conversationId: string,
    dto: SendMessageDto,
  ): Promise<MessageResponseDto> {
    const conversation = await this.findConversationWithParticipants(conversationId);
    await this.assertConversationParticipant(conversationId, userId);

    const message = await this.messagesRepository.save(
      this.messagesRepository.create({
        conversationId,
        senderId: userId,
        body: dto.body.trim(),
        messageType: MessageType.TEXT,
      }),
    );

    const hydratedMessage = await this.getMessageByIdOrFail(message.id, conversationId);
    const response = this.toMessageResponse(hydratedMessage);
    this.chatRealtimeService.broadcastToConversation(conversationId, {
      event: 'message_created',
      data: response,
    });

    const recipients = conversation.participants.filter(
      (participant) => participant.userId !== userId,
    );
    await Promise.all(
      recipients.map((participant) =>
        this.notificationsService.createNotification({
          userId: participant.userId,
          type: NotificationType.CHAT,
          title: 'New chat message',
          body: dto.body.trim().slice(0, 180),
          resourceType: 'conversation',
          resourceId: conversationId,
        }),
      ),
    );

    await this.maybeSendAssistantReplies(conversation, userId, recipients);
    return response;
  }

  async assertConversationParticipant(
    conversationId: string,
    userId: string,
  ): Promise<void> {
    const membership = await this.participantsRepository.findOne({
      where: { conversationId, userId },
    });

    if (!membership) {
      throw new ForbiddenException('You are not part of this conversation');
    }
  }

  async listConversationParticipantIds(conversationId: string): Promise<string[]> {
    const participants = await this.participantsRepository.find({
      where: { conversationId },
    });
    return participants.map((participant) => participant.userId);
  }

  private async findConversationWithParticipants(
    conversationId: string,
  ): Promise<Conversation> {
    const conversation = await this.conversationsRepository.findOne({
      where: { id: conversationId },
      relations: {
        participants: {
          user: {
            profile: true,
            setting: true,
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return conversation;
  }

  private findLastMessage(conversationId: string): Promise<Message | null> {
    return this.messagesRepository.findOne({
      where: { conversationId },
      relations: {
        sender: {
          profile: true,
        },
      },
      order: { createdAt: 'DESC' },
    });
  }

  private async getMessageByIdOrFail(
    messageId: string,
    conversationId: string,
  ): Promise<Message> {
    const message = await this.messagesRepository.findOne({
      where: { id: messageId, conversationId },
      relations: {
        sender: {
          profile: true,
        },
      },
    });

    if (!message) {
      throw new NotFoundException('Message not found');
    }

    return message;
  }

  private toConversationResponse(
    conversation: Conversation,
    lastMessage: Message | null,
  ): ConversationResponseDto {
    return {
      id: conversation.id,
      type: conversation.type,
      participants: conversation.participants.map((participant) => ({
        userId: participant.user.id,
        email: participant.user.email,
        role: participant.user.role,
        fullName: participant.user.profile?.fullName ?? null,
      })),
      lastMessage: lastMessage ? this.toMessageResponse(lastMessage) : null,
      createdAt: conversation.createdAt,
    };
  }

  private toMessageResponse(message: Message): MessageResponseDto {
    return {
      id: message.id,
      conversationId: message.conversationId,
      sender: {
        userId: message.sender.id,
        email: message.sender.email,
        role: message.sender.role,
        fullName: message.sender.profile?.fullName ?? null,
      },
      body: message.body,
      messageType: message.messageType,
      createdAt: message.createdAt,
    };
  }

  private async maybeSendAssistantReplies(
    conversation: Conversation,
    originalSenderId: string,
    recipients: ConversationParticipant[],
  ): Promise<void> {
    if (conversation.type !== ConversationType.DIRECT) {
      return;
    }

    for (const finalRecipient of recipients) {
      const enabled = finalRecipient.user.setting?.aiAssistEnabled ?? true;
      if (!enabled) {
        continue;
      }

      const assistantBody = await this.aiService.generateChatAutoReply(
        finalRecipient.userId,
        finalRecipient.user.role,
        conversation.id,
      );

      const assistantMessage = await this.messagesRepository.save(
        this.messagesRepository.create({
          conversationId: conversation.id,
          senderId: finalRecipient.userId,
          body: assistantBody.trim(),
          messageType: MessageType.ASSISTANT,
        }),
      );
      const hydratedAssistantMessage = await this.getMessageByIdOrFail(
        assistantMessage.id,
        conversation.id,
      );
      const response = this.toMessageResponse(hydratedAssistantMessage);

      this.chatRealtimeService.broadcastToConversation(conversation.id, {
        event: 'message_created',
        data: response,
      });

      await this.notificationsService.createNotification({
        userId: originalSenderId,
        type: NotificationType.CHAT,
        title: 'AI-assisted reply',
        body: assistantBody.trim().slice(0, 180),
        resourceType: 'conversation',
        resourceId: conversation.id,
      });
    }
  }
}
