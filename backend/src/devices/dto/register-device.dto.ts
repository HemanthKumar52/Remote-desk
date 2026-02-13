import { IsString, IsIn } from 'class-validator';

export class RegisterDeviceDto {
  @IsString()
  deviceName: string;

  @IsString()
  @IsIn(['windows', 'macos', 'linux', 'android', 'ios'])
  platform: string;

  @IsString()
  deviceUniqueId: string;
}
