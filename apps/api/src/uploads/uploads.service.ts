import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UploadedAssetResponseDto } from './dto';

interface StoredUploadFile {
  filename: string;
  originalname: string;
  mimetype: string;
  size: number;
}

@Injectable()
export class UploadsService {
  constructor(private readonly configService: ConfigService) {}

  toUploadedAssetResponse(
    file: StoredUploadFile,
    kind: 'image' | 'document',
    relativePath: string,
  ): UploadedAssetResponseDto {
    return {
      kind,
      url: this.buildAssetUrl(relativePath),
      path: relativePath,
      filename: file.filename,
      originalName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
    };
  }

  getUploadDirectory(): string {
    return this.configService.getOrThrow<string>('uploads.directory');
  }

  getImageMaxBytes(): number {
    return this.configService.get<number>('uploads.imageMaxBytes', 6 * 1024 * 1024);
  }

  getDocumentMaxBytes(): number {
    return this.configService.get<number>(
      'uploads.documentMaxBytes',
      12 * 1024 * 1024,
    );
  }

  private buildAssetUrl(relativePath: string): string {
    const publicBaseUrl = this.configService
      .get<string>('uploads.publicBaseUrl', 'http://127.0.0.1:3000')
      .replace(/\/$/, '');

    return `${publicBaseUrl}${relativePath.startsWith('/') ? '' : '/'}${relativePath}`;
  }
}
