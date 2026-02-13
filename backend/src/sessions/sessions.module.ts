import { Module, forwardRef } from '@nestjs/common';
import { SessionsService } from './sessions.service';
import { SessionsController } from './sessions.controller';
import { DevicesModule } from '../devices/devices.module';

@Module({
  imports: [forwardRef(() => DevicesModule)],
  controllers: [SessionsController],
  providers: [SessionsService],
  exports: [SessionsService],
})
export class SessionsModule {}
