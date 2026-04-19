import 'package:flutter/foundation.dart';
import '../session/auth_models.dart';
import 'payment_models.dart';
import 'payments_api_client.dart';

class PaymentsController extends ChangeNotifier {
  PaymentsController({PaymentsApiClient? apiClient})
      : _apiClient = apiClient ?? PaymentsApiClient();

  final PaymentsApiClient _apiClient;

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<PaymentCheckoutModel> _payments = const [];
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<PaymentCheckoutModel> get payments => _payments;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _apiClient.fetchMyPayments(
        accessToken: session.tokens.accessToken,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaymentCheckoutModel> verifyCheckoutSession(
    AuthSession session,
    String checkoutSessionId,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final checkout = await _apiClient.verifyStripeCheckoutSession(
        checkoutSessionId: checkoutSessionId,
        accessToken: session.tokens.accessToken,
      );
      _payments = [
        checkout,
        ..._payments.where(
          (existing) => existing.payment.id != checkout.payment.id,
        ),
      ];
      _successMessage = checkout.payment.status == 'paid'
          ? 'Payment verified and booking confirmed.'
          : 'Payment session checked.';
      return checkout;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void addPayment(PaymentCheckoutModel checkout) {
    _payments = [checkout, ..._payments];
    _successMessage = checkout.payment.status == 'paid'
        ? 'Payment completed.'
        : 'Checkout session created.';
    notifyListeners();
  }
}
