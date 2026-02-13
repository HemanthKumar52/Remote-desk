import { IsString, IsUUID, IsOptional } from 'class-validator';

export class CreateSessionDto {
  @IsString()
  @IsUUID()
  hostDeviceId: string;

  @IsOptional()
  @IsString()
  @IsUUID()
  clientDeviceId?: string;
}
