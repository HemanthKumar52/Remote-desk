import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { PairingService } from './pairing.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';
import { GenerateCodeDto } from './dto/generate-code.dto';
import { ConnectDto } from './dto/connect.dto';

@Controller('pairing')
@UseGuards(JwtAuthGuard)
export class PairingController {
  constructor(private pairingService: PairingService) {}

  @Post('generate')
  async generateCode(
    @CurrentUser('id') userId: string,
    @Body() dto: GenerateCodeDto,
  ) {
    return this.pairingService.generateCode(userId, dto.deviceId);
  }

  @Post('connect')
  async connect(
    @CurrentUser('id') userId: string,
    @Body() dto: ConnectDto,
  ) {
    return this.pairingService.connect(userId, dto.code, dto.clientDeviceId);
  }
}
