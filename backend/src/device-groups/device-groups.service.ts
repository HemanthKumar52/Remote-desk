import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface CreateGroupDto {
  name: string;
  color?: string;
  icon?: string;
  parentId?: string;
}

interface UpdateGroupDto {
  name?: string;
  color?: string;
  icon?: string;
  parentId?: string;
}

@Injectable()
export class DeviceGroupsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateGroupDto) {
    // Check if group with same name exists
    const existing = await this.prisma.deviceGroup.findUnique({
      where: { userId_name: { userId, name: dto.name } },
    });

    if (existing) {
      throw new ConflictException('Group with this name already exists');
    }

    // Verify parent exists and belongs to user
    if (dto.parentId) {
      const parent = await this.prisma.deviceGroup.findUnique({
        where: { id: dto.parentId },
      });
      if (!parent || parent.userId !== userId) {
        throw new NotFoundException('Parent group not found');
      }
    }

    return this.prisma.deviceGroup.create({
      data: {
        userId,
        name: dto.name,
        color: dto.color,
        icon: dto.icon,
        parentId: dto.parentId,
      },
      include: {
        members: {
          include: {
            device: {
              select: {
                id: true,
                deviceName: true,
                platform: true,
                isOnline: true,
              },
            },
          },
        },
        children: true,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.deviceGroup.findMany({
      where: { userId },
      include: {
        members: {
          include: {
            device: {
              select: {
                id: true,
                deviceName: true,
                platform: true,
                isOnline: true,
                lastActive: true,
              },
            },
          },
        },
        children: {
          include: {
            members: {
              include: {
                device: {
                  select: {
                    id: true,
                    deviceName: true,
                    platform: true,
                    isOnline: true,
                  },
                },
              },
            },
          },
        },
        _count: {
          select: { members: true },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async findById(userId: string, groupId: string) {
    const group = await this.prisma.deviceGroup.findUnique({
      where: { id: groupId },
      include: {
        members: {
          include: {
            device: {
              select: {
                id: true,
                deviceName: true,
                platform: true,
                isOnline: true,
                lastActive: true,
                osVersion: true,
              },
            },
          },
        },
        children: true,
        parent: true,
      },
    });

    if (!group || group.userId !== userId) {
      throw new NotFoundException('Group not found');
    }

    return group;
  }

  async update(userId: string, groupId: string, dto: UpdateGroupDto) {
    const group = await this.prisma.deviceGroup.findUnique({
      where: { id: groupId },
    });

    if (!group || group.userId !== userId) {
      throw new NotFoundException('Group not found');
    }

    // Check name uniqueness if changing name
    if (dto.name && dto.name !== group.name) {
      const existing = await this.prisma.deviceGroup.findUnique({
        where: { userId_name: { userId, name: dto.name } },
      });
      if (existing) {
        throw new ConflictException('Group with this name already exists');
      }
    }

    // Verify parent if changing
    if (dto.parentId && dto.parentId !== group.parentId) {
      if (dto.parentId === groupId) {
        throw new ConflictException('Cannot set group as its own parent');
      }
      const parent = await this.prisma.deviceGroup.findUnique({
        where: { id: dto.parentId },
      });
      if (!parent || parent.userId !== userId) {
        throw new NotFoundException('Parent group not found');
      }
    }

    return this.prisma.deviceGroup.update({
      where: { id: groupId },
      data: dto,
      include: {
        members: {
          include: {
            device: {
              select: {
                id: true,
                deviceName: true,
                platform: true,
                isOnline: true,
              },
            },
          },
        },
      },
    });
  }

  async delete(userId: string, groupId: string) {
    const group = await this.prisma.deviceGroup.findUnique({
      where: { id: groupId },
    });

    if (!group || group.userId !== userId) {
      throw new NotFoundException('Group not found');
    }

    await this.prisma.deviceGroup.delete({
      where: { id: groupId },
    });

    return { success: true };
  }

  async addDevice(userId: string, groupId: string, deviceId: string) {
    const group = await this.prisma.deviceGroup.findUnique({
      where: { id: groupId },
    });

    if (!group || group.userId !== userId) {
      throw new NotFoundException('Group not found');
    }

    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device || device.userId !== userId) {
      throw new NotFoundException('Device not found');
    }

    // Check if already in group
    const existing = await this.prisma.deviceGroupMember.findUnique({
      where: { groupId_deviceId: { groupId, deviceId } },
    });

    if (existing) {
      throw new ConflictException('Device is already in this group');
    }

    return this.prisma.deviceGroupMember.create({
      data: { groupId, deviceId },
      include: {
        device: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
            isOnline: true,
          },
        },
      },
    });
  }

  async removeDevice(userId: string, groupId: string, deviceId: string) {
    const group = await this.prisma.deviceGroup.findUnique({
      where: { id: groupId },
    });

    if (!group || group.userId !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    const member = await this.prisma.deviceGroupMember.findUnique({
      where: { groupId_deviceId: { groupId, deviceId } },
    });

    if (!member) {
      throw new NotFoundException('Device not in group');
    }

    await this.prisma.deviceGroupMember.delete({
      where: { groupId_deviceId: { groupId, deviceId } },
    });

    return { success: true };
  }
}
