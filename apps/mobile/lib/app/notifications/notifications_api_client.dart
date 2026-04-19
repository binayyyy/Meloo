import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'notification_models.dart';

class NotificationsApiClient {
  NotificationsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<AppNotificationModel>> fetchMyNotifications({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => AppNotificationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<void> markNotificationRead({
    required String accessToken,
    required String notificationId,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decodeMap(response);
  }

  Future<void> markAllNotificationsRead({
    required String accessToken,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    _decodeMap(response);
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    final dynamic decoded =
        response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw _toApiException(decoded, response.statusCode);
    }
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final dynamic decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw _toApiException(decoded, response.statusCode);
    }
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
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
