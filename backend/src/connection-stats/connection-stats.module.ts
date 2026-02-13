import { Module } from '@nestjs/common';
import { ConnectionStatsService } from './connection-stats.service';
import { ConnectionStatsGateway } from './connection-stats.gateway';

@Module({
  providers: [ConnectionStatsService, ConnectionStatsGateway],
  exports: [ConnectionStatsService],
})
export class ConnectionStatsModule {}
