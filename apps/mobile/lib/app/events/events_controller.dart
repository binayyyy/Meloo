import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import 'event_models.dart';
import 'events_api_client.dart';

class EventsController extends SafeChangeNotifier {
  EventsController({EventsApiClient? apiClient})
      : _apiClient = apiClient ?? EventsApiClient();

  final EventsApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String? _successMessage;
  List<EventCategoryModel> _categories = const [];
  List<EventModel> _publicEvents = const [];
  List<EventModel> _myEvents = const [];
  List<EventModel> _favoriteEvents = const [];
  List<EventModel> _recentlyViewedEvents = const [];
  List<RegistrationModel> _myRegistrations = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<EventCategoryModel> get categories => _categories;
  List<EventModel> get publicEvents => _publicEvents;
  List<EventModel> get myEvents => _myEvents;
  List<EventModel> get favoriteEvents => _favoriteEvents;
  List<EventModel> get recentlyViewedEvents => _recentlyViewedEvents;
  List<RegistrationModel> get myRegistrations => _myRegistrations;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shouldLoadManagedEvents = _canManageEvents(session.user.role);
      final shouldLoadRegistrations = session.user.role == UserRole.attendee;

      final futures = await Future.wait([
        _apiClient.fetchCategories(),
        _apiClient.fetchPublicEvents(),
        _apiClient.fetchFavoriteEvents(accessToken: session.tokens.accessToken),
        _apiClient.fetchRecentlyViewedEvents(
          accessToken: session.tokens.accessToken,
        ),
        if (shouldLoadManagedEvents)
          _apiClient.fetchMyEvents(accessToken: session.tokens.accessToken),
        if (shouldLoadRegistrations)
          _apiClient.fetchMyRegistrations(
            accessToken: session.tokens.accessToken,
          ),
      ]);

      _categories = futures[0] as List<EventCategoryModel>;
      _publicEvents = futures[1] as List<EventModel>;
      _favoriteEvents = futures[2] as List<EventModel>;
      _recentlyViewedEvents = futures[3] as List<EventModel>;
      var nextIndex = 4;
      if (shouldLoadManagedEvents) {
        _myEvents = futures[nextIndex] as List<EventModel>;
        nextIndex += 1;
      } else {
        _myEvents = const [];
      }
      if (shouldLoadRegistrations) {
        _myRegistrations = futures[nextIndex] as List<RegistrationModel>;
      } else {
        _myRegistrations = const [];
      }
      _hasLoaded = true;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent(
    AuthSession session,
    EventCreateRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await _apiClient.createEvent(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _myEvents = [created, ..._myEvents];
      if (created.isPubliclyVisible) {
        _publicEvents = [created, ..._publicEvents];
      }
      _successMessage = created.isPubliclyVisible
          ? 'Event created and published.'
          : 'Event saved as draft.';
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void addRegistration(RegistrationModel registration) {
    _myRegistrations = [registration, ..._myRegistrations];
    _successMessage = 'Registration confirmed for ${registration.event.title}.';
    notifyListeners();
  }

  Future<bool> toggleFavorite(AuthSession session, String eventId) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final isFavorite = _favoriteEvents.any((event) => event.id == eventId);
      final nextFavorite = isFavorite
          ? await _apiClient.unfavoriteEvent(
              eventId: eventId,
              accessToken: session.tokens.accessToken,
            )
          : await _apiClient.favoriteEvent(
              eventId: eventId,
              accessToken: session.tokens.accessToken,
            );

      if (nextFavorite) {
        final source = _publicEvents
            .followedBy(_myEvents)
            .firstWhere((event) => event.id == eventId);
        _favoriteEvents = [source, ..._favoriteEvents.where((event) => event.id != eventId)];
        _successMessage = 'Event saved to favorites.';
      } else {
        _favoriteEvents = _favoriteEvents
            .where((event) => event.id != eventId)
            .toList(growable: false);
        _successMessage = 'Event removed from favorites.';
      }

      return nextFavorite;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> recordEventView(AuthSession session, String eventId) async {
    try {
      await _apiClient.recordEventView(
        eventId: eventId,
        accessToken: session.tokens.accessToken,
      );
      final viewed = _publicEvents
          .followedBy(_myEvents)
          .firstWhere((event) => event.id == eventId);
      _recentlyViewedEvents = [
        viewed,
        ..._recentlyViewedEvents.where((event) => event.id != eventId),
      ].take(12).toList(growable: false);
      notifyListeners();
    } catch (_) {
      // Quietly ignore view-tracking failures so detail navigation remains responsive.
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  bool _canManageEvents(UserRole role) {
    return role == UserRole.organizer || role == UserRole.admin;
  }
}
