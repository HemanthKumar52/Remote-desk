import { Module } from '@nestjs/common';
import { SystemToolsService } from './system-tools.service';
import { SystemToolsController } from './system-tools.controller';
import { SystemToolsGateway } from './system-tools.gateway';
import { AuditLogModule } from '../audit-log/audit-log.module';

@Module({
  imports: [AuditLogModule],
  controllers: [SystemToolsController],
  providers: [SystemToolsService, SystemToolsGateway],
  exports: [SystemToolsService],
})
export class SystemToolsModule {}
