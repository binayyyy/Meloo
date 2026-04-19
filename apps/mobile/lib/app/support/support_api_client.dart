import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'support_models.dart';

class SupportApiClient {
  SupportApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<SupportTicketModel>> fetchMyTickets({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/support/tickets/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => SupportTicketModel.fromJson(item))
        .toList(growable: false);
  }

  Future<SupportTicketModel> createTicket({
    required String accessToken,
    required CreateSupportTicketRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/support/tickets'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    return SupportTicketModel.fromJson(_decodeMap(response));
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
