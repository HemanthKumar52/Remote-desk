import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService, AuditAction } from '../audit-log/audit-log.service';
import * as dgram from 'dgram';

@Injectable()
export class SystemToolsService {
  constructor(
    private prisma: PrismaService,
    private auditLogService: AuditLogService,
  ) {}

  // Wake-on-LAN implementation
  async wakeOnLan(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    if (device.userId !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    if (!device.macAddress) {
      throw new ForbiddenException('Device MAC address not configured');
    }

    // Create WOL request record
    const wolRequest = await this.prisma.wakeOnLanRequest.create({
      data: {
        targetMac: device.macAddress,
        targetIp: device.localIp,
        requestedBy: userId,
        status: 'pending',
      },
    });

    try {
      await this.sendMagicPacket(device.macAddress);

      await this.prisma.wakeOnLanRequest.update({
        where: { id: wolRequest.id },
        data: { status: 'sent' },
      });

      // Log the action
      await this.auditLogService.log({
        userId,
        deviceId,
        action: AuditAction.WOL_REQUEST,
        details: { macAddress: device.macAddress },
      });

      return { success: true, message: 'Wake-on-LAN packet sent' };
    } catch (error) {
      await this.prisma.wakeOnLanRequest.update({
        where: { id: wolRequest.id },
        data: { status: 'failed' },
      });

      throw error;
    }
  }

  private sendMagicPacket(macAddress: string): Promise<void> {
    return new Promise((resolve, reject) => {
      // Create magic packet
      const mac = macAddress.replace(/[:-]/g, '');
      const macBuffer = Buffer.from(mac, 'hex');

      // Magic packet: 6 bytes of 0xFF followed by MAC address repeated 16 times
      const magicPacket = Buffer.alloc(102);
      magicPacket.fill(0xff, 0, 6);
      for (let i = 0; i < 16; i++) {
        macBuffer.copy(magicPacket, 6 + i * 6);
      }

      const socket = dgram.createSocket('udp4');

      socket.on('error', (err) => {
        socket.close();
        reject(err);
      });

      socket.bind(() => {
        socket.setBroadcast(true);

        // Send to broadcast address on port 9 (WOL port)
        socket.send(magicPacket, 0, magicPacket.length, 9, '255.255.255.255', (err) => {
          socket.close();
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      });
    });
  }

  // Update device system info
  async updateDeviceSystemInfo(
    deviceId: string,
    info: {
      osVersion?: string;
      cpuInfo?: string;
      ramTotal?: number;
      macAddress?: string;
      localIp?: string;
    },
  ) {
    return this.prisma.device.update({
      where: { id: deviceId },
      data: info,
    });
  }

  // Get device system info
  async getDeviceSystemInfo(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
      select: {
        id: true,
        deviceName: true,
        platform: true,
        osVersion: true,
        cpuInfo: true,
        ramTotal: true,
        macAddress: true,
        localIp: true,
        isOnline: true,
        lastActive: true,
        userId: true,
      },
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    if (device.userId !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    return device;
  }

  // Configure unattended access
  async configureUnattendedAccess(
    userId: string,
    deviceId: string,
    password: string | null,
  ) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Device not found');
    }

    if (device.userId !== userId) {
      throw new ForbiddenException('Not authorized');
    }

    const bcrypt = await import('bcrypt');
    const hashedPassword = password ? await bcrypt.hash(password, 10) : null;

    await this.prisma.device.update({
      where: { id: deviceId },
      data: {
        unattendedEnabled: !!password,
        unattendedPassword: hashedPassword,
      },
    });

    await this.auditLogService.log({
      userId,
      deviceId,
      action: password ? AuditAction.UNATTENDED_ENABLED : AuditAction.UNATTENDED_DISABLED,
    });

    return { success: true, unattendedEnabled: !!password };
  }

  // Verify unattended access password
  async verifyUnattendedPassword(deviceId: string, password: string): Promise<boolean> {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device || !device.unattendedEnabled || !device.unattendedPassword) {
      return false;
    }

    const bcrypt = await import('bcrypt');
    return bcrypt.compare(password, device.unattendedPassword);
  }

  // Get WOL history
  async getWolHistory(userId: string, limit = 20) {
    return this.prisma.wakeOnLanRequest.findMany({
      where: { requestedBy: userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
