import { IsString, IsIn } from 'class-validator';

export class UpdateSessionDto {
  @IsString()
  @IsIn(['pending', 'active', 'ended'])
  status: string;
}
