import 'package:flutter/foundation.dart';
import '../session/auth_models.dart';
import 'vendor_models.dart';
import 'vendors_api_client.dart';

class VendorsController extends ChangeNotifier {
  VendorsController({VendorsApiClient? apiClient})
      : _apiClient = apiClient ?? VendorsApiClient();

  final VendorsApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<VendorProfileModel> _publicVendors = const [];
  List<VendorRequestModel> _myOrganizerRequests = const [];
  List<VendorRequestModel> _myVendorRequests = const [];
  VendorProfileModel? _myVendorProfile;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<VendorProfileModel> get publicVendors => _publicVendors;
  List<VendorRequestModel> get myOrganizerRequests => _myOrganizerRequests;
  List<VendorRequestModel> get myVendorRequests => _myVendorRequests;
  VendorProfileModel? get myVendorProfile => _myVendorProfile;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final publicVendors = await _apiClient.fetchPublicVendors();
      _publicVendors = publicVendors;
      if (session.user.role == UserRole.organizer ||
          session.user.role == UserRole.admin) {
        _myOrganizerRequests = await _apiClient.fetchMyOrganizerRequests(
          accessToken: session.tokens.accessToken,
        );
      } else {
        _myOrganizerRequests = const [];
      }
      if (session.user.role == UserRole.vendor) {
        _myVendorProfile = await _apiClient.fetchMyVendorProfile(
          accessToken: session.tokens.accessToken,
        );
        _myVendorRequests = await _apiClient.fetchMyVendorRequests(
          accessToken: session.tokens.accessToken,
        );
      } else {
        _myVendorRequests = const [];
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upsertMyVendorProfile(
    AuthSession session,
    VendorProfileUpsertRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _myVendorProfile = await _apiClient.upsertMyVendorProfile(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _successMessage = 'Vendor profile updated.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> createVendorService(
    AuthSession session,
    VendorServiceCreateRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _myVendorProfile = await _apiClient.createVendorService(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _successMessage = 'Service added.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> createVendorPackage(
    AuthSession session,
    VendorPackageCreateRequest request,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _myVendorProfile = await _apiClient.createVendorPackage(
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _successMessage = 'Package added.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> createVendorRequest(
    AuthSession session, {
    required String vendorId,
    required VendorRequestCreateRequest request,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _apiClient.createVendorRequest(
        vendorId: vendorId,
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _successMessage = request.directBookingPreferred
          ? 'Vendor booked through direct booking.'
          : 'Vendor request sent.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> respondToVendorRequest(
    AuthSession session, {
    required String requestId,
    required String status,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _apiClient.respondToVendorRequest(
        requestId: requestId,
        accessToken: session.tokens.accessToken,
        status: status,
      );
      _successMessage = status == 'accepted'
          ? 'Vendor request accepted.'
          : 'Vendor request declined.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> markVendorRequestBooked(
    AuthSession session, {
    required String requestId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _apiClient.markVendorRequestBooked(
        requestId: requestId,
        accessToken: session.tokens.accessToken,
      );
      _successMessage = 'Vendor request marked as booked.';
      await load(session);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
