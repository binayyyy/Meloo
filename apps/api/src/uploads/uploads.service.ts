import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UploadedAssetResponseDto } from './dto';

interface StoredUploadFile {
  filename: string;
  originalname: string;
  mimetype: string;
  size: number;
}

interface AssetRequestLike {
  protocol?: string;
  get?: (name: string) => string | undefined;
  headers?: Record<string, string | string[] | undefined>;
}

@Injectable()
export class UploadsService {
  constructor(private readonly configService: ConfigService) {}

  toUploadedAssetResponse(
    file: StoredUploadFile,
    kind: 'image' | 'document',
    relativePath: string,
    request?: AssetRequestLike,
  ): UploadedAssetResponseDto {
    return {
      kind,
      url: this.buildAssetUrl(relativePath, request),
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

  private buildAssetUrl(
    relativePath: string,
    request?: AssetRequestLike,
  ): string {
    const configuredBaseUrl =
      this.configService.get<string>('uploads.publicBaseUrl', '').trim();
    const publicBaseUrl = (
      configuredBaseUrl.length > 0
        ? configuredBaseUrl
        : (this.resolveRequestOrigin(request) ??
            `http://127.0.0.1:${this.configService.get<number>('app.port', 3000)}`)
    ).replace(/\/$/, '');

    return `${publicBaseUrl}${relativePath.startsWith('/') ? '' : '/'}${relativePath}`;
  }

  private resolveRequestOrigin(request?: AssetRequestLike): string | null {
    if (request == null) {
      return null;
    }

    const forwardedProto = this.readHeader(request, 'x-forwarded-proto')
      ?.split(',')
      [0]
      ?.trim();
    const host =
      this.readHeader(request, 'x-forwarded-host') ??
      request.get?.('host') ??
      this.readHeader(request, 'host');

    if (host == null || host.trim().length === 0) {
      return null;
    }

    const protocol = forwardedProto ?? request.protocol ?? 'http';
    return `${protocol.trim()}://${host.trim()}`;
  }

  private readHeader(
    request: AssetRequestLike,
    name: string,
  ): string | null {
    const value = request.headers?.[name];
    if (Array.isArray(value)) {
      return value.length == 0 ? null : value[0];
    }
    if (typeof value === 'string') {
      return value;
    }
    return null;
  }
}
