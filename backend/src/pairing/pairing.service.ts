import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { SessionsService } from '../sessions/sessions.service';

@Injectable()
export class PairingService {
  constructor(
    private prisma: PrismaService,
    private devicesService: DevicesService,
    private sessionsService: SessionsService,
  ) {}

  async generateCode(userId: string, deviceId: string) {
    // Verify device belongs to user
    const device = await this.devicesService.findById(deviceId);
    if (!device) {
      throw new NotFoundException('Device not found');
    }
    if (device.userId !== userId) {
      throw new ForbiddenException('Device does not belong to user');
    }

    // Invalidate any existing codes for this device
    await this.prisma.pairCode.updateMany({
      where: {
        deviceId,
        used: false,
        expiresAt: { gt: new Date() },
      },
      data: { used: true },
    });

    // Generate 6-digit code
    const code = this.generateSixDigitCode();

    // Set expiry to 5 minutes from now
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    const pairCode = await this.prisma.pairCode.create({
      data: {
        code,
        deviceId,
        expiresAt,
      },
    });

    return {
      code: pairCode.code,
      expiresAt: pairCode.expiresAt,
      deviceId: pairCode.deviceId,
    };
  }

  async connect(userId: string, code: string, clientDeviceId: string) {
    // Find the pair code
    const pairCode = await this.prisma.pairCode.findUnique({
      where: { code },
      include: { device: true },
    });

    if (!pairCode) {
      throw new NotFoundException('Invalid pairing code');
    }

    if (pairCode.used) {
      throw new BadRequestException('Pairing code has already been used');
    }

    if (pairCode.expiresAt < new Date()) {
      throw new BadRequestException('Pairing code has expired');
    }

    // Verify client device belongs to user
    const clientDevice = await this.devicesService.findById(clientDeviceId);
    if (!clientDevice) {
      throw new NotFoundException('Client device not found');
    }
    if (clientDevice.userId !== userId) {
      throw new ForbiddenException('Client device does not belong to user');
    }

    // Cannot connect to own device
    if (pairCode.deviceId === clientDeviceId) {
      throw new BadRequestException('Cannot connect to the same device');
    }

    // Mark code as used
    await this.prisma.pairCode.update({
      where: { id: pairCode.id },
      data: { used: true },
    });

    // Create a session
    const session = await this.sessionsService.create(pairCode.deviceId, clientDeviceId);

    return {
      sessionId: session.id,
      hostDevice: {
        id: pairCode.device.id,
        deviceName: pairCode.device.deviceName,
        platform: pairCode.device.platform,
      },
    };
  }

  private generateSixDigitCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async cleanupExpiredCodes(): Promise<number> {
    const result = await this.prisma.pairCode.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } },
          { used: true },
        ],
      },
    });
    return result.count;
  }
}
