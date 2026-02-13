import { IsString, IsUUID } from 'class-validator';

export class GenerateCodeDto {
  @IsString()
  @IsUUID()
  deviceId: string;
}
