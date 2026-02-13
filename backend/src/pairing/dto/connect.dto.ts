import { IsString, Length, IsUUID } from 'class-validator';

export class ConnectDto {
  @IsString()
  @Length(6, 6)
  code: string;

  @IsString()
  @IsUUID()
  clientDeviceId: string;
}
