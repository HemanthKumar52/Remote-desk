import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export enum AuditAction {
  // Auth
  LOGIN = 'login',
  LOGOUT = 'logout',
  REGISTER = 'register',
  PASSWORD_CHANGE = 'password_change',
  TWO_FACTOR_ENABLED = '2fa_enabled',
  TWO_FACTOR_DISABLED = '2fa_disabled',

  // Sessions
  SESSION_START = 'session_start',
  SESSION_END = 'session_end',
  SESSION_PAUSE = 'session_pause',
  SESSION_RESUME = 'session_resume',

  // File Transfer
  FILE_TRANSFER_START = 'file_transfer_start',
  FILE_TRANSFER_COMPLETE = 'file_transfer_complete',
  FILE_TRANSFER_FAILED = 'file_transfer_failed',

  // Remote Control
  REMOTE_RESTART = 'remote_restart',
  REMOTE_SHUTDOWN = 'remote_shutdown',
  PROCESS_KILL = 'process_kill',
  COMMAND_EXEC = 'command_exec',

  // Device
  DEVICE_REGISTER = 'device_register',
  DEVICE_DELETE = 'device_delete',
  UNATTENDED_ENABLED = 'unattended_enabled',
  UNATTENDED_DISABLED = 'unattended_disabled',

  // Wake-on-LAN
  WOL_REQUEST = 'wol_request',
  WOL_SUCCESS = 'wol_success',
  WOL_FAILED = 'wol_failed',

  // Recording
  RECORDING_START = 'recording_start',
  RECORDING_STOP = 'recording_stop',
  RECORDING_DELETE = 'recording_delete',
}

interface CreateAuditLogDto {
  userId: string;
  deviceId?: string;
  action: AuditAction | string;
  details?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  success?: boolean;
}

@Injectable()
export class AuditLogService {
  constructor(private prisma: PrismaService) {}

  async log(data: CreateAuditLogDto) {
    return this.prisma.auditLog.create({
      data: {
        userId: data.userId,
        deviceId: data.deviceId,
        action: data.action,
        details: data.details ? JSON.stringify(data.details) : null,
        ipAddress: data.ipAddress,
        userAgent: data.userAgent,
        success: data.success ?? true,
      },
    });
  }

  async getByUser(
    userId: string,
    options?: {
      limit?: number;
      offset?: number;
      action?: string;
      startDate?: Date;
      endDate?: Date;
    },
  ) {
    const { limit = 50, offset = 0, action, startDate, endDate } = options || {};

    const where: Record<string, unknown> = { userId };

    if (action) {
      where.action = action;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        (where.createdAt as Record<string, Date>).gte = startDate;
      }
      if (endDate) {
        (where.createdAt as Record<string, Date>).lte = endDate;
      }
    }

    const [logs, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        include: {
          device: {
            select: {
              id: true,
              deviceName: true,
              platform: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    return {
      logs: logs.map((log) => ({
        ...log,
        details: log.details ? JSON.parse(log.details) : null,
      })),
      total,
      limit,
      offset,
    };
  }

  async getByDevice(deviceId: string, limit = 50) {
    const logs = await this.prisma.auditLog.findMany({
      where: { deviceId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return logs.map((log) => ({
      ...log,
      details: log.details ? JSON.parse(log.details) : null,
    }));
  }

  async getSessionHistory(userId: string, limit = 20) {
    const logs = await this.prisma.auditLog.findMany({
      where: {
        userId,
        action: {
          in: [AuditAction.SESSION_START, AuditAction.SESSION_END],
        },
      },
      include: {
        device: {
          select: {
            id: true,
            deviceName: true,
            platform: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return logs.map((log) => ({
      ...log,
      details: log.details ? JSON.parse(log.details) : null,
    }));
  }

  async getSecurityEvents(userId: string, limit = 50) {
    const securityActions = [
      AuditAction.LOGIN,
      AuditAction.LOGOUT,
      AuditAction.PASSWORD_CHANGE,
      AuditAction.TWO_FACTOR_ENABLED,
      AuditAction.TWO_FACTOR_DISABLED,
      AuditAction.UNATTENDED_ENABLED,
      AuditAction.UNATTENDED_DISABLED,
    ];

    const logs = await this.prisma.auditLog.findMany({
      where: {
        userId,
        action: { in: securityActions },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    return logs.map((log) => ({
      ...log,
      details: log.details ? JSON.parse(log.details) : null,
    }));
  }

  async deleteOldLogs(daysToKeep = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    const result = await this.prisma.auditLog.deleteMany({
      where: {
        createdAt: { lt: cutoffDate },
      },
    });

    return { deleted: result.count };
  }
}
