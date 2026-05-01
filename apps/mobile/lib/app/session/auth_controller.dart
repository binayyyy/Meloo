import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/safe_change_notifier.dart';
import 'auth_api_client.dart';
import 'auth_models.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthController extends SafeChangeNotifier {
  AuthController({AuthApiClient? apiClient})
      : _apiClient = apiClient ?? AuthApiClient();

  static const _storageKey = 'smart_event.auth_session';
  final AuthApiClient _apiClient;

  AuthStatus _status = AuthStatus.loading;
  AuthSession? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _setLoading();
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);

    if (encoded == null) {
      _session = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final persistedSession = AuthSession.fromJson(decoded);
      final refreshed = await _apiClient.refresh(
        refreshToken: persistedSession.tokens.refreshToken,
      );
      final currentUser = await _apiClient.fetchMe(
        accessToken: refreshed.tokens.accessToken,
      );
      _session = AuthSession(user: currentUser, tokens: refreshed.tokens);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      await _persistSession();
    } catch (_) {
      await clearSession();
      return;
    }

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runSessionAction(() => _apiClient.login(email: email, password: password));
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    await _runSessionAction(
      () => _apiClient.signUp(email: email, password: password, role: role),
    );
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    _setLoading();

    try {
      final result = await _apiClient.forgotPassword(email: email);
      _status = _session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return result;
    } on ApiException catch (error) {
      _status = _session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      _status = _session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      _errorMessage =
          'Unable to reach the server. Check the local API and try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    final refreshToken = _session?.tokens.refreshToken;
    try {
      if (refreshToken != null) {
        await _apiClient.logout(refreshToken: refreshToken);
      }
    } catch (_) {
    } finally {
      await clearSession();
    }
  }

  Future<void> updateMe({
    UserProfileModel? profile,
    UserSettingsModel? settings,
  }) async {
    final currentSession = _session;
    if (currentSession == null) {
      throw ApiException('You must be signed in to update your profile.');
    }

    try {
      final updatedUser = await _apiClient.updateMe(
        accessToken: currentSession.tokens.accessToken,
        body: {
          if (profile != null) 'profile': profile.toJson(),
          if (settings != null) 'settings': settings.toJson(),
        },
      );
      _session = AuthSession(
        user: updatedUser,
        tokens: currentSession.tokens,
      );
      _errorMessage = null;
      await _persistSession();
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      _errorMessage =
          'Unable to reach the server. Check the local API and try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearSession() async {
    _session = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    notifyListeners();
  }

  void bootstrapSession(AuthSession session) {
    _session = session;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _runSessionAction(
    Future<AuthSession> Function() action,
  ) async {
    _setLoading();

    try {
      final newSession = await action();
      _session = newSession;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      await _persistSession();
      notifyListeners();
    } on ApiException catch (error) {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage =
          'Unable to reach the server. Check the local API and try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _persistSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_session!.toJson()));
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    notifyListeners();
  }
}
