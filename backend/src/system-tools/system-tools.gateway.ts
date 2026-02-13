import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AuditLogService, AuditAction } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/system-tools',
})
export class SystemToolsGateway {
  @WebSocketServer()
  server: Server;

  constructor(
    private auditLogService: AuditLogService,
    private prisma: PrismaService,
  ) {}

  // Request system info from remote device
  @SubscribeMessage('request-system-info')
  async handleRequestSystemInfo(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      targetDeviceId: string;
    },
  ) {
    // Forward request to target device
    this.server.to(payload.sessionId).emit('get-system-info', {
      requesterId: client.id,
    });

    return { success: true };
  }

  // Receive system info from device
  @SubscribeMessage('system-info-response')
  async handleSystemInfoResponse(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      deviceId: string;
      info: {
        osVersion: string;
        cpuInfo: string;
        ramTotal: number;
        ramUsed: number;
        diskTotal: number;
        diskUsed: number;
        uptime: number;
        processes: Array<{
          pid: number;
          name: string;
          cpu: number;
          memory: number;
        }>;
      };
    },
  ) {
    // Update device info in database
    await this.prisma.device.update({
      where: { id: payload.deviceId },
      data: {
        osVersion: payload.info.osVersion,
        cpuInfo: payload.info.cpuInfo,
        ramTotal: payload.info.ramTotal,
      },
    });

    // Forward to all clients in session
    this.server.to(payload.sessionId).emit('system-info', payload.info);

    return { success: true };
  }

  // Request remote restart
  @SubscribeMessage('request-restart')
  async handleRequestRestart(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      userId: string;
      targetDeviceId: string;
      delay?: number; // seconds
    },
  ) {
    // Check permissions
    const session = await this.prisma.session.findUnique({
      where: { id: payload.sessionId },
      include: { permissions: true },
    });

    if (!session?.permissions?.allowRestart) {
      return { success: false, error: 'Restart not permitted' };
    }

    // Log the action
    await this.auditLogService.log({
      userId: payload.userId,
      deviceId: payload.targetDeviceId,
      action: AuditAction.REMOTE_RESTART,
      details: { delay: payload.delay || 0 },
    });

    // Send restart command to target device
    this.server.to(payload.sessionId).emit('execute-restart', {
      delay: payload.delay || 0,
    });

    return { success: true };
  }

  // Request remote shutdown
  @SubscribeMessage('request-shutdown')
  async handleRequestShutdown(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      userId: string;
      targetDeviceId: string;
      delay?: number;
    },
  ) {
    const session = await this.prisma.session.findUnique({
      where: { id: payload.sessionId },
      include: { permissions: true },
    });

    if (!session?.permissions?.allowShutdown) {
      return { success: false, error: 'Shutdown not permitted' };
    }

    await this.auditLogService.log({
      userId: payload.userId,
      deviceId: payload.targetDeviceId,
      action: AuditAction.REMOTE_SHUTDOWN,
      details: { delay: payload.delay || 0 },
    });

    this.server.to(payload.sessionId).emit('execute-shutdown', {
      delay: payload.delay || 0,
    });

    return { success: true };
  }

  // Request process list
  @SubscribeMessage('request-processes')
  handleRequestProcesses(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    this.server.to(payload.sessionId).emit('get-processes', {
      requesterId: client.id,
    });

    return { success: true };
  }

  // Kill a process
  @SubscribeMessage('kill-process')
  async handleKillProcess(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      userId: string;
      targetDeviceId: string;
      pid: number;
      processName: string;
    },
  ) {
    const session = await this.prisma.session.findUnique({
      where: { id: payload.sessionId },
      include: { permissions: true },
    });

    if (!session?.permissions?.allowProcessKill) {
      return { success: false, error: 'Process termination not permitted' };
    }

    await this.auditLogService.log({
      userId: payload.userId,
      deviceId: payload.targetDeviceId,
      action: AuditAction.PROCESS_KILL,
      details: { pid: payload.pid, processName: payload.processName },
    });

    this.server.to(payload.sessionId).emit('execute-kill-process', {
      pid: payload.pid,
    });

    return { success: true };
  }

  // Execute remote command
  @SubscribeMessage('execute-command')
  async handleExecuteCommand(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      userId: string;
      targetDeviceId: string;
      command: string;
    },
  ) {
    const session = await this.prisma.session.findUnique({
      where: { id: payload.sessionId },
      include: { permissions: true },
    });

    if (!session?.permissions?.allowCommandExec) {
      return { success: false, error: 'Command execution not permitted' };
    }

    await this.auditLogService.log({
      userId: payload.userId,
      deviceId: payload.targetDeviceId,
      action: AuditAction.COMMAND_EXEC,
      details: { command: payload.command },
    });

    this.server.to(payload.sessionId).emit('execute-command', {
      command: payload.command,
      requesterId: client.id,
    });

    return { success: true };
  }

  // Command output response
  @SubscribeMessage('command-output')
  handleCommandOutput(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      output: string;
      exitCode: number;
      error?: string;
    },
  ) {
    this.server.to(payload.sessionId).emit('command-result', payload);
  }

  @SubscribeMessage('join-system-tools')
  handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.join(payload.sessionId);
    return { success: true };
  }
}
