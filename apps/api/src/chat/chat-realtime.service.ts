import { Injectable } from '@nestjs/common';
import { Server, WebSocket } from 'ws';

@Injectable()
export class ChatRealtimeService {
  private readonly conversationRooms = new Map<string, Set<WebSocket>>();

  joinConversation(conversationId: string, client: WebSocket): void {
    if (!this.conversationRooms.has(conversationId)) {
      this.conversationRooms.set(conversationId, new Set());
    }

    this.conversationRooms.get(conversationId)!.add(client);
  }

  removeClient(client: WebSocket): void {
    for (const clients of this.conversationRooms.values()) {
      clients.delete(client);
    }
  }

  broadcastToConversation(
    conversationId: string,
    payload: Record<string, unknown>,
  ): void {
    const clients = this.conversationRooms.get(conversationId);
    if (!clients?.size) {
      return;
    }

    const encoded = JSON.stringify(payload);
    for (const client of clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(encoded);
      }
    }
  }
}
