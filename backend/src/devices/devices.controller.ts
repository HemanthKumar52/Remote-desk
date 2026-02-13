import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Controller('devices')
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(private devicesService: DevicesService) {}

  @Post('register')
  async register(
    @CurrentUser('id') userId: string,
    @Body() dto: RegisterDeviceDto,
  ) {
    return this.devicesService.register(userId, dto);
  }

  @Get()
  async findAll(@CurrentUser('id') userId: string) {
    return this.devicesService.findAllByUser(userId);
  }

  @Delete(':id')
  async delete(
    @CurrentUser('id') userId: string,
    @Param('id') deviceId: string,
  ) {
    await this.devicesService.delete(userId, deviceId);
    return { message: 'Device deleted successfully' };
  }
}
