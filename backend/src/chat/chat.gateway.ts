import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  constructor(private chatService: ChatService) {}

  @SubscribeMessage('send-message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      content: string;
      messageType?: string;
    },
  ) {
    const message = await this.chatService.createMessage({
      sessionId: payload.sessionId,
      senderDeviceId: payload.deviceId,
      content: payload.content,
      messageType: payload.messageType,
    });

    // Broadcast to all clients in the session room
    this.server.to(payload.sessionId).emit('new-message', message);

    return { success: true, message };
  }

  @SubscribeMessage('get-messages')
  async handleGetMessages(
    @MessageBody() payload: {
      sessionId: string;
      limit?: number;
      before?: string;
    },
  ) {
    const messages = await this.chatService.getSessionMessages(
      payload.sessionId,
      payload.limit,
      payload.before ? new Date(payload.before) : undefined,
    );

    return { success: true, messages };
  }

  @SubscribeMessage('mark-read')
  async handleMarkRead(
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
    },
  ) {
    await this.chatService.markAsRead(payload.sessionId, payload.deviceId);

    // Notify others that messages were read
    this.server.to(payload.sessionId).emit('messages-read', {
      deviceId: payload.deviceId,
    });

    return { success: true };
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      isTyping: boolean;
    },
  ) {
    client.to(payload.sessionId).emit('user-typing', {
      deviceId: payload.deviceId,
      isTyping: payload.isTyping,
    });
  }

  @SubscribeMessage('join-chat')
  handleJoinChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.join(payload.sessionId);
    return { success: true };
  }

  @SubscribeMessage('leave-chat')
  handleLeaveChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.leave(payload.sessionId);
    return { success: true };
  }
}
