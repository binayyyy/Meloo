import '../core/json_value.dart';

enum UploadAssetKind { image, document }

class UploadedAssetModel {
  const UploadedAssetModel({
    required this.kind,
    required this.url,
    required this.path,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.size,
  });

  final UploadAssetKind kind;
  final String url;
  final String path;
  final String filename;
  final String originalName;
  final String mimeType;
  final int size;

  factory UploadedAssetModel.fromJson(Map<String, dynamic> json) {
    return UploadedAssetModel(
      kind: stringValue(json['kind'], fallback: 'image') == 'document'
          ? UploadAssetKind.document
          : UploadAssetKind.image,
      url: stringValue(json['url']),
      path: stringValue(json['path']),
      filename: stringValue(json['filename']),
      originalName: stringValue(json['originalName']),
      mimeType: stringValue(json['mimeType']),
      size: intValue(json['size']),
    );
  }
}
