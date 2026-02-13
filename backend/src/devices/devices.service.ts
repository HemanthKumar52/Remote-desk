import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { Device } from '@prisma/client';

@Injectable()
export class DevicesService {
  constructor(private prisma: PrismaService) {}

  async register(userId: string, dto: RegisterDeviceDto): Promise<Device> {
    // Check if device already exists
    const existingDevice = await this.prisma.device.findUnique({
      where: { deviceUniqueId: dto.deviceUniqueId },
    });

    if (existingDevice) {
      // Update existing device
      return this.prisma.device.update({
        where: { id: existingDevice.id },
        data: {
          userId,
          deviceName: dto.deviceName,
          platform: dto.platform,
          lastActive: new Date(),
        },
      });
    }

    // Create new device
    return this.prisma.device.create({
      data: {
        userId,
        deviceName: dto.deviceName,
        platform: dto.platform,
        deviceUniqueId: dto.deviceUniqueId,
      },
    });
  }

  async findAllByUser(userId: string): Promise<Device[]> {
    return this.prisma.device.findMany({
      where: { userId },
      orderBy: { lastActive: 'desc' },
    });
  }

  async findById(id: string): Promise<Device | null> {
    return this.prisma.device.findUnique({
      where: { id },
    });
  }

  async findByUniqueId(deviceUniqueId: string): Promise<Device | null> {
    return this.prisma.device.findUnique({
      where: { deviceUniqueId },
    });
  }

  async updateLastActive(id: string): Promise<Device> {
    return this.prisma.device.update({
      where: { id },
      data: { lastActive: new Date() },
    });
  }

  async delete(userId: string, deviceId: string): Promise<void> {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    if (device.userId !== userId) {
      throw new ForbiddenException('You can only delete your own devices');
    }

    await this.prisma.device.delete({
      where: { id: deviceId },
    });
  }
}
