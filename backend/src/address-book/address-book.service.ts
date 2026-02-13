import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateEntryDto {
  targetDeviceId: string;
  alias?: string;
  notes?: string;
}

interface UpdateEntryDto {
  alias?: string;
  notes?: string;
  isFavorite?: boolean;
}

@Injectable()
export class AddressBookService {
  constructor(private prisma: PrismaService) {}

  async addEntry(userId: string, dto: CreateEntryDto) {
    // Check if device exists
    const device = await this.prisma.device.findUnique({
      where: { id: dto.targetDeviceId },
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    // Check if already in address book
    const existing = await this.prisma.addressBookEntry.findUnique({
      where: {
        userId_targetDeviceId: {
          userId,
          targetDeviceId: dto.targetDeviceId,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Device is already in your address book');
    }

    return this.prisma.addressBookEntry.create({
      data: {
        userId,
        targetDeviceId: dto.targetDeviceId,
        alias: dto.alias,
        notes: dto.notes,
      },
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
            user: {
              select: {
                email: true,
              },
            },
          },
        },
      },
    });
  }

  async getAll(userId: string) {
    return this.prisma.addressBookEntry.findMany({
      where: { userId },
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
            osVersion: true,
            user: {
              select: {
                email: true,
              },
            },
          },
        },
      },
      orderBy: [
        { isFavorite: 'desc' },
        { connectCount: 'desc' },
        { alias: 'asc' },
      ],
    });
  }

  async getFavorites(userId: string) {
    return this.prisma.addressBookEntry.findMany({
      where: { userId, isFavorite: true },
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
          },
        },
      },
      orderBy: { connectCount: 'desc' },
    });
  }

  async getRecent(userId: string, limit = 10) {
    return this.prisma.addressBookEntry.findMany({
      where: {
        userId,
        lastConnected: { not: null },
      },
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
          },
        },
      },
      orderBy: { lastConnected: 'desc' },
      take: limit,
    });
  }

  async updateEntry(userId: string, entryId: string, dto: UpdateEntryDto) {
    const entry = await this.prisma.addressBookEntry.findUnique({
      where: { id: entryId },
    });

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Entry not found');
    }

    return this.prisma.addressBookEntry.update({
      where: { id: entryId },
      data: dto,
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
          },
        },
      },
    });
  }

  async deleteEntry(userId: string, entryId: string) {
    const entry = await this.prisma.addressBookEntry.findUnique({
      where: { id: entryId },
    });

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Entry not found');
    }

    await this.prisma.addressBookEntry.delete({
      where: { id: entryId },
    });

    return { success: true };
  }

  async toggleFavorite(userId: string, entryId: string) {
    const entry = await this.prisma.addressBookEntry.findUnique({
      where: { id: entryId },
    });

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Entry not found');
    }

    return this.prisma.addressBookEntry.update({
      where: { id: entryId },
      data: { isFavorite: !entry.isFavorite },
    });
  }

  async recordConnection(userId: string, targetDeviceId: string) {
    const entry = await this.prisma.addressBookEntry.findUnique({
      where: {
        userId_targetDeviceId: { userId, targetDeviceId },
      },
    });

    if (entry) {
      await this.prisma.addressBookEntry.update({
        where: { id: entry.id },
        data: {
          lastConnected: new Date(),
          connectCount: { increment: 1 },
        },
      });
    }
  }

  async search(userId: string, query: string) {
    return this.prisma.addressBookEntry.findMany({
      where: {
        userId,
        OR: [
          { alias: { contains: query, mode: 'insensitive' } },
          { notes: { contains: query, mode: 'insensitive' } },
          { targetDevice: { deviceName: { contains: query, mode: 'insensitive' } } },
        ],
      },
      include: {
        targetDevice: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
            lastActive: true,
          },
        },
      },
      take: 20,
    });
  }
}
