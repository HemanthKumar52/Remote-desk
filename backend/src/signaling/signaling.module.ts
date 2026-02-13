import { Module } from '@nestjs/common';
import { SignalingGateway } from './signaling.gateway';
import { SessionsModule } from '../sessions/sessions.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [SessionsModule, AuthModule],
  providers: [SignalingGateway],
})
export class SignalingModule {}
