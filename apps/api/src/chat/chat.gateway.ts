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
import { IncomingMessage } from 'http';
import { Server, WebSocket } from 'ws';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { SendMessageDto } from './dto';
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
  ) {}

  @WebSocketServer()
  server!: Server;

  private readonly conversationRooms = new Map<string, Set<AuthenticatedSocket>>();

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
      client.user = await this.jwtService.verifyAsync<AuthenticatedUser>(token, {
        secret: this.configService.getOrThrow<string>('auth.jwtSecret'),
        issuer: this.configService.get<string>('auth.jwtIssuer'),
        audience: this.configService.get<string>('auth.jwtAudience'),
      });
    } catch {
      client.close(4001, 'Invalid access token');
    }
  }

  handleDisconnect(client: AuthenticatedSocket): void {
    for (const clients of this.conversationRooms.values()) {
      clients.delete(client);
    }
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

    if (!this.conversationRooms.has(payload.conversationId)) {
      this.conversationRooms.set(payload.conversationId, new Set());
    }

    this.conversationRooms.get(payload.conversationId)!.add(client);

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

    this.broadcastToConversation(payload.conversationId, {
      event: 'message_created',
      data: message,
    });

    return {
      event: 'message_accepted',
      data: { accepted: true },
    };
  }

  private broadcastToConversation(
    conversationId: string,
    payload: Record<string, unknown>,
  ): void {
    const clients = this.conversationRooms.get(conversationId);
    if (!clients) {
      return;
    }

    const encoded = JSON.stringify(payload);
    for (const client of clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(encoded);
      }
    }
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
