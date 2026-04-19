import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'chat_models.dart';

class ChatApiClient {
  ChatApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<ConversationModel>> fetchMyConversations({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/chat/conversations/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => ConversationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<ConversationModel> createDirectConversation({
    required String accessToken,
    required String participantUserId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/chat/conversations/direct'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'participantUserId': participantUserId}),
    );
    return ConversationModel.fromJson(_decodeMap(response));
  }

  Future<List<ChatMessageModel>> fetchMessages({
    required String accessToken,
    required String conversationId,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => ChatMessageModel.fromJson(item))
        .toList(growable: false);
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
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
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
