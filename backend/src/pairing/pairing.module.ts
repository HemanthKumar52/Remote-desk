import { Module } from '@nestjs/common';
import { PairingService } from './pairing.service';
import { PairingController } from './pairing.controller';
import { DevicesModule } from '../devices/devices.module';
import { SessionsModule } from '../sessions/sessions.module';

@Module({
  imports: [DevicesModule, SessionsModule],
  controllers: [PairingController],
  providers: [PairingService],
  exports: [PairingService],
})
export class PairingModule {}
