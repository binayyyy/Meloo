import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'sponsor_models.dart';

class SponsorsApiClient {
  SponsorsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<SponsorProfileModel?> fetchMySponsorProfile({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sponsors/me/profile'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 && response.body == 'null') {
      return null;
    }

    final decoded = _decodeMap(response);
    if (decoded.isEmpty) {
      return null;
    }
    return SponsorProfileModel.fromJson(decoded);
  }

  Future<SponsorProfileModel> upsertMySponsorProfile({
    required String accessToken,
    required SponsorProfileUpsertRequest request,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/sponsors/me/profile'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    return SponsorProfileModel.fromJson(_decodeMap(response));
  }

  Future<List<SponsorshipOpportunityModel>> fetchOpenOpportunities() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sponsorship-opportunities'),
    );
    return _decodeList(response)
        .map((item) => SponsorshipOpportunityModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<SponsorshipOpportunityModel>> fetchMyOpportunities({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sponsorship-opportunities/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => SponsorshipOpportunityModel.fromJson(item))
        .toList(growable: false);
  }

  Future<SponsorshipOpportunityModel> createOpportunity({
    required String accessToken,
    required SponsorshipOpportunityCreateRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$_baseUrl/events/${request.eventId}/sponsorship-opportunities',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    return SponsorshipOpportunityModel.fromJson(_decodeMap(response));
  }

  Future<SponsorshipInterestModel> expressInterest({
    required String accessToken,
    required String opportunityId,
    required SponsorshipInterestCreateRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$_baseUrl/sponsorship-opportunities/$opportunityId/interests',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    return SponsorshipInterestModel.fromJson(_decodeMap(response));
  }

  Future<List<SponsorshipInterestModel>> fetchMyInterests({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sponsorship-interests/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => SponsorshipInterestModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<SponsorshipInterestModel>> fetchOpportunityInterests({
    required String accessToken,
    required String opportunityId,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '$_baseUrl/sponsorship-opportunities/$opportunityId/interests',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => SponsorshipInterestModel.fromJson(item))
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
