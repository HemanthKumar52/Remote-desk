import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AnnotationsService, AnnotationType } from './annotations.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/annotations',
})
export class AnnotationsGateway {
  @WebSocketServer()
  server: Server;

  constructor(private annotationsService: AnnotationsService) {}

  @SubscribeMessage('create-annotation')
  async handleCreateAnnotation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      type: AnnotationType | string;
      color?: string;
      strokeWidth?: number;
      points: { x: number; y: number }[];
      text?: string;
    },
  ) {
    const annotation = await this.annotationsService.create({
      sessionId: payload.sessionId,
      creatorDeviceId: payload.deviceId,
      type: payload.type,
      color: payload.color,
      strokeWidth: payload.strokeWidth,
      points: payload.points,
      text: payload.text,
    });

    // Broadcast to all clients in the session
    this.server.to(payload.sessionId).emit('annotation-created', {
      ...annotation,
      points: payload.points,
    });

    return { success: true, annotation };
  }

  @SubscribeMessage('update-annotation')
  async handleUpdateAnnotation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      annotationId: string;
      points?: { x: number; y: number }[];
      text?: string;
      color?: string;
      strokeWidth?: number;
    },
  ) {
    const annotation = await this.annotationsService.update(payload.annotationId, {
      points: payload.points,
      text: payload.text,
      color: payload.color,
      strokeWidth: payload.strokeWidth,
    });

    // Broadcast update to all clients
    this.server.to(payload.sessionId).emit('annotation-updated', {
      ...annotation,
      points: payload.points || JSON.parse(annotation.points),
    });

    return { success: true };
  }

  @SubscribeMessage('delete-annotation')
  async handleDeleteAnnotation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      annotationId: string;
    },
  ) {
    await this.annotationsService.delete(payload.annotationId);

    // Broadcast deletion
    this.server.to(payload.sessionId).emit('annotation-deleted', {
      annotationId: payload.annotationId,
    });

    return { success: true };
  }

  @SubscribeMessage('clear-annotations')
  async handleClearAnnotations(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId?: string; // If provided, only clear this device's annotations
    },
  ) {
    await this.annotationsService.clearSessionAnnotations(
      payload.sessionId,
      payload.deviceId,
    );

    // Broadcast clear event
    this.server.to(payload.sessionId).emit('annotations-cleared', {
      deviceId: payload.deviceId,
    });

    return { success: true };
  }

  @SubscribeMessage('get-annotations')
  async handleGetAnnotations(
    @MessageBody() payload: { sessionId: string },
  ) {
    const annotations = await this.annotationsService.getSessionAnnotations(
      payload.sessionId,
    );
    return { success: true, annotations };
  }

  @SubscribeMessage('drawing-stroke')
  handleDrawingStroke(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      point: { x: number; y: number };
      annotationId?: string;
      color?: string;
      strokeWidth?: number;
    },
  ) {
    // Real-time stroke broadcasting (without saving to DB)
    client.to(payload.sessionId).emit('drawing-stroke', {
      deviceId: payload.deviceId,
      point: payload.point,
      annotationId: payload.annotationId,
      color: payload.color,
      strokeWidth: payload.strokeWidth,
    });
  }

  @SubscribeMessage('pointer-move')
  handlePointerMove(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      position: { x: number; y: number };
      isVisible: boolean;
    },
  ) {
    // Broadcast pointer position for collaborative cursors
    client.to(payload.sessionId).emit('pointer-update', {
      deviceId: payload.deviceId,
      position: payload.position,
      isVisible: payload.isVisible,
    });
  }

  @SubscribeMessage('join-annotations')
  handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.join(payload.sessionId);
    return { success: true };
  }

  @SubscribeMessage('leave-annotations')
  handleLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.leave(payload.sessionId);
    return { success: true };
  }
}
