import 'package:flutter/material.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_api_client.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_scope.dart';
import '../../router.dart';
import 'event_detail_screen.dart';

class PaymentResultScreenArgs {
  const PaymentResultScreenArgs({
    required this.checkoutSessionId,
    required this.eventId,
    required this.paymentResult,
  });

  final String checkoutSessionId;
  final String? eventId;
  final String paymentResult;
}

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    required this.args,
    super.key,
  });

  final PaymentResultScreenArgs args;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  final PaymentsApiClient _paymentsApiClient = PaymentsApiClient();
  PaymentCheckoutModel? _checkout;
  String? _errorMessage;
  bool _isLoading = true;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = AuthScope.of(context).session;
    if (session == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You need to be signed in to verify this payment.';
      });
      return;
    }

    if (widget.args.paymentResult != 'success') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final checkout = await _paymentsApiClient.verifyStripeCheckoutSession(
        checkoutSessionId: widget.args.checkoutSessionId,
        accessToken: session.tokens.accessToken,
      );
      if (mounted) {
        setState(() {
          _checkout = checkout;
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wasCancelled = widget.args.paymentResult == 'cancel';
    final checkout = _checkout;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment status')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7F9FA),
              Color(0xFFF0F4F7),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCE3E8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10101828),
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 18),
                          Text('Verifying your Stripe payment...'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: (_errorMessage != null
                                      ? const Color(0xFFAF3D31)
                                      : wasCancelled
                                          ? const Color(0xFF7A6A52)
                                          : const Color(0xFF2F6B57))
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _errorMessage != null
                                  ? Icons.error_outline_rounded
                                  : wasCancelled
                                      ? Icons.payments_outlined
                                      : Icons.check_circle_outline_rounded,
                              size: 24,
                              color: _errorMessage != null
                                  ? const Color(0xFFAF3D31)
                                  : wasCancelled
                                      ? const Color(0xFF7A6A52)
                                      : const Color(0xFF2F6B57),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage != null
                                ? 'Payment verification failed'
                                : wasCancelled
                                    ? 'Stripe checkout was cancelled'
                                    : checkout?.payment.status == 'paid'
                                        ? 'Payment confirmed'
                                        : 'Payment is still pending',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ??
                                (wasCancelled
                                    ? 'You can return to the event and try checkout again whenever you are ready.'
                                    : checkout?.payment.status == 'paid'
                                        ? 'Your booking is confirmed and the event is now available in your payment history.'
                                        : 'Stripe did not report a paid session yet. If you just completed checkout, wait a moment and retry.'),
                            style: const TextStyle(
                              color: Color(0xFF66717D),
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                          if (checkout != null) ...[
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _pill('Status ${checkout.payment.status}'),
                                _pill(
                                  '${checkout.payment.currency} ${checkout.payment.amount}',
                                ),
                                _pill(checkout.registration.ticketType.name),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  if (widget.args.eventId != null) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRouter.eventDetail,
                                      (route) => route.settings.name == AppRouter.home,
                                      arguments: EventDetailScreenArgs(
                                        eventId: widget.args.eventId!,
                                        manageMode: false,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRouter.home,
                                    (route) => false,
                                  );
                                },
                                child: Text(
                                  widget.args.eventId != null
                                      ? 'Back to event'
                                      : 'Back to home',
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                  AppRouter.home,
                                  (route) => false,
                                ),
                                child: const Text('Dashboard'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE3E8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
