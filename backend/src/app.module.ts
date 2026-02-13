import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { DevicesModule } from './devices/devices.module';
import { SessionsModule } from './sessions/sessions.module';
import { PairingModule } from './pairing/pairing.module';
import { SignalingModule } from './signaling/signaling.module';
import { TwoFactorModule } from './two-factor/two-factor.module';
import { AuditLogModule } from './audit-log/audit-log.module';
import { DeviceGroupsModule } from './device-groups/device-groups.module';
import { AddressBookModule } from './address-book/address-book.module';
import { ChatModule } from './chat/chat.module';
import { AnnotationsModule } from './annotations/annotations.module';
import { RecordingsModule } from './recordings/recordings.module';
import { SystemToolsModule } from './system-tools/system-tools.module';
import { ConnectionStatsModule } from './connection-stats/connection-stats.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    DevicesModule,
    SessionsModule,
    PairingModule,
    SignalingModule,
    // Advanced Features
    TwoFactorModule,
    AuditLogModule,
    DeviceGroupsModule,
    AddressBookModule,
    ChatModule,
    AnnotationsModule,
    RecordingsModule,
    SystemToolsModule,
    ConnectionStatsModule,
  ],
})
export class AppModule {}
