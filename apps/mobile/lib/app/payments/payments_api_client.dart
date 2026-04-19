import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/auth_api_client.dart';
import 'payment_models.dart';

class PaymentsApiClient {
  PaymentsApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<PaymentCheckoutModel> createCheckoutSession({
    required String eventId,
    required String accessToken,
    required String ticketTypeId,
    required int quantity,
    String? returnUrl,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/events/$eventId/payments/checkout-session'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ticketTypeId': ticketTypeId,
        'quantity': quantity,
        if (returnUrl != null) 'returnUrl': returnUrl,
      }),
    );

    return PaymentCheckoutModel.fromJson(_decodeMap(response));
  }

  Future<PaymentCheckoutModel> verifyStripeCheckoutSession({
    required String checkoutSessionId,
    required String accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/payments/stripe/sessions/$checkoutSessionId/verify'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    return PaymentCheckoutModel.fromJson(_decodeMap(response));
  }

  Future<List<PaymentCheckoutModel>> fetchMyPayments({
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/payments/my'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    return _decodeList(response)
        .map((item) => PaymentCheckoutModel.fromJson(item))
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
