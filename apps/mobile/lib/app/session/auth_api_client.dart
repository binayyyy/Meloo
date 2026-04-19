import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_models.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApiClient {
  AuthApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final http.Client _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final json = await _post(
      '/auth/signup',
      body: {
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> refresh({
    required String refreshToken,
  }) async {
    final json = await _post(
      '/auth/refresh',
      body: {
        'refreshToken': refreshToken,
      },
    );
    return AuthSession.fromJson(json);
  }

  Future<void> logout({required String refreshToken}) async {
    await _post(
      '/auth/logout',
      body: {
        'refreshToken': refreshToken,
      },
    );
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final json = await _post(
      '/auth/forgot-password',
      body: {
        'email': email,
      },
    );
    return ForgotPasswordResult.fromJson(json);
  }

  Future<UserModel> fetchMe({required String accessToken}) async {
    final uri = Uri.parse('$_defaultBaseUrl/users/me');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    final json = _decode(response);
    return UserModel.fromJson(json);
  }

  Future<UserModel> updateMe({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_defaultBaseUrl/users/me');
    final response = await _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final json = _decode(response);
    return UserModel.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_defaultBaseUrl$path');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic>) {
        throw ApiException(
          decoded['message'] is List
              ? (decoded['message'] as List).join(', ')
              : (decoded['message']?.toString() ?? 'Request failed'),
        );
      }

      throw ApiException('Request failed with status ${response.statusCode}');
    }

    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
  }
}
