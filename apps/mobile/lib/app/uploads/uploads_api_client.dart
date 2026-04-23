import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'upload_models.dart';

class UploadsApiClient {
  UploadsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<UploadedAssetModel> uploadFile({
    required String accessToken,
    required PlatformFile file,
    required UploadAssetKind kind,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$_baseUrl/uploads/${kind == UploadAssetKind.image ? 'images' : 'documents'}',
      ),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';
    request.files.add(await _toMultipartFile(file));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final dynamic decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw _toApiException(decoded, response.statusCode);
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Upload failed with an invalid response');
    }

    return UploadedAssetModel.fromJson(decoded);
  }

  Future<http.MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      );
    }

    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      );
    }

    throw ApiException('Selected file could not be read');
  }

  ApiException _toApiException(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      return ApiException(
        decoded['message'] is List
            ? (decoded['message'] as List).join(', ')
            : (decoded['message']?.toString() ?? 'Request failed'),
      );
    }

    return ApiException('Request failed with status $statusCode');
  }
}
