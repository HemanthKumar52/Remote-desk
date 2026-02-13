import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ConnectionStatsService } from './connection-stats.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/stats',
})
export class ConnectionStatsGateway {
  @WebSocketServer()
  server: Server;

  constructor(private statsService: ConnectionStatsService) {}

  @SubscribeMessage('report-stats')
  async handleReportStats(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      latency: number;
      bandwidth: number;
      packetLoss: number;
      fps: number;
      resolution: string;
      cpuUsage: number;
      memoryUsage: number;
    },
  ) {
    // Record stats
    await this.statsService.recordStats(payload);

    // Calculate quality score
    const qualityScore = this.statsService.calculateQualityScore({
      latency: payload.latency,
      bandwidth: payload.bandwidth,
      packetLoss: payload.packetLoss,
      fps: payload.fps,
    });

    const qualityLabel = this.statsService.getQualityLabel(qualityScore);

    // Broadcast stats to session participants
    this.server.to(payload.sessionId).emit('stats-update', {
      ...payload,
      qualityScore,
      qualityLabel,
      timestamp: new Date().toISOString(),
    });

    return { success: true, qualityScore, qualityLabel };
  }

  @SubscribeMessage('get-session-stats')
  async handleGetSessionStats(
    @MessageBody() payload: { sessionId: string; limit?: number },
  ) {
    const stats = await this.statsService.getSessionStats(
      payload.sessionId,
      payload.limit,
    );
    return { success: true, stats };
  }

  @SubscribeMessage('request-quality-adjustment')
  async handleQualityAdjustment(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      preset?: string;
      auto?: boolean;
      currentStats?: {
        latency: number;
        bandwidth: number;
        packetLoss: number;
      };
    },
  ) {
    let targetPreset: string;

    if (payload.auto && payload.currentStats) {
      // Auto-determine quality
      const optimal = this.statsService.determineOptimalQuality(payload.currentStats);
      targetPreset = Object.entries(this.statsService.getQualityPresets())
        .find(([_, v]) => v.name === optimal.name)?.[0] || 'medium';
    } else {
      targetPreset = payload.preset || 'medium';
    }

    const updated = await this.statsService.updateSessionQuality(
      payload.sessionId,
      targetPreset,
    );

    if (updated) {
      // Notify all session participants
      this.server.to(payload.sessionId).emit('quality-changed', {
        preset: targetPreset,
        settings: this.statsService.getQualityPresets()[targetPreset],
      });
    }

    return { success: true, preset: targetPreset };
  }

  @SubscribeMessage('get-quality-presets')
  handleGetQualityPresets() {
    return {
      success: true,
      presets: this.statsService.getQualityPresets(),
    };
  }

  @SubscribeMessage('bandwidth-test')
  async handleBandwidthTest(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    // Initiate bandwidth test
    const testData = Buffer.alloc(1024 * 100); // 100KB test payload
    const startTime = Date.now();

    this.server.to(payload.sessionId).emit('bandwidth-test-start', {
      requesterId: client.id,
      testData: testData.toString('base64'),
      startTime,
    });

    return { success: true, startTime };
  }

  @SubscribeMessage('bandwidth-test-result')
  handleBandwidthTestResult(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: {
      sessionId: string;
      startTime: number;
      endTime: number;
      bytesTransferred: number;
    },
  ) {
    const duration = (payload.endTime - payload.startTime) / 1000; // seconds
    const bandwidth = Math.round((payload.bytesTransferred * 8) / duration / 1000); // kbps

    this.server.to(payload.sessionId).emit('bandwidth-test-complete', {
      bandwidth,
      duration,
    });

    return { success: true, bandwidth };
  }

  @SubscribeMessage('join-stats')
  handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { sessionId: string },
  ) {
    client.join(payload.sessionId);
    return { success: true };
  }
}
