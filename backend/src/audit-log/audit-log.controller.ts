import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuditLogService } from './audit-log.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('audit-logs')
@UseGuards(JwtAuthGuard)
export class AuditLogController {
  constructor(private auditLogService: AuditLogService) {}

  @Get()
  async getLogs(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
    @Query('action') action?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.auditLogService.getByUser(userId, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
      action,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    });
  }

  @Get('sessions')
  async getSessionHistory(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.auditLogService.getSessionHistory(userId, limit ? Number(limit) : undefined);
  }

  @Get('security')
  async getSecurityEvents(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.auditLogService.getSecurityEvents(userId, limit ? Number(limit) : undefined);
  }
}
