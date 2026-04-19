import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'ai_models.dart';

class AiApiClient {
  AiApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<AiEventRecommendationModel>> fetchEventRecommendations({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ai/recommendations/events'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => AiEventRecommendationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<AiVendorRecommendationModel>> fetchVendorRecommendations({
    required String accessToken,
    required String eventId,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ai/recommendations/vendors?eventId=$eventId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => AiVendorRecommendationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<AiOpportunityRecommendationModel>> fetchOpportunityRecommendations({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ai/recommendations/opportunities'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => AiOpportunityRecommendationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<AiPlanningAssistantResponseModel> generatePlanningBrief({
    required String accessToken,
    required String? eventId,
    required int? expectedAttendees,
    required String? budget,
    required String? planningGoal,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/ai/planning/organizer'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (eventId != null) 'eventId': eventId,
        if (expectedAttendees != null) 'expectedAttendees': expectedAttendees,
        if (budget != null) 'budget': budget,
        if (planningGoal != null) 'planningGoal': planningGoal,
      }),
    );
    return AiPlanningAssistantResponseModel.fromJson(_decodeMap(response));
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
