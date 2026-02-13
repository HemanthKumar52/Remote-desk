import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface StatsData {
  sessionId: string;
  latency: number;
  bandwidth: number;
  packetLoss: number;
  fps: number;
  resolution: string;
  cpuUsage: number;
  memoryUsage: number;
}

export interface QualityPreset {
  name: string;
  maxFps: number;
  maxBitrate: number;
  resolution: string;
}

@Injectable()
export class ConnectionStatsService {
  private readonly qualityPresets: Record<string, QualityPreset> = {
    low: { name: 'Low', maxFps: 15, maxBitrate: 500, resolution: '854x480' },
    medium: { name: 'Medium', maxFps: 24, maxBitrate: 1500, resolution: '1280x720' },
    high: { name: 'High', maxFps: 30, maxBitrate: 3000, resolution: '1920x1080' },
    ultra: { name: 'Ultra', maxFps: 60, maxBitrate: 8000, resolution: '2560x1440' },
  };

  constructor(private prisma: PrismaService) {}

  async recordStats(data: StatsData) {
    return this.prisma.connectionStats.create({
      data: {
        sessionId: data.sessionId,
        latency: data.latency,
        bandwidth: data.bandwidth,
        packetLoss: data.packetLoss,
        fps: data.fps,
        resolution: data.resolution,
        cpuUsage: data.cpuUsage,
        memoryUsage: data.memoryUsage,
      },
    });
  }

  async getSessionStats(sessionId: string, limit = 100) {
    const stats = await this.prisma.connectionStats.findMany({
      where: { sessionId },
      orderBy: { timestamp: 'desc' },
      take: limit,
    });

    if (stats.length === 0) {
      return null;
    }

    // Calculate averages
    const avgLatency = stats.reduce((sum, s) => sum + s.latency, 0) / stats.length;
    const avgBandwidth = stats.reduce((sum, s) => sum + s.bandwidth, 0) / stats.length;
    const avgPacketLoss = stats.reduce((sum, s) => sum + s.packetLoss, 0) / stats.length;
    const avgFps = stats.reduce((sum, s) => sum + s.fps, 0) / stats.length;

    return {
      current: stats[0],
      averages: {
        latency: Math.round(avgLatency),
        bandwidth: Math.round(avgBandwidth),
        packetLoss: Number(avgPacketLoss.toFixed(2)),
        fps: Math.round(avgFps),
      },
      history: stats.reverse(),
    };
  }

  // Determine optimal quality based on current stats
  determineOptimalQuality(stats: {
    latency: number;
    bandwidth: number;
    packetLoss: number;
  }): QualityPreset {
    const { latency, bandwidth, packetLoss } = stats;

    // Poor connection
    if (latency > 200 || bandwidth < 500 || packetLoss > 5) {
      return this.qualityPresets.low;
    }

    // Moderate connection
    if (latency > 100 || bandwidth < 1500 || packetLoss > 2) {
      return this.qualityPresets.medium;
    }

    // Good connection
    if (latency > 50 || bandwidth < 5000 || packetLoss > 0.5) {
      return this.qualityPresets.high;
    }

    // Excellent connection
    return this.qualityPresets.ultra;
  }

  async updateSessionQuality(sessionId: string, preset: string) {
    const qualityPreset = this.qualityPresets[preset];
    if (!qualityPreset) {
      return null;
    }

    return this.prisma.session.update({
      where: { id: sessionId },
      data: {
        qualityPreset: preset,
        maxFps: qualityPreset.maxFps,
        maxBitrate: qualityPreset.maxBitrate,
      },
    });
  }

  getQualityPresets() {
    return this.qualityPresets;
  }

  // Calculate connection quality score (0-100)
  calculateQualityScore(stats: {
    latency: number;
    bandwidth: number;
    packetLoss: number;
    fps: number;
  }): number {
    let score = 100;

    // Latency impact (max -40 points)
    if (stats.latency > 20) {
      score -= Math.min(40, (stats.latency - 20) / 5);
    }

    // Bandwidth impact (max -30 points)
    if (stats.bandwidth < 5000) {
      score -= Math.min(30, (5000 - stats.bandwidth) / 150);
    }

    // Packet loss impact (max -20 points)
    score -= Math.min(20, stats.packetLoss * 4);

    // FPS impact (max -10 points)
    if (stats.fps < 30) {
      score -= Math.min(10, (30 - stats.fps) / 3);
    }

    return Math.max(0, Math.round(score));
  }

  // Get connection quality label
  getQualityLabel(score: number): string {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Critical';
  }

  // Cleanup old stats (keep last 24 hours)
  async cleanupOldStats() {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const result = await this.prisma.connectionStats.deleteMany({
      where: { timestamp: { lt: cutoff } },
    });

    return { deleted: result.count };
  }
}
