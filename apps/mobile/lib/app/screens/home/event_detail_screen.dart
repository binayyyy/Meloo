import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../events/event_detail_controller.dart';
import '../../events/event_models.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../session/auth_scope.dart';
import 'widgets/create_ticket_type_sheet.dart';
import 'widgets/register_ticket_sheet.dart';

class EventDetailScreenArgs {
  const EventDetailScreenArgs({
    required this.eventId,
    required this.manageMode,
  });

  final String eventId;
  final bool manageMode;
}

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    required this.args,
    super.key,
  });

  final EventDetailScreenArgs args;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventDetailController _controller = EventDetailController();
  String? _loadedToken;
  bool _didPresentDemoSheet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context).session;
    final accessToken = session?.tokens.accessToken;
    if (session != null &&
        accessToken != null &&
        accessToken != _loadedToken) {
      _loadedToken = accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.load(
            session: session,
            eventId: widget.args.eventId,
            manageMode: widget.args.manageMode,
          ).then((_) => _maybePresentDemoSheet(session));
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateTicketSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CreateTicketTypeSheet(
              isSubmitting: _controller.isSubmitting,
              onSubmit: (request) async {
                try {
                  await _controller.createTicketType(
                    session: session,
                    eventId: widget.args.eventId,
                    request: request,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text(_controller.successMessage ?? 'Ticket created'),
                      ),
                    );
                  }
                } on ApiException {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.errorMessage ?? 'Ticket creation failed',
                        ),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openRegistrationSheet(
    AuthSession session,
    TicketTypeModel ticketType,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return RegisterTicketSheet(
              ticketType: ticketType,
              isSubmitting: _controller.isSubmitting,
              onSubmit: (quantity) async {
                try {
                  if (ticketType.isFree) {
                    final registration = await _controller.register(
                      session: session,
                      eventId: widget.args.eventId,
                      ticketTypeId: ticketType.id,
                      quantity: quantity,
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            _controller.successMessage ??
                                'Registered for ${registration.event.title}',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  final checkout = await _controller.purchasePaidTicket(
                    session: session,
                    eventId: widget.args.eventId,
                    ticketTypeId: ticketType.id,
                    quantity: quantity,
                    returnUrl: _buildCheckoutReturnUrl(),
                  );
                  if (mounted) {
                    if (checkout.checkoutUrl != null &&
                        checkout.checkoutUrl!.isNotEmpty) {
                      final launched = await launchUrlString(
                        checkout.checkoutUrl!,
                        mode: LaunchMode.platformDefault,
                      );
                      if (!launched && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Unable to open Stripe checkout'),
                          ),
                        );
                      }
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.successMessage ??
                              'Stripe checkout started for ${checkout.registration.event.title}',
                        ),
                      ),
                    );
                  }
                } on ApiException {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.errorMessage ?? 'Registration failed',
                        ),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  String _buildCheckoutReturnUrl() {
    final current = Uri.base;
    return current.replace(
      queryParameters: {
        if (widget.args.eventId.isNotEmpty) 'eventId': widget.args.eventId,
      },
    ).toString();
  }

  Future<void> _maybePresentDemoSheet(AuthSession session) async {
    if (_didPresentDemoSheet) {
      return;
    }

    final demoSheet = Uri.base.queryParameters['demo_sheet'];
    if (demoSheet == null || demoSheet.isEmpty) {
      return;
    }

    _didPresentDemoSheet = true;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }

    switch (demoSheet) {
      case 'create-ticket':
        if (widget.args.manageMode) {
          await _openCreateTicketSheet(session);
        }
        return;
      case 'register-ticket':
        final ticketKind = Uri.base.queryParameters['ticket_kind'];
        TicketTypeModel? selectedTicket;
        if (ticketKind == 'paid') {
          selectedTicket = _firstTicketMatching((item) => !item.isFree);
        } else if (ticketKind == 'free') {
          selectedTicket = _firstTicketMatching((item) => item.isFree);
        }
        selectedTicket ??=
            _controller.ticketTypes.isNotEmpty ? _controller.ticketTypes.first : null;
        if (!widget.args.manageMode && selectedTicket != null) {
          await _openRegistrationSheet(session, selectedTicket);
        }
        return;
      default:
        return;
    }
  }

  TicketTypeModel? _firstTicketMatching(bool Function(TicketTypeModel item) test) {
    for (final ticket in _controller.ticketTypes) {
      if (test(ticket)) {
        return ticket;
      }
    }
    return null;
  }

  Future<void> _openExternalMap(EventModel event) async {
    final lat = event.latitude;
    final lng = event.longitude;
    final query = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent('${event.venue}, ${event.city}');
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    final launched = await launchUrlString(
      url,
      mode: LaunchMode.platformDefault,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3EBDE),
          appBar: AppBar(
            title: const Text('Event detail'),
            actions: widget.args.manageMode
                ? null
                : [
                    IconButton(
                      onPressed: _controller.isSubmitting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await _controller.toggleFavorite(
                                  session: session,
                                  eventId: widget.args.eventId,
                                );
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _controller.successMessage ??
                                            'Favorite state updated',
                                      ),
                                    ),
                                  );
                                }
                              } on ApiException {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _controller.errorMessage ??
                                            'Unable to update favorite',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: Icon(
                        _controller.isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                    ),
                  ],
          ),
          floatingActionButton: widget.args.manageMode
              ? FloatingActionButton.extended(
                  onPressed: () => _openCreateTicketSheet(session),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Add ticket'),
                )
              : null,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF9F4EC),
                  Color(0xFFF1E8DB),
                ],
              ),
            ),
            child: _buildBody(session),
          ),
        );
      },
    );
  }

  Widget _buildBody(AuthSession session) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
          if (_controller.isLoading && _controller.event == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = _controller.event;
          if (event == null) {
            return Center(
              child: Text(
                _controller.errorMessage ?? 'Unable to load event',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(
              session: session,
              eventId: widget.args.eventId,
              manageMode: widget.args.manageMode,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _DetailHero(
                  event: event,
                  manageMode: widget.args.manageMode,
                  ticketCount: _controller.ticketTypes.length,
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: 'At a glance',
                  icon: Icons.place_rounded,
                  accent: const Color(0xFF145B52),
                  child: _InfoRail(
                    items: [
                      _InfoRailItem(
                        label: 'Window',
                        value: _formatCompactWindow(event.startAt, event.endAt),
                        icon: Icons.schedule_rounded,
                      ),
                      _InfoRailItem(
                        label: 'Venue',
                        value: '${event.venue}, ${event.city}',
                        icon: Icons.location_city_rounded,
                      ),
                      _InfoRailItem(
                        label: 'Tickets',
                        value: _controller.ticketTypes.isEmpty
                            ? 'Setup needed'
                            : '${_controller.ticketTypes.length} live types',
                        icon: Icons.confirmation_number_rounded,
                      ),
                    ],
                  ),
                ),
                if (event.latitude != null && event.longitude != null) ...[
                  const SizedBox(height: 16),
                  _Panel(
                    title: 'Map',
                    icon: Icons.map_rounded,
                    accent: const Color(0xFF145B52),
                    child: _EventMapCard(
                      event: event,
                      onOpenMaps: () => _openExternalMap(event),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _Panel(
                  title: 'Event story',
                  icon: Icons.menu_book_rounded,
                  accent: const Color(0xFF145B52),
                  child: Text(
                    event.description,
                    style: const TextStyle(
                      color: Color(0xFF5F645F),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: widget.args.manageMode ? 'Operations snapshot' : 'What to expect',
                  icon: widget.args.manageMode
                      ? Icons.dashboard_customize_rounded
                      : Icons.auto_awesome_rounded,
                  accent: widget.args.manageMode
                      ? const Color(0xFF145B52)
                      : const Color(0xFFBA7B2F),
                  child: _ExpectationBoard(
                    manageMode: widget.args.manageMode,
                    event: event,
                    ticketTypes: _controller.ticketTypes,
                  ),
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: widget.args.manageMode ? 'Ticket management' : 'Tickets',
                  icon: Icons.local_activity_rounded,
                  accent: widget.args.manageMode
                      ? const Color(0xFF145B52)
                      : const Color(0xFFBA7B2F),
                  child: _controller.ticketTypes.isEmpty
                      ? Text(
                          widget.args.manageMode
                              ? 'No ticket types yet. Add at least one ticket to open attendee registration.'
                              : 'No tickets are available yet.',
                          style: const TextStyle(
                            color: Color(0xFF5F645F),
                            height: 1.5,
                          ),
                        )
                      : Column(
                          children: _controller.ticketTypes
                              .map(
                                (ticket) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TicketCard(
                                    ticket: ticket,
                                    manageMode: widget.args.manageMode,
                                    attendeeMode:
                                        session.user.role == UserRole.attendee &&
                                            !widget.args.manageMode,
                                    isSubmitting: _controller.isSubmitting,
                                    onRegister: ticket.isFree
                                        ? () => _openRegistrationSheet(
                                              session,
                                              ticket,
                                            )
                                        : null,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
            ),
          );
        },
      );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.event,
    required this.manageMode,
    required this.ticketCount,
  });

  final EventModel event;
  final bool manageMode;
  final int ticketCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24163E3A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      event.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.expand(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF132A4A),
                                  Color(0xFF1A4C74),
                                  Color(0xFF8A6A37),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.expand(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF132A4A),
                              Color(0xFF1A4C74),
                              Color(0xFF8A6A37),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF10223F).withValues(alpha: 0.24),
                      const Color(0xFF10223F).withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${event.venue}, ${event.city}',
                    style: const TextStyle(
                      color: Color(0xFFE6F0EE),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetaBadge(label: _formatWindow(event)),
                      _MetaBadge(label: '${event.status} / ${event.visibility}'),
                      _MetaBadge(
                        label: manageMode
                            ? '$ticketCount ticket lane${ticketCount == 1 ? '' : 's'}'
                            : 'Stripe-ready checkout',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWindow(EventModel event) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(event.startAt.day)}/${two(event.startAt.month)}/${event.startAt.year} ${two(event.startAt.hour)}:${two(event.startAt.minute)}';
  }
}

class _EventMapCard extends StatelessWidget {
  const _EventMapCard({
    required this.event,
    required this.onOpenMaps,
  });

  final EventModel event;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) {
      return Text(
        '${event.venue}, ${event.city}',
        style: const TextStyle(
          color: Color(0xFF5F645F),
          height: 1.5,
        ),
      );
    }

    final point = LatLng(latitude, longitude);
    final radiusKm = event.vendorMatchRadiusKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 12.8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'local.meloo.app',
                ),
                if (radiusKm != null && radiusKm > 0)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: point,
                        radius: radiusKm * 1000,
                        useRadiusInMeter: true,
                        color: const Color(0x26145B52),
                        borderColor: const Color(0xFF145B52),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF132A4A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x30132A4A),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetaBadge(label: event.venue),
            _MetaBadge(label: event.city),
            _MetaBadge(
              label:
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            ),
            if (radiusKm != null && radiusKm > 0)
              _MetaBadge(label: '${radiusKm.toStringAsFixed(0)} km match'),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onOpenMaps,
          icon: const Icon(Icons.near_me_rounded),
          label: const Text('Open in maps'),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.icon = Icons.apps_rounded,
    this.accent = const Color(0xFF145B52),
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF8),
            Color(0xFFF4ECE0),
          ],
        ),
        border: Border.all(color: const Color(0xFFD8D1C2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101A130C),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRailItem {
  const _InfoRailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _InfoRail extends StatelessWidget {
  const _InfoRail({required this.items});

  final List<_InfoRailItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 206,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0D9CB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3F0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: const Color(0xFF145B52)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF145B52),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ExpectationBoard extends StatelessWidget {
  const _ExpectationBoard({
    required this.manageMode,
    required this.event,
    required this.ticketTypes,
  });

  final bool manageMode;
  final EventModel event;
  final List<TicketTypeModel> ticketTypes;

  @override
  Widget build(BuildContext context) {
    final hasFree = ticketTypes.any((ticket) => ticket.isFree);
    final hasPaid = ticketTypes.any((ticket) => !ticket.isFree);

    final points = manageMode
        ? <String>[
            'This event is ${event.status} and currently ${event.visibility}.',
            hasFree
                ? 'A free-access lane is already configured for discovery or community entry.'
                : 'No free-access lane is configured yet.',
            hasPaid
                ? 'Paid access is active through Stripe checkout.'
                : 'No paid checkout lane is active yet.',
            'Manage quantity and sale windows below to shape conversion before launch.',
          ]
        : <String>[
            'This event is framed around ${event.category.name.toLowerCase()} energy and venue-led experience.',
            hasFree
                ? 'At least one ticket lane allows instant free confirmation.'
                : 'Visible ticket lanes currently route through paid access.',
            hasPaid
                ? 'Paid booking continues through Stripe checkout after ticket selection.'
                : 'You can enter without a payment step on the current ticket mix.',
            'Booking updates, support replies, and reminders will appear in your inbox.',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.radio_button_checked_rounded,
                      size: 12,
                      color: Color(0xFF145B52),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFF5F645F),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.manageMode,
    required this.attendeeMode,
    required this.isSubmitting,
    this.onRegister,
  });

  final TicketTypeModel ticket;
  final bool manageMode;
  final bool attendeeMode;
  final bool isSubmitting;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F2E8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: ticket.isFree
                  ? const Color(0xFF145B52)
                  : const Color(0xFFBA7B2F),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ticket.isFree ? 'Free' : ticket.price,
                style: TextStyle(
                  color: ticket.isFree
                      ? const Color(0xFF0E6B5C)
                      : const Color(0xFF9A5F1D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.isFree
                ? 'Free entry with instant confirmation'
                : 'Stripe checkout in test mode for paid access',
            style: const TextStyle(
              color: Color(0xFF5F645F),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaBadge(label: 'Remaining ${ticket.remaining}/${ticket.quantity}'),
              _MetaBadge(label: 'Sales close ${ticket.saleEndAt.day}/${ticket.saleEndAt.month}'),
            ],
          ),
          if (manageMode) ...[
            const SizedBox(height: 12),
            Text(
              ticket.isFree
                  ? 'Free ticket ready for booking'
                  : 'Paid checkout is active through Stripe Checkout',
              style: const TextStyle(color: Color(0xFF5F645F)),
            ),
          ],
          if (attendeeMode) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    isSubmitting || ticket.remaining == 0 || onRegister == null
                        ? null
                        : onRegister,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    ticket.isFree ? 'Register now' : 'Continue to checkout',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

String _formatCompactWindow(DateTime start, DateTime end) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(start.day)}/${two(start.month)} ${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
}
