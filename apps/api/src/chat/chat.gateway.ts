import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { IncomingMessage } from 'http';
import { MoreThan, Repository } from 'typeorm';
import { Server, WebSocket } from 'ws';
import { UserStatus } from '../common/enums/user-status.enum';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { Session } from '../users/entities';
import { SendMessageDto } from './dto';
import { ChatRealtimeService } from './chat-realtime.service';
import { ChatService } from './chat.service';

interface AuthenticatedSocket extends WebSocket {
  user?: AuthenticatedUser;
}

interface JoinConversationPayload {
  conversationId: string;
}

interface SendMessagePayload extends SendMessageDto {
  conversationId: string;
}

@WebSocketGateway({
  path: '/chat',
})
export class ChatGateway
  implements OnGatewayConnection<AuthenticatedSocket>, OnGatewayDisconnect<AuthenticatedSocket>
{
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly chatService: ChatService,
    private readonly chatRealtimeService: ChatRealtimeService,
    @InjectRepository(Session)
    private readonly sessionsRepository: Repository<Session>,
  ) {}

  @WebSocketServer()
  server!: Server;

  async handleConnection(
    client: AuthenticatedSocket,
    request: IncomingMessage,
  ): Promise<void> {
    const token = this.extractToken(request);
    if (!token) {
      client.close(4001, 'Missing token');
      return;
    }

    try {
      const payload = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.configService.getOrThrow<string>('auth.jwtSecret'),
        issuer: this.configService.get<string>('auth.jwtIssuer'),
        audience: this.configService.get<string>('auth.jwtAudience'),
      });

      const session = await this.sessionsRepository.findOne({
        where: {
          id: payload.sessionId,
          userId: payload.sub,
          expiresAt: MoreThan(new Date()),
        },
        relations: {
          user: true,
        },
      });

      if (
        !session ||
        session.user.status === UserStatus.SUSPENDED ||
        session.user.status === UserStatus.DEACTIVATED
      ) {
        client.close(4001, 'Session is no longer active');
        return;
      }

      client.user = payload;
    } catch {
      client.close(4001, 'Invalid access token');
    }
  }

  handleDisconnect(client: AuthenticatedSocket): void {
    this.chatRealtimeService.removeClient(client);
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() payload: JoinConversationPayload,
  ): Promise<{ event: string; data: JoinConversationPayload }> {
    const user = client.user;
    if (!user) {
      throw new WsException('Unauthorized');
    }

    await this.chatService.assertConversationParticipant(
      payload.conversationId,
      user.sub,
    );

    this.chatRealtimeService.joinConversation(payload.conversationId, client);

    return {
      event: 'conversation_joined',
      data: payload,
    };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() payload: SendMessagePayload,
  ): Promise<{ event: string; data: { accepted: true } }> {
    const user = client.user;
    if (!user) {
      throw new WsException('Unauthorized');
    }

    const message = await this.chatService.sendMessage(user.sub, payload.conversationId, {
      body: payload.body,
    });

    this.chatRealtimeService.broadcastToConversation(payload.conversationId, {
      event: 'message_created',
      data: message,
    });

    return {
      event: 'message_accepted',
      data: { accepted: true },
    };
  }

  private extractToken(request: IncomingMessage): string | null {
    const url = request.url ?? '';
    const queryIndex = url.indexOf('?');
    if (queryIndex === -1) {
      return null;
    }

    const query = new URLSearchParams(url.slice(queryIndex + 1));
    const token = query.get('token');
    return token?.trim() || null;
  }
}
