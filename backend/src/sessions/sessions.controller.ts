import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { SessionsService } from './sessions.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';

@Controller('sessions')
@UseGuards(JwtAuthGuard)
export class SessionsController {
  constructor(private sessionsService: SessionsService) {}

  @Post()
  async create(@Body() dto: CreateSessionDto) {
    return this.sessionsService.create(dto.hostDeviceId, dto.clientDeviceId);
  }

  @Get('active')
  async getActiveSessions(@CurrentUser('id') userId: string) {
    return this.sessionsService.findActiveSessionsForUser(userId);
  }

  @Get('history')
  async getHistory(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.sessionsService.getSessionHistory(userId, limit);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.sessionsService.findByIdWithDevices(id);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateSessionDto) {
    return this.sessionsService.updateStatus(id, dto.status);
  }

  @Delete(':id')
  async end(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.sessionsService.endSession(id, userId);
  }
}
