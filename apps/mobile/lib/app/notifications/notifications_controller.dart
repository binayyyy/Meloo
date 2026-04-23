import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import 'notification_models.dart';
import 'notifications_api_client.dart';

class NotificationsController extends SafeChangeNotifier {
  NotificationsController({NotificationsApiClient? apiClient})
      : _apiClient = apiClient ?? NotificationsApiClient();

  final NotificationsApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<AppNotificationModel> _notifications = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<AppNotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((item) => item.unread).length;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _apiClient.fetchMyNotifications(
        accessToken: session.tokens.accessToken,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AuthSession session, String notificationId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.markNotificationRead(
        accessToken: session.tokens.accessToken,
        notificationId: notificationId,
      );
      _notifications = _notifications
          .map(
            (item) => item.id == notificationId
                ? AppNotificationModel(
                    id: item.id,
                    type: item.type,
                    title: item.title,
                    body: item.body,
                    resourceType: item.resourceType,
                    resourceId: item.resourceId,
                    readAt: DateTime.now(),
                    createdAt: item.createdAt,
                    unread: false,
                  )
                : item,
          )
          .toList(growable: false);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead(AuthSession session) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.markAllNotificationsRead(
        accessToken: session.tokens.accessToken,
      );
      final now = DateTime.now();
      _notifications = _notifications
          .map(
            (item) => AppNotificationModel(
              id: item.id,
              type: item.type,
              title: item.title,
              body: item.body,
              resourceType: item.resourceType,
              resourceId: item.resourceId,
              readAt: now,
              createdAt: item.createdAt,
              unread: false,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
