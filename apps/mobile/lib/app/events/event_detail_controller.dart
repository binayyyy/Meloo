import 'package:flutter/foundation.dart';
import '../payments/payment_models.dart';
import '../payments/payments_api_client.dart';
import '../session/auth_models.dart';
import 'event_models.dart';
import 'events_api_client.dart';

class EventDetailController extends ChangeNotifier {
  EventDetailController({
    EventsApiClient? apiClient,
    PaymentsApiClient? paymentsApiClient,
  })  : _apiClient = apiClient ?? EventsApiClient(),
        _paymentsApiClient = paymentsApiClient ?? PaymentsApiClient();

  final EventsApiClient _apiClient;
  final PaymentsApiClient _paymentsApiClient;

  EventModel? _event;
  List<TicketTypeModel> _ticketTypes = const [];
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  EventModel? get event => _event;
  List<TicketTypeModel> get ticketTypes => _ticketTypes;
  bool get isFavorite => _isFavorite;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load({
    required AuthSession session,
    required String eventId,
    required bool manageMode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (manageMode) {
        final results = await Future.wait([
          _apiClient.fetchManageEvent(
            eventId: eventId,
            accessToken: session.tokens.accessToken,
          ),
          _apiClient.fetchManageTicketTypes(
            eventId: eventId,
            accessToken: session.tokens.accessToken,
          ),
        ]);
        _event = results[0] as EventModel;
        _ticketTypes = results[1] as List<TicketTypeModel>;
      } else {
        final results = await Future.wait([
          _apiClient.fetchPublicEvent(eventId),
          _apiClient.fetchPublicTicketTypes(eventId),
          _apiClient.fetchFavoriteEvents(accessToken: session.tokens.accessToken),
        ]);
        _event = results[0] as EventModel;
        _ticketTypes = results[1] as List<TicketTypeModel>;
        final favorites = results[2] as List<EventModel>;
        _isFavorite = favorites.any((event) => event.id == eventId);
        await _apiClient.recordEventView(
          eventId: eventId,
          accessToken: session.tokens.accessToken,
        );
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketTypeModel> createTicketType({
    required AuthSession session,
    required String eventId,
    required TicketTypeCreateRequest request,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await _apiClient.createTicketType(
        eventId: eventId,
        accessToken: session.tokens.accessToken,
        request: request,
      );
      _ticketTypes = [..._ticketTypes, created];
      _successMessage = 'Ticket type created.';
      return created;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<RegistrationModel> register({
    required AuthSession session,
    required String eventId,
    required String ticketTypeId,
    required int quantity,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final registration = await _apiClient.createRegistration(
        eventId: eventId,
        accessToken: session.tokens.accessToken,
        ticketTypeId: ticketTypeId,
        quantity: quantity,
      );
      _ticketTypes = _ticketTypes
          .map(
            (ticket) => ticket.id == ticketTypeId
                ? TicketTypeModel(
                    id: ticket.id,
                    eventId: ticket.eventId,
                    name: ticket.name,
                    price: ticket.price,
                    quantity: ticket.quantity,
                    remaining: ticket.remaining - quantity,
                    saleStartAt: ticket.saleStartAt,
                    saleEndAt: ticket.saleEndAt,
                  )
                : ticket,
          )
          .toList(growable: false);
      _successMessage = 'Registration confirmed.';
      return registration;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<PaymentCheckoutModel> purchasePaidTicket({
    required AuthSession session,
    required String eventId,
    required String ticketTypeId,
    required int quantity,
    String? returnUrl,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final initiated = await _paymentsApiClient.createCheckoutSession(
        eventId: eventId,
        accessToken: session.tokens.accessToken,
        ticketTypeId: ticketTypeId,
        quantity: quantity,
        returnUrl: returnUrl,
      );

      _successMessage = initiated.requiresRedirect
          ? 'Stripe checkout session created.'
          : 'Payment session created.';
      return initiated;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> toggleFavorite({
    required AuthSession session,
    required String eventId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _isFavorite = _isFavorite
          ? await _apiClient.unfavoriteEvent(
              eventId: eventId,
              accessToken: session.tokens.accessToken,
            )
          : await _apiClient.favoriteEvent(
              eventId: eventId,
              accessToken: session.tokens.accessToken,
            );
      _successMessage = _isFavorite
          ? 'Event saved to favorites.'
          : 'Event removed from favorites.';
      return _isFavorite;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
