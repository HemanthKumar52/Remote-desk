import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Session } from '@prisma/client';

@Injectable()
export class SessionsService {
  constructor(private prisma: PrismaService) {}

  async create(hostDeviceId: string, clientDeviceId?: string): Promise<Session> {
    return this.prisma.session.create({
      data: {
        hostDeviceId,
        clientDeviceId,
        status: clientDeviceId ? 'active' : 'pending',
      },
    });
  }

  async findById(id: string): Promise<Session | null> {
    return this.prisma.session.findUnique({
      where: { id },
      include: {
        hostDevice: true,
        clientDevice: true,
      },
    });
  }

  async findByIdWithDevices(id: string) {
    return this.prisma.session.findUnique({
      where: { id },
      include: {
        hostDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            userId: true,
          },
        },
        clientDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            userId: true,
          },
        },
      },
    });
  }

  async updateStatus(id: string, status: string): Promise<Session> {
    const updateData: { status: string; endedAt?: Date } = { status };

    if (status === 'ended') {
      updateData.endedAt = new Date();
    }

    return this.prisma.session.update({
      where: { id },
      data: updateData,
    });
  }

  async setClientDevice(sessionId: string, clientDeviceId: string): Promise<Session> {
    return this.prisma.session.update({
      where: { id: sessionId },
      data: {
        clientDeviceId,
        status: 'active',
      },
    });
  }

  async endSession(sessionId: string, userId: string): Promise<Session> {
    const session = await this.findByIdWithDevices(sessionId);

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    // Check if user owns either device in the session
    const isHost = session.hostDevice?.userId === userId;
    const isClient = session.clientDevice?.userId === userId;

    if (!isHost && !isClient) {
      throw new ForbiddenException('You do not have permission to end this session');
    }

    return this.updateStatus(sessionId, 'ended');
  }

  async findActiveSessionsForUser(userId: string) {
    return this.prisma.session.findMany({
      where: {
        status: 'active',
        OR: [
          { hostDevice: { userId } },
          { clientDevice: { userId } },
        ],
      },
      include: {
        hostDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
          },
        },
        clientDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
          },
        },
      },
      orderBy: { startedAt: 'desc' },
    });
  }

  async getSessionHistory(userId: string, limit = 10) {
    return this.prisma.session.findMany({
      where: {
        OR: [
          { hostDevice: { userId } },
          { clientDevice: { userId } },
        ],
      },
      include: {
        hostDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
          },
        },
        clientDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
          },
        },
      },
      orderBy: { startedAt: 'desc' },
      take: limit,
    });
  }
}
