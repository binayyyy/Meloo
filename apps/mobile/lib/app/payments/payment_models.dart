import '../events/event_models.dart';
import '../core/json_value.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.type,
    required this.requesterId,
    required this.targetUserId,
    required this.eventId,
    required this.registrationId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String requesterId;
  final String targetUserId;
  final String eventId;
  final String registrationId;
  final String status;
  final String amount;
  final String currency;
  final DateTime createdAt;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: stringValue(json['id']),
      type: stringValue(json['type']),
      requesterId: stringValue(json['requesterId']),
      targetUserId: stringValue(json['targetUserId']),
      eventId: stringValue(json['eventId']),
      registrationId: stringValue(json['registrationId']),
      status: stringValue(json['status']),
      amount: stringValue(json['amount']),
      currency: stringValue(json['currency']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.payerId,
    required this.provider,
    required this.providerRef,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String payerId;
  final String provider;
  final String providerRef;
  final String amount;
  final String currency;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: stringValue(json['id']),
      bookingId: stringValue(json['bookingId']),
      payerId: stringValue(json['payerId']),
      provider: stringValue(json['provider']),
      providerRef: stringValue(json['providerRef']),
      amount: stringValue(json['amount']),
      currency: stringValue(json['currency']),
      status: stringValue(json['status']),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(stringValue(json['paidAt'])).toLocal(),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
    );
  }
}

class PaymentCheckoutModel {
  const PaymentCheckoutModel({
    required this.booking,
    required this.payment,
    required this.registration,
    required this.checkoutSessionId,
    required this.checkoutUrl,
  });

  final BookingModel booking;
  final PaymentModel payment;
  final RegistrationModel registration;
  final String? checkoutSessionId;
  final String? checkoutUrl;

  bool get requiresRedirect =>
      checkoutUrl != null &&
      checkoutUrl!.isNotEmpty &&
      payment.status == 'initiated';

  factory PaymentCheckoutModel.fromJson(Map<String, dynamic> json) {
    return PaymentCheckoutModel(
      booking: BookingModel.fromJson(
        Map<String, dynamic>.from(json['booking'] as Map),
      ),
      payment: PaymentModel.fromJson(
        Map<String, dynamic>.from(json['payment'] as Map),
      ),
      registration: RegistrationModel.fromJson(
        Map<String, dynamic>.from(json['registration'] as Map),
      ),
      checkoutSessionId: nullableStringValue(json['checkoutSessionId']),
      checkoutUrl: nullableStringValue(json['checkoutUrl']),
    );
  }
}
