import { resolve } from 'path';
import { registerAs } from '@nestjs/config';

export default registerAs('uploads', () => ({
  directory:
    process.env.UPLOADS_DIR ?? resolve(process.cwd(), '../../.tooling/uploads'),
  publicBaseUrl: process.env.PUBLIC_API_BASE_URL?.trim() ?? '',
  imageMaxBytes: Number.parseInt(
    process.env.UPLOAD_IMAGE_MAX_BYTES ?? `${6 * 1024 * 1024}`,
    10,
  ),
  documentMaxBytes: Number.parseInt(
    process.env.UPLOAD_DOCUMENT_MAX_BYTES ?? `${12 * 1024 * 1024}`,
    10,
  ),
}));
