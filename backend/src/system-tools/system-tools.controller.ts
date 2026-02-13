import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { SystemToolsService } from './system-tools.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('system-tools')
@UseGuards(JwtAuthGuard)
export class SystemToolsController {
  constructor(private systemToolsService: SystemToolsService) {}

  @Post('wake/:deviceId')
  async wakeOnLan(
    @CurrentUser('id') userId: string,
    @Param('deviceId') deviceId: string,
  ) {
    return this.systemToolsService.wakeOnLan(userId, deviceId);
  }

  @Get('device/:deviceId/info')
  async getDeviceInfo(
    @CurrentUser('id') userId: string,
    @Param('deviceId') deviceId: string,
  ) {
    return this.systemToolsService.getDeviceSystemInfo(userId, deviceId);
  }

  @Post('device/:deviceId/unattended')
  async configureUnattendedAccess(
    @CurrentUser('id') userId: string,
    @Param('deviceId') deviceId: string,
    @Body() dto: { password: string | null },
  ) {
    return this.systemToolsService.configureUnattendedAccess(
      userId,
      deviceId,
      dto.password,
    );
  }

  @Post('device/:deviceId/unattended/verify')
  async verifyUnattendedPassword(
    @Param('deviceId') deviceId: string,
    @Body() dto: { password: string },
  ) {
    const valid = await this.systemToolsService.verifyUnattendedPassword(
      deviceId,
      dto.password,
    );
    return { valid };
  }

  @Get('wol/history')
  async getWolHistory(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.systemToolsService.getWolHistory(
      userId,
      limit ? Number(limit) : undefined,
    );
  }
}
