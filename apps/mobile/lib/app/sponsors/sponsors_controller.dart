import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import 'sponsor_models.dart';
import 'sponsors_api_client.dart';

class SponsorsController extends SafeChangeNotifier {
  SponsorsController({SponsorsApiClient? apiClient})
      : _apiClient = apiClient ?? SponsorsApiClient();

  final SponsorsApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  SponsorProfileModel? _mySponsorProfile;
  List<SponsorshipOpportunityModel> _openOpportunities = const [];
  List<SponsorshipOpportunityModel> _myOpportunities = const [];
  List<SponsorshipInterestModel> _myInterests = const [];
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  SponsorProfileModel? get mySponsorProfile => _mySponsorProfile;
  List<SponsorshipOpportunityModel> get openOpportunities => _openOpportunities;
  List<SponsorshipOpportunityModel> get myOpportunities => _myOpportunities;
  List<SponsorshipInterestModel> get myInterests => _myInterests;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shouldLoadSponsorData =
          session.user.role == UserRole.sponsor || session.user.role == UserRole.admin;
      final shouldLoadOrganizerData =
          session.user.role == UserRole.organizer || session.user.role == UserRole.admin;

      final futures = await Future.wait([
        _apiClient.fetchOpenOpportunities(),
        if (shouldLoadSponsorData)
          _apiClient.fetchMySponsorProfile(
            accessToken: session.tokens.accessToken,
          ),
        if (shouldLoadSponsorData)
          _apiClient.fetchMyInterests(
            accessToken: session.tokens.accessToken,
          ),
        if (shouldLoadOrganizerData)
          _apiClient.fetchMyOpportunities(
            accessToken: session.tokens.accessToken,
          ),
      ]);

      _openOpportunities = futures[0] as List<SponsorshipOpportunityModel>;
      var nextIndex = 1;
      if (shouldLoadSponsorData) {
        _mySponsorProfile = futures[nextIndex] as SponsorProfileModel?;
        nextIndex += 1;
        _myInterests = futures[nextIndex] as List<SponsorshipInterestModel>;
        nextIndex += 1;
      } else {
        _mySponsorProfile = null;
        _myInterests = const [];
      }
      if (shouldLoadOrganizerData) {
        _myOpportunities = futures[nextIndex] as List<SponsorshipOpportunityModel>;
      } else {
        _myOpportunities = const [];
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upsertMySponsorProfile(
    AuthSession session,
    SponsorProfileUpsertRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _mySponsorProfile = await _apiClient.upsertMySponsorProfile(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _successMessage = 'Sponsor profile updated.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> createOpportunity(
    AuthSession session,
    SponsorshipOpportunityCreateRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final opportunity = await _apiClient.createOpportunity(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _myOpportunities = [opportunity, ..._myOpportunities];
      if (opportunity.isOpen) {
        _openOpportunities = [opportunity, ..._openOpportunities];
      }
      _successMessage = 'Sponsorship opportunity created.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> expressInterest(
    AuthSession session,
    String opportunityId,
    SponsorshipInterestCreateRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final interest = await _apiClient.expressInterest(
        accessToken: session.tokens.accessToken,
        opportunityId: opportunityId,
        request: request,
      );
      _myInterests = [interest, ..._myInterests];
      _successMessage = 'Interest submitted to the organizer.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<List<SponsorshipInterestModel>> fetchOpportunityInterests(
    AuthSession session,
    String opportunityId,
  ) {
    return _apiClient.fetchOpportunityInterests(
      accessToken: session.tokens.accessToken,
      opportunityId: opportunityId,
    );
  }
}
