import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { SessionsService } from '../sessions/sessions.service';

interface JoinSessionPayload {
  sessionId: string;
  deviceId: string;
  role: 'host' | 'client';
}

interface SignalingPayload {
  sessionId: string;
  data: unknown;
}

interface IceCandidatePayload {
  sessionId: string;
  candidate: RTCIceCandidateInit;
}

interface InputEventPayload {
  sessionId: string;
  event: {
    type: 'mouse' | 'keyboard';
    action: string;
    data: unknown;
  };
}

interface FileTransferPayload {
  sessionId: string;
  fileName: string;
  fileSize: number;
  chunkIndex: number;
  totalChunks: number;
  data: string; // base64 encoded chunk
}

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/signaling',
})
export class SignalingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedClients: Map<string, { socketId: string; deviceId: string; userId: string }> = new Map();
  private sessionRooms: Map<string, Set<string>> = new Map();

  constructor(
    private jwtService: JwtService,
    private sessionsService: SessionsService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        client.emit('error', { message: 'Authentication required' });
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.sub;
      const deviceId = client.handshake.query.deviceId as string;

      if (!deviceId) {
        client.emit('error', { message: 'Device ID required' });
        client.disconnect();
        return;
      }

      this.connectedClients.set(client.id, { socketId: client.id, deviceId, userId });
      console.log(`Client connected: ${client.id} (Device: ${deviceId})`);

      client.emit('connected', { message: 'Connected to signaling server' });
    } catch {
      client.emit('error', { message: 'Invalid token' });
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const clientInfo = this.connectedClients.get(client.id);
    if (clientInfo) {
      console.log(`Client disconnected: ${client.id} (Device: ${clientInfo.deviceId})`);

      // Notify session rooms about disconnection
      this.sessionRooms.forEach((clients, sessionId) => {
        if (clients.has(client.id)) {
          clients.delete(client.id);
          this.server.to(sessionId).emit('peer-disconnected', {
            deviceId: clientInfo.deviceId,
          });
        }
      });

      this.connectedClients.delete(client.id);
    }
  }

  @SubscribeMessage('join-session')
  async handleJoinSession(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: JoinSessionPayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    const { sessionId, deviceId, role } = payload;

    // Verify session exists and is valid
    const session = await this.sessionsService.findByIdWithDevices(sessionId);
    if (!session) {
      return { success: false, error: 'Session not found' };
    }

    if (session.status === 'ended') {
      return { success: false, error: 'Session has ended' };
    }

    // Join the session room
    client.join(sessionId);

    if (!this.sessionRooms.has(sessionId)) {
      this.sessionRooms.set(sessionId, new Set());
    }
    this.sessionRooms.get(sessionId)!.add(client.id);

    // Notify other participants
    client.to(sessionId).emit('peer-joined', {
      deviceId,
      role,
      socketId: client.id,
    });

    console.log(`Device ${deviceId} joined session ${sessionId} as ${role}`);

    return { success: true, sessionId };
  }

  @SubscribeMessage('leave-session')
  handleLeaveSession(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    const { sessionId } = payload;

    client.leave(sessionId);
    this.sessionRooms.get(sessionId)?.delete(client.id);

    client.to(sessionId).emit('peer-left', {
      deviceId: clientInfo.deviceId,
    });

    console.log(`Device ${clientInfo.deviceId} left session ${sessionId}`);

    return { success: true };
  }

  @SubscribeMessage('offer')
  handleOffer(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SignalingPayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('offer', {
      deviceId: clientInfo.deviceId,
      sdp: payload.data,
    });

    return { success: true };
  }

  @SubscribeMessage('answer')
  handleAnswer(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: SignalingPayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('answer', {
      deviceId: clientInfo.deviceId,
      sdp: payload.data,
    });

    return { success: true };
  }

  @SubscribeMessage('ice-candidate')
  handleIceCandidate(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: IceCandidatePayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('ice-candidate', {
      deviceId: clientInfo.deviceId,
      candidate: payload.candidate,
    });

    return { success: true };
  }

  @SubscribeMessage('input-event')
  handleInputEvent(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: InputEventPayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    // Forward input events to the host
    client.to(payload.sessionId).emit('input-event', {
      deviceId: clientInfo.deviceId,
      event: payload.event,
    });

    return { success: true };
  }

  @SubscribeMessage('file-transfer-request')
  handleFileTransferRequest(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string; fileName: string; fileSize: number },
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('file-transfer-request', {
      deviceId: clientInfo.deviceId,
      fileName: payload.fileName,
      fileSize: payload.fileSize,
    });

    return { success: true };
  }

  @SubscribeMessage('file-transfer-accept')
  handleFileTransferAccept(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string; fileName: string },
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('file-transfer-accept', {
      deviceId: clientInfo.deviceId,
      fileName: payload.fileName,
    });

    return { success: true };
  }

  @SubscribeMessage('file-chunk')
  handleFileChunk(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: FileTransferPayload,
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    client.to(payload.sessionId).emit('file-chunk', {
      deviceId: clientInfo.deviceId,
      fileName: payload.fileName,
      chunkIndex: payload.chunkIndex,
      totalChunks: payload.totalChunks,
      data: payload.data,
    });

    return { success: true };
  }

  @SubscribeMessage('session-ended')
  async handleSessionEnded(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    const clientInfo = this.connectedClients.get(client.id);
    if (!clientInfo) {
      return { success: false, error: 'Not authenticated' };
    }

    // Notify all participants
    this.server.to(payload.sessionId).emit('session-ended', {
      deviceId: clientInfo.deviceId,
    });

    // Clean up session room
    const room = this.sessionRooms.get(payload.sessionId);
    if (room) {
      room.forEach((socketId) => {
        const socket = this.server.sockets.sockets.get(socketId);
        socket?.leave(payload.sessionId);
      });
      this.sessionRooms.delete(payload.sessionId);
    }

    // Update session status
    try {
      await this.sessionsService.updateStatus(payload.sessionId, 'ended');
    } catch (error) {
      console.error('Failed to update session status:', error);
    }

    return { success: true };
  }
}
