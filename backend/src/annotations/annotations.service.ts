import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export enum AnnotationType {
  FREEHAND = 'freehand',
  ARROW = 'arrow',
  RECTANGLE = 'rectangle',
  ELLIPSE = 'ellipse',
  TEXT = 'text',
  HIGHLIGHT = 'highlight',
  LINE = 'line',
  POINTER = 'pointer', // Temporary pointer/cursor highlight
}

interface CreateAnnotationDto {
  sessionId: string;
  creatorDeviceId: string;
  type: AnnotationType | string;
  color?: string;
  strokeWidth?: number;
  points: { x: number; y: number }[];
  text?: string;
}

interface UpdateAnnotationDto {
  points?: { x: number; y: number }[];
  text?: string;
  color?: string;
  strokeWidth?: number;
  isVisible?: boolean;
}

@Injectable()
export class AnnotationsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateAnnotationDto) {
    return this.prisma.annotation.create({
      data: {
        sessionId: dto.sessionId,
        creatorDeviceId: dto.creatorDeviceId,
        type: dto.type,
        color: dto.color || '#FF0000',
        strokeWidth: dto.strokeWidth || 3,
        points: JSON.stringify(dto.points),
        text: dto.text,
      },
    });
  }

  async update(annotationId: string, dto: UpdateAnnotationDto) {
    const data: Record<string, unknown> = {};

    if (dto.points) {
      data.points = JSON.stringify(dto.points);
    }
    if (dto.text !== undefined) {
      data.text = dto.text;
    }
    if (dto.color) {
      data.color = dto.color;
    }
    if (dto.strokeWidth) {
      data.strokeWidth = dto.strokeWidth;
    }
    if (dto.isVisible !== undefined) {
      data.isVisible = dto.isVisible;
    }

    return this.prisma.annotation.update({
      where: { id: annotationId },
      data,
    });
  }

  async delete(annotationId: string) {
    await this.prisma.annotation.delete({
      where: { id: annotationId },
    });
    return { success: true };
  }

  async getSessionAnnotations(sessionId: string) {
    const annotations = await this.prisma.annotation.findMany({
      where: { sessionId, isVisible: true },
      orderBy: { createdAt: 'asc' },
    });

    return annotations.map((annotation) => ({
      ...annotation,
      points: JSON.parse(annotation.points),
    }));
  }

  async clearSessionAnnotations(sessionId: string, creatorDeviceId?: string) {
    const where: Record<string, unknown> = { sessionId };

    if (creatorDeviceId) {
      where.creatorDeviceId = creatorDeviceId;
    }

    await this.prisma.annotation.deleteMany({ where });
    return { success: true };
  }

  async toggleVisibility(annotationId: string) {
    const annotation = await this.prisma.annotation.findUnique({
      where: { id: annotationId },
    });

    if (!annotation) {
      return null;
    }

    return this.prisma.annotation.update({
      where: { id: annotationId },
      data: { isVisible: !annotation.isVisible },
    });
  }
}
