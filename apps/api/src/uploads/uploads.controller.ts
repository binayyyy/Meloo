import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { extname, join } from 'path';
import { mkdirSync } from 'fs';
import { randomUUID } from 'crypto';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { UploadedAssetResponseDto } from './dto';
import { UploadsService } from './uploads.service';

type UploadKind = 'image' | 'document';
type StoredUploadFile = {
  filename: string;
  originalname: string;
  mimetype: string;
  size: number;
};
type StorageCallback = (error: Error | null, value: string) => void;
type FileFilterCallback = (error: Error | null, acceptFile: boolean) => void;

// `multer` ships through Nest here, but the repo does not include its TS types.
const { diskStorage } = require('multer') as {
  diskStorage: (options: {
    destination: (
      request: unknown,
      file: StoredUploadFile,
      callback: StorageCallback,
    ) => void;
    filename: (
      request: unknown,
      file: StoredUploadFile,
      callback: StorageCallback,
    ) => void;
  }) => unknown;
};

function ensureUploadSubdirectory(kind: UploadKind): string {
  const root =
    process.env.UPLOADS_DIR ?? join(process.cwd(), '../../.tooling/uploads');
  const folder = join(root, kind === 'image' ? 'images' : 'documents');
  mkdirSync(folder, { recursive: true });
  return folder;
}

function sanitizeExtension(originalName: string, mimeType: string): string {
  const rawExtension = extname(originalName).toLowerCase();
  if (/^\.[a-z0-9]+$/.test(rawExtension)) {
    return rawExtension;
  }

  const fallback = mimeType.split('/').at(1)?.toLowerCase() ?? 'bin';
  const safeFallback = fallback.replace(/[^a-z0-9]/g, '');
  return safeFallback ? `.${safeFallback}` : '.bin';
}

function createStorage(kind: UploadKind) {
  return diskStorage({
    destination: (
      _request: unknown,
      _file: StoredUploadFile,
      callback: StorageCallback,
    ) => {
      callback(null, ensureUploadSubdirectory(kind));
    },
    filename: (
      _request: unknown,
      file: StoredUploadFile,
      callback: StorageCallback,
    ) => {
      callback(
        null,
        `${Date.now()}-${randomUUID()}${sanitizeExtension(
          file.originalname,
          file.mimetype,
        )}`,
      );
    },
  });
}

function createFileFilter(kind: UploadKind) {
  return (
    _request: unknown,
    file: StoredUploadFile,
    callback: FileFilterCallback,
  ) => {
    const isAccepted =
      kind === 'image'
        ? file.mimetype.startsWith('image/')
        : [
            'application/pdf',
            'image/',
            'text/plain',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/msword',
          ].some((allowed) => file.mimetype.startsWith(allowed));

    if (!isAccepted) {
      callback(
        new BadRequestException(
          kind === 'image'
            ? 'Only image uploads are allowed here'
            : 'Only PDF, document, text, or image files are allowed here',
        ),
        false,
      );
      return;
    }

    callback(null, true);
  };
}

@Controller('uploads')
@UseGuards(AccessTokenGuard)
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('images')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: createStorage('image'),
      fileFilter: createFileFilter('image'),
      limits: {
        fileSize: Number.parseInt(
          process.env.UPLOAD_IMAGE_MAX_BYTES ?? `${6 * 1024 * 1024}`,
          10,
        ),
      },
    }),
  )
  uploadImage(
    @UploadedFile() file?: StoredUploadFile,
  ): UploadedAssetResponseDto {
    return this.toUploadedAssetResponse(file, 'image');
  }

  @Post('documents')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: createStorage('document'),
      fileFilter: createFileFilter('document'),
      limits: {
        fileSize: Number.parseInt(
          process.env.UPLOAD_DOCUMENT_MAX_BYTES ?? `${12 * 1024 * 1024}`,
          10,
        ),
      },
    }),
  )
  uploadDocument(
    @UploadedFile() file?: StoredUploadFile,
  ): UploadedAssetResponseDto {
    return this.toUploadedAssetResponse(file, 'document');
  }

  private toUploadedAssetResponse(
    file: StoredUploadFile | undefined,
    kind: UploadKind,
  ): UploadedAssetResponseDto {
    if (!file) {
      throw new BadRequestException('File upload is required');
    }

    const relativePath = `/uploads/${
      kind === 'image' ? 'images' : 'documents'
    }/${file.filename}`;

    return this.uploadsService.toUploadedAssetResponse(file, kind, relativePath);
  }
}
