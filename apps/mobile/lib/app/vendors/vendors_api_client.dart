import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'vendor_models.dart';

class VendorsApiClient {
  VendorsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<List<VendorProfileModel>> fetchPublicVendors() async {
    final response = await _client.get(Uri.parse('$_baseUrl/vendors'));
    return _decodeList(response)
        .map((item) => VendorProfileModel.fromJson(item))
        .toList(growable: false);
  }

  Future<VendorProfileModel?> fetchMyVendorProfile({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/vendors/me/profile'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200 && response.body == 'null') {
      return null;
    }

    final decoded = _decodeMap(response);
    if (decoded.isEmpty) {
      return null;
    }
    return VendorProfileModel.fromJson(decoded);
  }

  Future<VendorProfileModel> upsertMyVendorProfile({
    required String accessToken,
    required VendorProfileUpsertRequest request,
  }) async {
    await _patch(
      '/vendors/me/profile',
      accessToken: accessToken,
      body: request.profileJson,
    );
    final decoded = await _patch(
      '/vendors/me/booking-preference',
      accessToken: accessToken,
      body: request.bookingPreferenceJson,
    );
    return VendorProfileModel.fromJson(decoded);
  }

  Future<VendorProfileModel> createVendorService({
    required String accessToken,
    required VendorServiceCreateRequest request,
  }) async {
    final decoded = await _post(
      '/vendors/me/services',
      accessToken: accessToken,
      body: request.toJson(),
    );
    return VendorProfileModel.fromJson(decoded);
  }

  Future<VendorProfileModel> createVendorPackage({
    required String accessToken,
    required VendorPackageCreateRequest request,
  }) async {
    final decoded = await _post(
      '/vendors/me/packages',
      accessToken: accessToken,
      body: request.toJson(),
    );
    return VendorProfileModel.fromJson(decoded);
  }

  Future<VendorRequestModel> createVendorRequest({
    required String vendorId,
    required String accessToken,
    required VendorRequestCreateRequest request,
  }) async {
    final decoded = await _post(
      '/vendors/$vendorId/requests',
      accessToken: accessToken,
      body: request.toJson(),
    );
    return VendorRequestModel.fromJson(decoded);
  }

  Future<List<VendorRequestModel>> fetchMyOrganizerRequests({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/vendors/requests/my-organizer'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => VendorRequestModel.fromJson(item))
        .toList(growable: false);
  }

  Future<List<VendorRequestModel>> fetchMyVendorRequests({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/vendors/requests/my-vendor'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeList(response)
        .map((item) => VendorRequestModel.fromJson(item))
        .toList(growable: false);
  }

  Future<VendorRequestModel> respondToVendorRequest({
    required String requestId,
    required String accessToken,
    required String status,
  }) async {
    final decoded = await _patch(
      '/vendors/requests/$requestId/respond',
      accessToken: accessToken,
      body: {'status': status},
    );
    return VendorRequestModel.fromJson(decoded);
  }

  Future<VendorRequestModel> markVendorRequestBooked({
    required String requestId,
    required String accessToken,
  }) async {
    final decoded = await _patch(
      '/vendors/requests/$requestId/book',
      accessToken: accessToken,
      body: const {},
    );
    return VendorRequestModel.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeMap(response);
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
