export class UploadedAssetResponseDto {
  kind!: 'image' | 'document';
  url!: string;
  path!: string;
  filename!: string;
  originalName!: string;
  mimeType!: string;
  size!: number;
}
