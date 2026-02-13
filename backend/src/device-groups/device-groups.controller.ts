import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { DeviceGroupsService } from './device-groups.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('device-groups')
@UseGuards(JwtAuthGuard)
export class DeviceGroupsController {
  constructor(private deviceGroupsService: DeviceGroupsService) {}

  @Post()
  async create(
    @CurrentUser('id') userId: string,
    @Body() dto: { name: string; color?: string; icon?: string; parentId?: string },
  ) {
    return this.deviceGroupsService.create(userId, dto);
  }

  @Get()
  async findAll(@CurrentUser('id') userId: string) {
    return this.deviceGroupsService.findAll(userId);
  }

  @Get(':id')
  async findOne(
    @CurrentUser('id') userId: string,
    @Param('id') groupId: string,
  ) {
    return this.deviceGroupsService.findById(userId, groupId);
  }

  @Patch(':id')
  async update(
    @CurrentUser('id') userId: string,
    @Param('id') groupId: string,
    @Body() dto: { name?: string; color?: string; icon?: string; parentId?: string },
  ) {
    return this.deviceGroupsService.update(userId, groupId, dto);
  }

  @Delete(':id')
  async delete(
    @CurrentUser('id') userId: string,
    @Param('id') groupId: string,
  ) {
    return this.deviceGroupsService.delete(userId, groupId);
  }

  @Post(':id/devices/:deviceId')
  async addDevice(
    @CurrentUser('id') userId: string,
    @Param('id') groupId: string,
    @Param('deviceId') deviceId: string,
  ) {
    return this.deviceGroupsService.addDevice(userId, groupId, deviceId);
  }

  @Delete(':id/devices/:deviceId')
  async removeDevice(
    @CurrentUser('id') userId: string,
    @Param('id') groupId: string,
    @Param('deviceId') deviceId: string,
  ) {
    return this.deviceGroupsService.removeDevice(userId, groupId, deviceId);
  }
}
