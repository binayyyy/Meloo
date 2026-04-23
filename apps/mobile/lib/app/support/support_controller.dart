import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import 'support_api_client.dart';
import 'support_models.dart';

class SupportController extends SafeChangeNotifier {
  SupportController({SupportApiClient? apiClient})
      : _apiClient = apiClient ?? SupportApiClient();

  final SupportApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<SupportTicketModel> _tickets = const [];
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<SupportTicketModel> get tickets => _tickets;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _apiClient.fetchMyTickets(
        accessToken: session.tokens.accessToken,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTicket(
    AuthSession session,
    CreateSupportTicketRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await _apiClient.createTicket(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _tickets = [created, ..._tickets];
      _successMessage = created.escalation == null
          ? 'Support ticket created.'
          : 'Support ticket created and escalated.';
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
