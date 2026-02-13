import { Module } from '@nestjs/common';
import { AnnotationsService } from './annotations.service';
import { AnnotationsGateway } from './annotations.gateway';

@Module({
  providers: [AnnotationsService, AnnotationsGateway],
  exports: [AnnotationsService],
})
export class AnnotationsModule {}
