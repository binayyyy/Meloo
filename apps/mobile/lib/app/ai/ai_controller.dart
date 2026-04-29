import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import 'ai_api_client.dart';
import 'ai_models.dart';

class AiController extends SafeChangeNotifier {
  AiController({AiApiClient? apiClient})
      : _apiClient = apiClient ?? AiApiClient();

  final AiApiClient _apiClient;

  bool _isLoading = false;
  bool _isPlanning = false;
  List<AiEventRecommendationModel> _recommendedEvents = const [];
  List<AiVendorRecommendationModel> _recommendedVendors = const [];
  List<AiOpportunityRecommendationModel> _recommendedOpportunities = const [];
  AiPlanningAssistantResponseModel? _planningBrief;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isPlanning => _isPlanning;
  List<AiEventRecommendationModel> get recommendedEvents => _recommendedEvents;
  List<AiVendorRecommendationModel> get recommendedVendors => _recommendedVendors;
  List<AiOpportunityRecommendationModel> get recommendedOpportunities =>
      _recommendedOpportunities;
  AiPlanningAssistantResponseModel? get planningBrief => _planningBrief;
  String? get errorMessage => _errorMessage;

  Future<void> load(
    AuthSession session, {
    String? organizerEventId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shouldLoadVendorRecommendations =
          (session.user.role == UserRole.organizer ||
                  session.user.role == UserRole.admin) &&
              organizerEventId != null;
      final shouldLoadOpportunityRecommendations =
          session.user.role == UserRole.sponsor ||
              session.user.role == UserRole.admin;
      final failures = <String>[];

      _recommendedEvents = await _safeLoad(
        () => _apiClient.fetchEventRecommendations(
          accessToken: session.tokens.accessToken,
        ),
        fallback: const <AiEventRecommendationModel>[],
        failures: failures,
        label: 'event recommendations',
      );
      _recommendedVendors = shouldLoadVendorRecommendations
          ? await _safeLoad(
              () => _apiClient.fetchVendorRecommendations(
                accessToken: session.tokens.accessToken,
                eventId: organizerEventId,
              ),
              fallback: const <AiVendorRecommendationModel>[],
              failures: failures,
              label: 'vendor recommendations',
            )
          : const [];
      _recommendedOpportunities = shouldLoadOpportunityRecommendations
          ? await _safeLoad(
              () => _apiClient.fetchOpportunityRecommendations(
                accessToken: session.tokens.accessToken,
              ),
              fallback: const <AiOpportunityRecommendationModel>[],
              failures: failures,
              label: 'sponsor recommendations',
            )
          : const [];

      _errorMessage = failures.isEmpty
          ? null
          : 'Some AI panels are unavailable right now: ${failures.join(', ')}.';
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generatePlanningBrief(
    AuthSession session, {
    required String? eventId,
    required int? expectedAttendees,
    required String? budget,
    required String? planningGoal,
  }) async {
    _isPlanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _planningBrief = await _apiClient.generatePlanningBrief(
        accessToken: session.tokens.accessToken,
        eventId: eventId,
        expectedAttendees: expectedAttendees,
        budget: budget,
        planningGoal: planningGoal,
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isPlanning = false;
      notifyListeners();
    }
  }

  Future<T> _safeLoad<T>(
    Future<T> Function() loader, {
    required T fallback,
    required List<String> failures,
    required String label,
  }) async {
    try {
      return await loader();
    } catch (_) {
      failures.add(label);
      return fallback;
    }
  }
}
