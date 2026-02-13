import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateMessageDto {
  sessionId: string;
  senderDeviceId: string;
  content: string;
  messageType?: string;
}

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async createMessage(dto: CreateMessageDto) {
    return this.prisma.chatMessage.create({
      data: {
        sessionId: dto.sessionId,
        senderDeviceId: dto.senderDeviceId,
        content: dto.content,
        messageType: dto.messageType || 'text',
      },
    });
  }

  async getSessionMessages(sessionId: string, limit = 100, before?: Date) {
    const where: Record<string, unknown> = { sessionId };

    if (before) {
      where.createdAt = { lt: before };
    }

    return this.prisma.chatMessage.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async markAsRead(sessionId: string, deviceId: string) {
    await this.prisma.chatMessage.updateMany({
      where: {
        sessionId,
        senderDeviceId: { not: deviceId },
        isRead: false,
      },
      data: { isRead: true },
    });
  }

  async getUnreadCount(sessionId: string, deviceId: string) {
    return this.prisma.chatMessage.count({
      where: {
        sessionId,
        senderDeviceId: { not: deviceId },
        isRead: false,
      },
    });
  }

  async createSystemMessage(sessionId: string, content: string) {
    return this.prisma.chatMessage.create({
      data: {
        sessionId,
        senderDeviceId: 'system',
        content,
        messageType: 'system',
      },
    });
  }
}
