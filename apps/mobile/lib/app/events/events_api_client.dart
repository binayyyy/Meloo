import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'event_models.dart';

class EventsApiClient {
  EventsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<EventCategoryModel>> fetchCategories() async {
    final response = await _client.get(Uri.parse('$_baseUrl/event-categories'));
    final decoded = _decodeList(response);
    return decoded
        .map((item) => EventCategoryModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<EventModel>> fetchPublicEvents() async {
    final response = await _client.get(Uri.parse('$_baseUrl/events'));
    final decoded = _decodeList(response);
    return decoded.map((item) => EventModel.fromJson(item)).toList(growable: false);
  }

  Future<List<EventModel>> fetchMyEvents({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/events/my'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final decoded = _decodeList(response);
    return decoded.map((item) => EventModel.fromJson(item)).toList(growable: false);
  }

  Future<List<EventModel>> fetchFavoriteEvents({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/events/my/favorites'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final decoded = _decodeList(response);
    return decoded.map((item) => EventModel.fromJson(item)).toList(growable: false);
  }

  Future<List<EventModel>> fetchRecentlyViewedEvents({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/events/my/recently-viewed'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final decoded = _decodeList(response);
    return decoded.map((item) => EventModel.fromJson(item)).toList(growable: false);
  }

  Future<EventModel> fetchPublicEvent(String eventId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/events/$eventId'));
    return EventModel.fromJson(_decodeMap(response));
  }

  Future<EventModel> fetchManageEvent({
    required String eventId,
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/events/$eventId/manage'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    return EventModel.fromJson(_decodeMap(response));
  }

  Future<List<TicketTypeModel>> fetchPublicTicketTypes(String eventId) async {
    final response =
        await _client.get(Uri.parse('$_baseUrl/events/$eventId/ticket-types'));
    return _decodeList(response)
        .map((item) => TicketTypeModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<TicketTypeModel>> fetchManageTicketTypes({
    required String eventId,
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/events/$eventId/ticket-types/manage'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(response)
        .map((item) => TicketTypeModel.fromJson(item))
        .toList(growable: false);
  }

  Future<TicketTypeModel> createTicketType({
    required String eventId,
    required String accessToken,
    required TicketTypeCreateRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/$eventId/ticket-types'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    return TicketTypeModel.fromJson(_decodeMap(response));
  }

  Future<RegistrationModel> createRegistration({
    required String eventId,
    required String accessToken,
    required String ticketTypeId,
    required int quantity,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/$eventId/registrations'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ticketTypeId': ticketTypeId,
        'quantity': quantity,
      }),
    );

    return RegistrationModel.fromJson(_decodeMap(response));
  }

  Future<List<RegistrationModel>> fetchMyRegistrations({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/registrations/my'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _decodeList(response)
        .map((item) => RegistrationModel.fromJson(item))
        .toList(growable: false);
  }

  Future<EventModel> createEvent({
    required String accessToken,
    required EventCreateRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    final decoded = _decodeMap(response);
    return EventModel.fromJson(decoded);
  }

  Future<bool> favoriteEvent({
    required String eventId,
    required String accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/$eventId/favorite'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final decoded = _decodeMap(response);
    return decoded['isFavorite'] as bool? ?? true;
  }

  Future<bool> unfavoriteEvent({
    required String eventId,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/events/$eventId/favorite'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    final decoded = _decodeMap(response);
    return decoded['isFavorite'] as bool? ?? false;
  }

  Future<void> recordEventView({
    required String eventId,
    required String accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/$eventId/view'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
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
