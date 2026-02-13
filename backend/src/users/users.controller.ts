import { Controller, Get, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  async getProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }
}
