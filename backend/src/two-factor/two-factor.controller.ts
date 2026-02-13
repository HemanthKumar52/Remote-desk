import { Controller, Post, Body, UseGuards, Get } from '@nestjs/common';
import { TwoFactorService } from './two-factor.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('2fa')
@UseGuards(JwtAuthGuard)
export class TwoFactorController {
  constructor(private twoFactorService: TwoFactorService) {}

  @Get('status')
  async getStatus(@CurrentUser('id') userId: string) {
    const enabled = await this.twoFactorService.isEnabled(userId);
    return { enabled };
  }

  @Post('setup')
  async setup(@CurrentUser('id') userId: string) {
    return this.twoFactorService.setup(userId);
  }

  @Post('enable')
  async enable(
    @CurrentUser('id') userId: string,
    @Body('code') code: string,
  ) {
    return this.twoFactorService.enable(userId, code);
  }

  @Post('disable')
  async disable(
    @CurrentUser('id') userId: string,
    @Body('code') code: string,
  ) {
    return this.twoFactorService.disable(userId, code);
  }

  @Post('verify')
  async verify(
    @CurrentUser('id') userId: string,
    @Body('code') code: string,
  ) {
    const valid = await this.twoFactorService.verify(userId, code);
    return { valid };
  }
}
