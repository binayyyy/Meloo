import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../ai/ai_controller.dart';
import '../../ai/ai_models.dart';
import '../../chat/chat_controller.dart';
import '../../chat/chat_models.dart';
import '../../events/event_models.dart';
import '../../events/events_controller.dart';
import '../../notifications/notifications_controller.dart';
import '../../notifications/notification_models.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_controller.dart';
import '../../support/support_controller.dart';
import '../../support/support_models.dart';
import '../../sponsors/sponsor_models.dart';
import '../../sponsors/sponsors_controller.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../session/auth_scope.dart';
import '../../vendors/vendor_models.dart';
import '../../vendors/vendors_controller.dart';
import '../../widgets/brand_lockup.dart';
import '../../widgets/workflow_page_scaffold.dart';
import '../../router.dart';
import '../chat/conversation_screen.dart';
import 'event_detail_screen.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/create_sponsorship_opportunity_sheet.dart';
import 'widgets/create_support_ticket_sheet.dart';
import 'widgets/create_vendor_request_sheet.dart';
import 'widgets/create_vendor_package_sheet.dart';
import 'widgets/create_vendor_service_sheet.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/express_sponsorship_interest_sheet.dart';
import 'widgets/planning_assistant_sheet.dart';
import 'widgets/sponsor_profile_sheet.dart';
import 'widgets/vendor_profile_sheet.dart';

class RoleHomeScreen extends StatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  State<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  final AiController _aiController = AiController();
  final ChatController _chatController = ChatController();
  final EventsController _eventsController = EventsController();
  final NotificationsController _notificationsController =
      NotificationsController();
  final PaymentsController _paymentsController = PaymentsController();
  final SupportController _supportController = SupportController();
  final SponsorsController _sponsorsController = SponsorsController();
  final VendorsController _vendorsController = VendorsController();
  int _selectedTab = 0;
  String _eventSearch = '';
  String? _selectedCategorySlug;
  String? _loadedForAccessToken;
  bool _didPresentEntrySheet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context).session;
    final accessToken = session?.tokens.accessToken;

    if (session != null &&
        accessToken != null &&
        accessToken != _loadedForAccessToken) {
      _loadedForAccessToken = accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAll(session).then((_) => _maybePresentEntrySheet(session));
        }
      });
    }
  }

  @override
  void dispose() {
    _aiController.dispose();
    _chatController.dispose();
    _eventsController.dispose();
    _notificationsController.dispose();
    _paymentsController.dispose();
    _supportController.dispose();
    _sponsorsController.dispose();
    _vendorsController.dispose();
    super.dispose();
  }

  Future<void> _loadAll(AuthSession session) async {
    await _runSafe(() => _eventsController.load(session));

    await Future.wait([
      _runSafe(() => _chatController.load(session)),
      _runSafe(() => _notificationsController.load(session)),
      if (session.user.role == UserRole.attendee)
        _runSafe(() => _paymentsController.load(session)),
      _runSafe(() => _supportController.load(session)),
      _runSafe(() => _sponsorsController.load(session)),
    ]);

    final organizerFocusEvent = _eventsController.myEvents.isNotEmpty
        ? _eventsController.myEvents.first
        : null;
    await _runSafe(
      () => _vendorsController.load(session, focusEvent: organizerFocusEvent),
    );
    await _runSafe(
      () => _aiController.load(
        session,
        organizerEventId: organizerFocusEvent?.id,
      ),
    );
  }

  Future<void> _runSafe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
    }
  }

  Future<void> _maybePresentEntrySheet(AuthSession session) async {
    if (_didPresentEntrySheet) {
      return;
    }

    final entrySheet = Uri.base.queryParameters['entry_sheet'];
    if (entrySheet == null || entrySheet.isEmpty) {
      return;
    }

    _didPresentEntrySheet = true;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }

    switch (entrySheet) {
      case 'create-event':
        await _openCreateEventSheet(session);
        return;
      case 'vendor-profile':
        await _openVendorProfileSheet(session);
        return;
      case 'vendor-service':
        await _openVendorServiceSheet(session);
        return;
      case 'vendor-package':
        await _openVendorPackageSheet(session);
        return;
      case 'vendor-request':
        final vendor = _vendorsController.publicVendors.isNotEmpty
            ? _vendorsController.publicVendors.first
            : null;
        if (vendor != null) {
          await _openVendorRequestSheet(session, vendor);
        }
        return;
      case 'support-ticket':
        await _openCreateSupportTicketSheet(session);
        return;
      case 'planning-assistant':
        await _openPlanningAssistantSheet(session);
        return;
      case 'sponsor-profile':
        await _openSponsorProfileSheet(session);
        return;
      case 'sponsor-opportunity':
        await _openCreateOpportunitySheet(session);
        return;
      case 'sponsor-interest':
        final opportunity = _sponsorsController.openOpportunities.isNotEmpty
            ? _sponsorsController.openOpportunities.first
            : null;
        if (opportunity != null) {
          await _openExpressInterestSheet(session, opportunity);
        }
        return;
      case 'opportunity-interests':
        final opportunity = _sponsorsController.myOpportunities.isNotEmpty
            ? _sponsorsController.myOpportunities.first
            : null;
        if (opportunity != null) {
          await _openOpportunityInterestsSheet(session, opportunity);
        }
        return;
      case 'conversation':
        final conversation = _chatController.conversations.isNotEmpty
            ? _chatController.conversations.first
            : null;
        if (conversation != null) {
          await _openConversationSheet(session, conversation);
        }
        return;
      default:
        return;
    }
  }

  Future<void> _openCreateEventSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);

    if (_eventsController.categories.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Event categories are still loading')),
      );
      return;
    }

    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _eventsController,
        builder: (context, _) {
          return CreateEventSheet(
            accessToken: session.tokens.accessToken,
            categories: _eventsController.categories,
            isSubmitting: _eventsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _eventsController.createEvent(session, request);
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      _eventsController.successMessage ?? 'Event created',
                    ),
                  ),
                );
              } on ApiException {
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      _eventsController.errorMessage ?? 'Event creation failed',
                    ),
                  ),
                );
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openVendorProfileSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _vendorsController,
        builder: (context, _) {
          return VendorProfileSheet(
            accessToken: session.tokens.accessToken,
            initialProfile: _vendorsController.myVendorProfile,
            isSubmitting: _vendorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _vendorsController.upsertMyVendorProfile(session, request);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.successMessage ?? 'Profile updated',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.errorMessage ??
                            'Profile update failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openEditProfileSheet(AuthSession session) async {
    final authController = AuthScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          final currentUser = authController.session?.user ?? session.user;
          return EditProfileSheet(
            accessToken: session.tokens.accessToken,
            user: currentUser,
            onSubmit: (profile, settings) async {
              await authController.updateMe(
                profile: profile,
                settings: settings,
              );
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openVendorServiceSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _vendorsController,
        builder: (context, _) {
          return CreateVendorServiceSheet(
            isSubmitting: _vendorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _vendorsController.createVendorService(session, request);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.successMessage ?? 'Service added',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.errorMessage ??
                            'Service creation failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openVendorPackageSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _vendorsController,
        builder: (context, _) {
          return CreateVendorPackageSheet(
            isSubmitting: _vendorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _vendorsController.createVendorPackage(session, request);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.successMessage ?? 'Package added',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.errorMessage ??
                            'Package creation failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openVendorRequestSheet(
    AuthSession session,
    VendorProfileModel vendor,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_eventsController.myEvents.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Create an event before contacting vendors')),
      );
      return;
    }

    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _vendorsController,
        builder: (context, _) {
          return CreateVendorRequestSheet(
            vendor: vendor,
            events: _eventsController.myEvents,
            isSubmitting: _vendorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _vendorsController.createVendorRequest(
                  session,
                  vendorId: vendor.id,
                  request: request,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.successMessage ?? 'Vendor request sent',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _vendorsController.errorMessage ??
                            'Vendor request failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openCreateSupportTicketSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _supportController,
        builder: (context, _) {
          return CreateSupportTicketSheet(
            isSubmitting: _supportController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _supportController.createTicket(session, request);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _supportController.successMessage ?? 'Ticket created',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _supportController.errorMessage ??
                            'Ticket creation failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openPlanningAssistantSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _aiController,
        builder: (context, _) {
          return PlanningAssistantSheet(
            events: _eventsController.myEvents,
            isSubmitting: _aiController.isPlanning,
            onSubmit: (request) async {
              try {
                await _aiController.generatePlanningBrief(
                  session,
                  eventId: request.eventId,
                  expectedAttendees: request.expectedAttendees,
                  budget: request.budget,
                  planningGoal: request.planningGoal,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Planning brief generated'),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _aiController.errorMessage ??
                            'Unable to generate planning brief',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openSponsorProfileSheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _sponsorsController,
        builder: (context, _) {
          return SponsorProfileSheet(
            accessToken: session.tokens.accessToken,
            initialProfile: _sponsorsController.mySponsorProfile,
            isSubmitting: _sponsorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _sponsorsController.upsertMySponsorProfile(
                  session,
                  request,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.successMessage ?? 'Profile updated',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.errorMessage ??
                            'Profile update failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openCreateOpportunitySheet(AuthSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_eventsController.myEvents.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Create an event before adding sponsors')),
      );
      return;
    }

    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _sponsorsController,
        builder: (context, _) {
          return CreateSponsorshipOpportunitySheet(
            events: _eventsController.myEvents,
            isSubmitting: _sponsorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _sponsorsController.createOpportunity(session, request);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.successMessage ?? 'Opportunity created',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.errorMessage ??
                            'Opportunity creation failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openExpressInterestSheet(
    AuthSession session,
    SponsorshipOpportunityModel opportunity,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await _pushWorkflowPage((context) {
      return AnimatedBuilder(
        animation: _sponsorsController,
        builder: (context, _) {
          return ExpressSponsorshipInterestSheet(
            opportunity: opportunity,
            isSubmitting: _sponsorsController.isSubmitting,
            onSubmit: (request) async {
              try {
                await _sponsorsController.expressInterest(
                  session,
                  opportunity.id,
                  request,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.successMessage ?? 'Interest submitted',
                      ),
                    ),
                  );
                }
              } on ApiException {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        _sponsorsController.errorMessage ??
                            'Interest submission failed',
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openOpportunityInterestsSheet(
    AuthSession session,
    SponsorshipOpportunityModel opportunity,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final interests = await _sponsorsController.fetchOpportunityInterests(
        session,
        opportunity.id,
      );
      if (!mounted) {
        return;
      }
      await _pushWorkflowPage((context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: _OpportunityInterestsSheet(
            opportunity: opportunity,
            interests: interests,
            onStartChat: (interest) => _openDirectConversation(
              session,
              participantUserId: interest.sponsor.userId,
              participantLabel: interest.sponsor.companyName,
            ),
          ),
        );
      });
    } on ApiException {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _sponsorsController.errorMessage ?? 'Failed to load interests',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openDirectConversation(
    AuthSession session, {
    required String participantUserId,
    required String participantLabel,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversation = await _chatController.createDirectConversation(
        session,
        participantUserId,
      );
      if (!mounted) {
        return;
      }
      await _openConversationSheet(
        session,
        conversation,
        title: participantLabel,
      );
    } on ApiException {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _chatController.errorMessage ?? 'Failed to open conversation',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openConversationSheet(
    AuthSession session,
    ConversationModel conversation, {
    String? title,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _chatController.openConversation(session, conversation);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return AnimatedBuilder(
              animation: _chatController,
              builder: (context, _) {
                return ConversationScreen(
                  title: title ??
                      _chatController.counterpartFor(conversation)?.displayName ??
                      'Conversation',
                  accessToken: session.tokens.accessToken,
                  messages: _chatController.activeMessages,
                  currentUserId: session.user.id,
                  currentUserRole: session.user.role,
                  aiAssistEnabled: session.user.settings?.aiAssistEnabled ?? false,
                  isLoading: _chatController.isOpeningConversation,
                  isSending: _chatController.isSending,
                  isDrafting: _chatController.isDrafting,
                  onSend: _chatController.sendMessage,
                  onSendAttachment: _chatController.sendAttachment,
                  onGenerateDraft: ({
                    required intent,
                    prompt,
                  }) =>
                      _chatController.generateAssistantDraft(
                    session,
                    intent: intent,
                    prompt: prompt,
                  ),
                );
              },
            );
          },
        ),
      );
      if (mounted) {
        await _chatController.load(session);
      }
    } on ApiException {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _chatController.errorMessage ?? 'Failed to load conversation',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);
    final session = authController.session;
    final user = session?.user;

    if (user == null || session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navigation = _navigationForRole(user.role)[_selectedTab];
    final heroMetrics = _summaryMetricsForSelectedTab(user.role);
    final palette = _paletteForRole(user.role);

    return Scaffold(
      backgroundColor: palette.canvasTop,
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 18,
        backgroundColor: palette.canvasTop,
        title: Row(
          children: [
            MelooBrandMark(
              size: 32,
              padding: 7,
              borderRadius: 11,
              backgroundColor: palette.surface,
              showBorder: true,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  navigation.headline,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  navigation.label,
                  style: TextStyle(
                    color: palette.support,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                _workspaceLabelForRole(user.role),
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Badge(
              isLabelVisible: _notificationsController.unreadCount > 0,
              label: Text(_notificationsController.unreadCount.toString()),
              child: IconButton(
                onPressed: () => setState(() => _selectedTab = 2),
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Inbox',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: authController.signOut,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(session, user.role),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: palette.surface,
        indicatorColor: palette.accent.withValues(alpha: 0.12),
        destinations: _navigationForRole(user.role)
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: item.label,
              ),
            )
            .toList(growable: false),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _aiController,
          _chatController,
          _eventsController,
          _notificationsController,
          _paymentsController,
          _supportController,
          _sponsorsController,
          _vendorsController,
        ]),
        builder: (context, _) {
          final isBusy =
              (_eventsController.isLoading || _sponsorsController.isLoading) &&
                  _loadedForAccessToken == session.tokens.accessToken &&
                  _eventsController.publicEvents.isEmpty &&
                  _sponsorsController.openOpportunities.isEmpty;

          if (isBusy) {
            return const Center(child: CircularProgressIndicator());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildTabSurface(
              key: ValueKey('${user.role.name}-$_selectedTab'),
              session: session,
              user: user,
              navigation: navigation,
              heroMetrics: heroMetrics,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabSurface({
    required Key key,
    required AuthSession session,
    required UserModel user,
    required _NavDestinationData navigation,
    required List<_HeroMetric> heroMetrics,
  }) {
    final palette = _paletteForRole(user.role);
    final sections = switch (_selectedTab) {
      0 => _buildExploreSections(session, user),
      1 => _buildWorkspaceSections(session, user),
      2 => _buildInboxSections(session, user),
      _ => _buildProfileSections(session, user),
    };

    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.canvasTop,
            palette.canvasBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 90,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.support.withValues(alpha: 0.08),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () => _loadAll(session),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
              children: [
                _HeroCard(
                  roleLabel: _workspaceLabelForRole(user.role),
                  headline: navigation.headline,
                  supporting: navigation.description,
                  metrics: heroMetrics,
                  palette: palette,
                ),
                const SizedBox(height: 12),
                _RoleLeadPanel(
                  title: _panelTitleForSelectedTab(),
                  actions: _quickActionsForRole(session, user.role),
                  signals: _signalsForSelectedTab(user.role),
                  palette: palette,
                ),
                ..._buildSystemBanners(),
                ...sections,
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_HeroMetric> _summaryMetricsForSelectedTab(UserRole role) {
    final signals = _signalsForSelectedTab(role);
    return signals
        .take(3)
        .map((signal) => _HeroMetric(signal.label, signal.value))
        .toList(growable: false);
  }

  List<_LeadSignal> _signalsForSelectedTab(UserRole role) {
    switch (_selectedTab) {
      case 0:
        return _leadSignalsForRole(role);
      case 1:
        switch (role) {
          case UserRole.attendee:
            return _attendeePlanSignals();
          case UserRole.organizer:
            return _organizerStudioSignals(role);
          case UserRole.vendor:
            return _vendorWorkSignals();
          case UserRole.sponsor:
            return _sponsorDealSignals();
          case UserRole.admin:
            return _adminReviewSignals();
        }
      case 2:
        return _inboxSignals(role);
      default:
        return [
          _LeadSignal(
            label: 'Role',
            value: role.name,
            note: 'Account identity',
            icon: Icons.person_rounded,
            color: const Color(0xFF355C7D),
          ),
          _LeadSignal(
            label: 'Alerts',
            value: userProfileAlertValue(role),
            note: 'Notification preference',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF2F6B57),
          ),
          _LeadSignal(
            label: 'AI',
            value: userProfileAiValue(role),
            note: 'Assistant state',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF7C6A3A),
          ),
        ];
    }
  }

  String userProfileAlertValue(UserRole role) {
    final session = AuthScope.of(context).session;
    final enabled = session?.user.settings?.notificationsEnabled ?? true;
    return enabled ? 'On' : 'Off';
  }

  String userProfileAiValue(UserRole role) {
    final session = AuthScope.of(context).session;
    final enabled = session?.user.settings?.aiAssistEnabled ?? false;
    return enabled ? 'On' : 'Off';
  }

  String _panelTitleForSelectedTab() {
    switch (_selectedTab) {
      case 0:
        return 'Discover';
      case 1:
        return 'Actions';
      case 2:
        return 'Updates';
      default:
        return 'Account';
    }
  }

  List<Widget> _buildSystemBanners() {
    final banners = <_BannerMessage>[
      if (_eventsController.errorMessage != null)
        _BannerMessage(
            _eventsController.errorMessage!, const Color(0xFFB3261E)),
      if (_chatController.errorMessage != null)
        _BannerMessage(_chatController.errorMessage!, const Color(0xFFB3261E)),
      if (_aiController.errorMessage != null)
        _BannerMessage(_aiController.errorMessage!, const Color(0xFFB3261E)),
      if (_notificationsController.errorMessage != null)
        _BannerMessage(
          _notificationsController.errorMessage!,
          const Color(0xFFB3261E),
        ),
      if (_supportController.errorMessage != null)
        _BannerMessage(
            _supportController.errorMessage!, const Color(0xFFB3261E)),
      if (_paymentsController.errorMessage != null)
        _BannerMessage(
            _paymentsController.errorMessage!, const Color(0xFFB3261E)),
      if (_vendorsController.errorMessage != null)
        _BannerMessage(
            _vendorsController.errorMessage!, const Color(0xFFB3261E)),
      if (_sponsorsController.errorMessage != null)
        _BannerMessage(
            _sponsorsController.errorMessage!, const Color(0xFFB3261E)),
    ];

    return banners
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _BannerCard(message: item.message, color: item.color),
          ),
        )
        .toList(growable: false);
  }

  _RolePalette _paletteForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return const _RolePalette(
          canvasTop: Color(0xFFF7F3EB),
          canvasBottom: Color(0xFFEDE5D8),
          surface: Color(0xFFFFFBF5),
          accent: Color(0xFF8A6738),
          support: Color(0xFF9B8158),
        );
      case UserRole.organizer:
        return const _RolePalette(
          canvasTop: Color(0xFFF3F7F3),
          canvasBottom: Color(0xFFE3ECE5),
          surface: Color(0xFFFDFEFB),
          accent: Color(0xFF2F6B57),
          support: Color(0xFF6D8B7C),
        );
      case UserRole.vendor:
        return const _RolePalette(
          canvasTop: Color(0xFFF8F3EE),
          canvasBottom: Color(0xFFEDE3D7),
          surface: Color(0xFFFFFBF7),
          accent: Color(0xFF7C5938),
          support: Color(0xFF967258),
        );
      case UserRole.sponsor:
        return const _RolePalette(
          canvasTop: Color(0xFFF5F6FA),
          canvasBottom: Color(0xFFE5EAF1),
          surface: Color(0xFFFCFCFE),
          accent: Color(0xFF536781),
          support: Color(0xFF7F8A9A),
        );
      case UserRole.admin:
        return const _RolePalette(
          canvasTop: Color(0xFFF2F5F8),
          canvasBottom: Color(0xFFE4EAF0),
          surface: Color(0xFFFDFEFF),
          accent: Color(0xFF324A5F),
          support: Color(0xFF62788A),
        );
    }
  }

  Widget _buildDiscoverySearchSection() {
    return _SectionCard(
      title: 'Find the right room',
      accent: const Color(0xFFBA7B2F),
      icon: Icons.search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _eventSearch = value;
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search events, cities, venues, or categories',
            ),
          ),
          if (_eventsController.categories.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategorySlug == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategorySlug = null;
                    });
                  },
                ),
                ..._eventsController.categories.map(
                  (category) => ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategorySlug == category.slug,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategorySlug =
                            _selectedCategorySlug == category.slug
                                ? null
                                : category.slug;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<_LeadSignal> _leadSignalsForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return [
          _LeadSignal(
            label: 'Saved',
            value: _eventsController.favoriteEvents.length.toString(),
            note: 'Shortlist building',
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFBA7B2F),
          ),
          _LeadSignal(
            label: 'Booked',
            value: _eventsController.myRegistrations.length.toString(),
            note: 'Confirmed plans',
            icon: Icons.confirmation_number_rounded,
            color: const Color(0xFF145B52),
          ),
          _LeadSignal(
            label: 'Unread',
            value: _notificationsController.unreadCount.toString(),
            note: 'Fresh updates',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF6B5078),
          ),
        ];
      case UserRole.organizer:
        return _organizerStudioSignals(role);
      case UserRole.vendor:
        return _vendorWorkSignals();
      case UserRole.sponsor:
        return _sponsorDealSignals();
      case UserRole.admin:
        return _adminReviewSignals();
    }
  }

  List<_LeadSignal> _attendeePlanSignals() {
    final paidCount = _paymentsController.payments
        .where((item) => item.payment.status == 'paid')
        .length;
    return [
      _LeadSignal(
        label: 'Upcoming',
        value: _eventsController.myRegistrations.length.toString(),
        note: 'Planned live moments',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF145B52),
      ),
      _LeadSignal(
        label: 'Paid',
        value: paidCount.toString(),
        note: 'Stripe settled',
        icon: Icons.lock_rounded,
        color: const Color(0xFF6A4A7C),
      ),
      _LeadSignal(
        label: 'Recent',
        value: _eventsController.recentlyViewedEvents.length.toString(),
        note: 'Viewed lately',
        icon: Icons.visibility_rounded,
        color: const Color(0xFF8A5A22),
      ),
    ];
  }

  List<_LeadSignal> _organizerStudioSignals(UserRole role) {
    return [
      _LeadSignal(
        label: 'Events',
        value: _eventsController.myEvents.length.toString(),
        note:
            role == UserRole.admin ? 'Admin-reviewed set' : 'Studio inventory',
        icon: Icons.theater_comedy_rounded,
        color: const Color(0xFF145B52),
      ),
      _LeadSignal(
        label: 'Vendor reqs',
        value: _vendorsController.myOrganizerRequests.length.toString(),
        note: 'Procurement lane',
        icon: Icons.store_mall_directory_rounded,
        color: const Color(0xFF4B5B77),
      ),
      _LeadSignal(
        label: 'Opportunities',
        value: _sponsorsController.myOpportunities.length.toString(),
        note: 'Revenue pipeline',
        icon: Icons.handshake_rounded,
        color: const Color(0xFFB26B2D),
      ),
    ];
  }

  List<_LeadSignal> _adminReviewSignals() {
    return [
      _LeadSignal(
        label: 'Events',
        value: _eventsController.publicEvents.length.toString(),
        note: 'Live inventory',
        icon: Icons.public_rounded,
        color: const Color(0xFF173B63),
      ),
      _LeadSignal(
        label: 'Vendors',
        value: _vendorsController.publicVendors.length.toString(),
        note: 'Coverage to review',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF145B52),
      ),
      _LeadSignal(
        label: 'Alerts',
        value: _notificationsController.unreadCount.toString(),
        note: 'Unread ops activity',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFB26B2D),
      ),
    ];
  }

  List<_LeadSignal> _vendorWorkSignals() {
    return [
      _LeadSignal(
        label: 'Services',
        value: (_vendorsController.myVendorProfile?.services.length ?? 0)
            .toString(),
        note: 'Catalog depth',
        icon: Icons.design_services_rounded,
        color: const Color(0xFF6B5078),
      ),
      _LeadSignal(
        label: 'Packages',
        value: (_vendorsController.myVendorProfile?.packages.length ?? 0)
            .toString(),
        note: 'Bundled offers',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFBA7B2F),
      ),
      _LeadSignal(
        label: 'Accepted',
        value: _vendorsController.myVendorRequests
            .where(
                (item) => item.status == 'accepted' || item.status == 'booked')
            .length
            .toString(),
        note: 'Active deals',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF145B52),
      ),
    ];
  }

  List<_LeadSignal> _sponsorDealSignals() {
    return [
      _LeadSignal(
        label: 'Interests',
        value: _sponsorsController.myInterests.length.toString(),
        note: 'Active conversations',
        icon: Icons.flag_circle_rounded,
        color: const Color(0xFFB26B2D),
      ),
      _LeadSignal(
        label: 'Matches',
        value: _aiController.recommendedOpportunities.length.toString(),
        note: 'Ranked shortlist',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5526),
      ),
      _LeadSignal(
        label: 'Inbox',
        value: _chatController.conversations.length.toString(),
        note: 'Direct threads',
        icon: Icons.mark_chat_unread_rounded,
        color: const Color(0xFF145B52),
      ),
    ];
  }

  List<_LeadSignal> _inboxSignals(UserRole role) {
    return [
      _LeadSignal(
        label: 'Alerts',
        value: _notificationsController.notifications.length.toString(),
        note: 'System + product',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF145B52),
      ),
      _LeadSignal(
        label: 'Threads',
        value: _chatController.conversations.length.toString(),
        note: 'Live message lanes',
        icon: Icons.forum_rounded,
        color: const Color(0xFF5D4A6D),
      ),
      _LeadSignal(
        label: 'Support',
        value: _supportController.tickets.length.toString(),
        note: role == UserRole.admin ? 'Cases in view' : 'Open tickets',
        icon: Icons.support_agent_rounded,
        color: const Color(0xFFB26B2D),
      ),
    ];
  }

  List<Widget> _buildExploreSections(AuthSession session, UserModel user) {
    final publicEvents = _filteredPublicEvents();
    final featuredEvent = publicEvents.isNotEmpty ? publicEvents.first : null;
    final searchSection = _buildDiscoverySearchSection();

    switch (user.role) {
      case UserRole.attendee:
        return [
          const SizedBox(height: 16),
          searchSection,
          if (publicEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CitySpotlightPanel(events: publicEvents),
          ],
          if (featuredEvent != null) ...[
            const SizedBox(height: 16),
            _FeaturedEventPanel(
              event: featuredEvent,
              onTap: () => _openEventDetail(
                session,
                featuredEvent.id,
                manageMode: false,
              ),
            ),
          ],
          if (_aiController.recommendedEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'A better fit than the feed',
              accent: const Color(0xFF8A5A22),
              icon: Icons.auto_awesome_rounded,
              child: Column(
                children: _aiController.recommendedEvents
                    .take(3)
                    .map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecommendationCard(
                          title: recommendation.event.title,
                          reason: recommendation.reasonSummary,
                          score: recommendation.score,
                          meta:
                              '${recommendation.event.venue}, ${recommendation.event.city}',
                          onTap: () => _openEventDetail(
                            session,
                            recommendation.event.id,
                            manageMode: false,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: publicEvents.isEmpty ? 'No matching events' : 'Live now',
            accent: const Color(0xFFBA7B2F),
            icon: Icons.local_activity_rounded,
            child: publicEvents.isEmpty
                ? const Text(
                    'Try another search or category filter.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: publicEvents
                        .take(8)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFFCC7A00),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.organizer:
        return [
          if (_vendorsController.publicVendors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Vendor market',
              accent: const Color(0xFF145B52),
              icon: Icons.storefront_rounded,
              child: Column(
                children: _vendorsController.publicVendors
                    .take(4)
                    .map(
                      (vendor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorDiscoveryCard(
                          vendor: vendor,
                          actionLabel: 'Start chat',
                          secondaryActionLabel:
                              vendor.bookingPreference?.allowDirectBooking ==
                                      true
                                  ? 'Book / request'
                                  : 'Send request',
                          onAction: () => _openDirectConversation(
                            session,
                            participantUserId: vendor.userId,
                            participantLabel: vendor.businessName,
                          ),
                          onSecondaryAction: () => _openVendorRequestSheet(
                            session,
                            vendor,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (_sponsorsController.openOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Sponsor demand',
              accent: const Color(0xFFB26B2D),
              icon: Icons.campaign_rounded,
              child: Column(
                children: _sponsorsController.openOpportunities
                    .take(4)
                    .map(
                      (opportunity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SponsorshipOpportunityCard(
                          opportunity: opportunity,
                          accent: const Color(0xFFCC7A00),
                          actionLabel: user.role == UserRole.admin
                              ? 'Express interest'
                              : null,
                          secondaryActionLabel: user.role == UserRole.admin
                              ? 'Chat organizer'
                              : null,
                          onAction: user.role == UserRole.admin
                              ? () => _openExpressInterestSheet(
                                  session, opportunity)
                              : null,
                          onSecondaryAction: user.role == UserRole.admin
                              ? () => _openDirectConversation(
                                    session,
                                    participantUserId: opportunity.organizerId,
                                    participantLabel: opportunity.event.title,
                                  )
                              : null,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (featuredEvent != null) ...[
            const SizedBox(height: 16),
            _FeaturedEventPanel(
              event: featuredEvent,
              onTap: () => _openEventDetail(
                session,
                featuredEvent.id,
                manageMode: false,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: publicEvents.isEmpty ? 'No live events' : 'Public pulse',
            accent: const Color(0xFF145B52),
            icon: Icons.trending_up_rounded,
            child: publicEvents.isEmpty
                ? const Text(
                    'Publish an event to light up this feed.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: publicEvents
                        .take(6)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFF145B52),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.admin:
        return [
          if (featuredEvent != null) ...[
            const SizedBox(height: 16),
            _FeaturedEventPanel(
              event: featuredEvent,
              onTap: () => _openEventDetail(
                session,
                featuredEvent.id,
                manageMode: false,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: publicEvents.isEmpty ? 'No live events' : 'Event pulse',
            accent: const Color(0xFF173B63),
            icon: Icons.monitor_heart_rounded,
            child: publicEvents.isEmpty
                ? const Text(
                    'Public activity will appear here once events are live.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: publicEvents
                        .take(6)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFF173B63),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (_vendorsController.publicVendors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Vendor coverage',
              accent: const Color(0xFF145B52),
              icon: Icons.storefront_rounded,
              child: Column(
                children: _vendorsController.publicVendors
                    .take(4)
                    .map(
                      (vendor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorDiscoveryCard(vendor: vendor),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (_sponsorsController.openOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Sponsor queue',
              accent: const Color(0xFFB26B2D),
              icon: Icons.handshake_rounded,
              child: Column(
                children: _sponsorsController.openOpportunities
                    .take(4)
                    .map(
                      (opportunity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SponsorshipOpportunityCard(
                          opportunity: opportunity,
                          accent: const Color(0xFFB26B2D),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ];
      case UserRole.vendor:
        return [
          if (featuredEvent != null) ...[
            const SizedBox(height: 16),
            _FeaturedEventPanel(
              event: featuredEvent,
              onTap: () => _openEventDetail(
                session,
                featuredEvent.id,
                manageMode: false,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title:
                publicEvents.isEmpty ? 'No event demand yet' : 'Demand radar',
            accent: const Color(0xFF5C4267),
            icon: Icons.radar_rounded,
            child: publicEvents.isEmpty
                ? const Text(
                    'Once organizers publish events, open demand will appear here.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: publicEvents
                        .take(6)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFF6B5078),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.sponsor:
        return [
          if (_aiController.recommendedOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Best-fit sponsor openings',
              accent: const Color(0xFF8B5526),
              icon: Icons.insights_rounded,
              child: Column(
                children: _aiController.recommendedOpportunities
                    .take(4)
                    .map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecommendationCard(
                          title: recommendation.opportunity.title,
                          reason: recommendation.reasonSummary,
                          score: recommendation.score,
                          meta: recommendation.opportunity.event.title,
                          onTap: () => _openExpressInterestSheet(
                            session,
                            recommendation.opportunity,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (_sponsorsController.openOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Open opportunities',
              accent: const Color(0xFFB26B2D),
              icon: Icons.workspace_premium_rounded,
              child: Column(
                children: _sponsorsController.openOpportunities
                    .take(6)
                    .map(
                      (opportunity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SponsorshipOpportunityCard(
                          opportunity: opportunity,
                          accent: const Color(0xFFCC7A00),
                          actionLabel: 'Express interest',
                          secondaryActionLabel: 'Chat with organizer',
                          onAction: () => _openExpressInterestSheet(
                            session,
                            opportunity,
                          ),
                          onSecondaryAction: () => _openDirectConversation(
                            session,
                            participantUserId: opportunity.organizerId,
                            participantLabel: opportunity.event.title,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (featuredEvent != null) ...[
            const SizedBox(height: 16),
            _FeaturedEventPanel(
              event: featuredEvent,
              onTap: () => _openEventDetail(
                session,
                featuredEvent.id,
                manageMode: false,
              ),
            ),
          ],
        ];
    }
  }

  List<Widget> _buildWorkspaceSections(AuthSession session, UserModel user) {
    switch (user.role) {
      case UserRole.attendee:
        return [
          const SizedBox(height: 16),
          _SectionCard(
            title: 'My plans',
            accent: const Color(0xFF145B52),
            icon: Icons.event_available_rounded,
            child: _eventsController.myRegistrations.isEmpty
                ? const Text(
                    'You have not booked any events yet.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _eventsController.myRegistrations
                        .map(
                          (registration) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:
                                _RegistrationCard(registration: registration),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Saved shortlist',
            accent: const Color(0xFF8A5A22),
            icon: Icons.bookmark_rounded,
            child: _eventsController.favoriteEvents.isEmpty
                ? const Text(
                    'Save events from discovery to build a shortlist.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _eventsController.favoriteEvents
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFF7C5C00),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Payment history',
            accent: const Color(0xFF6A4A7C),
            icon: Icons.receipt_long_rounded,
            child: _paymentsController.payments.isEmpty
                ? const Text(
                    'No payments yet. Paid ticket checkouts will appear here.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _paymentsController.payments
                        .map(
                          (payment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PaymentCard(payment: payment),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.organizer:
        return [
          if (_canCreateEvents(user.role)) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Event studio',
              accent: const Color(0xFF145B52),
              icon: Icons.theater_comedy_rounded,
              child: _eventsController.myEvents.isEmpty
                  ? const Text(
                      'No events yet. Create your first event to open ticketing and sponsor flow.',
                      style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                    )
                  : Column(
                      children: _eventsController.myEvents
                          .map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _EventCard(
                                event: event,
                                accent: const Color(0xFF0E6B5C),
                                onTap: () => _openEventDetail(
                                  session,
                                  event.id,
                                  manageMode: true,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Planning assistant',
            accent: const Color(0xFF7A4F20),
            icon: Icons.auto_awesome_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.tonal(
                  onPressed: () => _openPlanningAssistantSheet(session),
                  child: const Text('Generate planning brief'),
                ),
                const SizedBox(height: 14),
                if (_aiController.planningBrief == null)
                  const Text(
                    'Generate an organizer brief with timeline checkpoints, vendor coverage, and budget guidance.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                else
                  _PlanningBriefCard(
                      planningBrief: _aiController.planningBrief!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Vendor requests',
            accent: const Color(0xFF4B5B77),
            icon: Icons.store_mall_directory_rounded,
            child: _vendorsController.myOrganizerRequests.isEmpty
                ? const Text(
                    'No vendor requests yet. Start from the vendor market.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _vendorsController.myOrganizerRequests
                        .map(
                          (vendorRequest) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VendorRequestCard(
                              vendorRequest: vendorRequest,
                              actionLabel: vendorRequest.status == 'accepted'
                                  ? 'Mark booked'
                                  : null,
                              onAction: vendorRequest.status == 'accepted'
                                  ? () => _vendorsController
                                          .markVendorRequestBooked(
                                        session,
                                        requestId: vendorRequest.id,
                                      )
                                  : null,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Sponsorship pipeline',
            accent: const Color(0xFFB26B2D),
            icon: Icons.handshake_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.tonal(
                  onPressed: () => _openCreateOpportunitySheet(session),
                  child: const Text('Create opportunity'),
                ),
                const SizedBox(height: 14),
                if (_sponsorsController.myOpportunities.isEmpty)
                  const Text(
                    'No sponsorship opportunities yet.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                else
                  ..._sponsorsController.myOpportunities.map(
                    (opportunity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SponsorshipOpportunityCard(
                        opportunity: opportunity,
                        accent: const Color(0xFF0E6B5C),
                        actionLabel: 'View interests',
                        onAction: () => _openOpportunityInterestsSheet(
                          session,
                          opportunity,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ];
      case UserRole.admin:
        return [
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Platform review',
            accent: const Color(0xFF173B63),
            icon: Icons.fact_check_rounded,
            child: _eventsController.publicEvents.isEmpty
                ? const Text(
                    'Live events will appear here for review.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _eventsController.publicEvents
                        .take(6)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: event,
                              accent: const Color(0xFF173B63),
                              onTap: () => _openEventDetail(
                                session,
                                event.id,
                                manageMode: false,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (_vendorsController.publicVendors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Vendor readiness',
              accent: const Color(0xFF145B52),
              icon: Icons.approval_rounded,
              child: Column(
                children: _vendorsController.publicVendors
                    .take(4)
                    .map(
                      (vendor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VendorDiscoveryCard(vendor: vendor),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Support watch',
            accent: const Color(0xFFB26B2D),
            icon: Icons.support_agent_rounded,
            child: _supportController.tickets.isEmpty
                ? const Text(
                    'No support tickets linked to this account yet.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _supportController.tickets
                        .map(
                          (ticket) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SupportTicketCard(ticket: ticket),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.vendor:
        return [
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Business profile',
            accent: const Color(0xFF6B5078),
            icon: Icons.store_rounded,
            child: _vendorsController.myVendorProfile == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your profile so organizers can find your services.',
                        style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => _openVendorProfileSheet(session),
                        child: const Text('Create vendor profile'),
                      ),
                    ],
                  )
                : _VendorProfileCard(
                    profile: _vendorsController.myVendorProfile!,
                    onEditProfile: () => _openVendorProfileSheet(session),
                    onAddService: () => _openVendorServiceSheet(session),
                    onAddPackage: () => _openVendorPackageSheet(session),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Incoming requests',
            accent: const Color(0xFF145B52),
            icon: Icons.inbox_rounded,
            child: _vendorsController.myVendorRequests.isEmpty
                ? const Text(
                    'No organizer requests yet.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _vendorsController.myVendorRequests
                        .map(
                          (vendorRequest) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VendorRequestCard(
                              vendorRequest: vendorRequest,
                              actionLabel: vendorRequest.status == 'pending'
                                  ? 'Accept'
                                  : null,
                              secondaryActionLabel:
                                  vendorRequest.status == 'pending'
                                      ? 'Decline'
                                      : null,
                              onAction: vendorRequest.status == 'pending'
                                  ? () =>
                                      _vendorsController.respondToVendorRequest(
                                        session,
                                        requestId: vendorRequest.id,
                                        status: 'accepted',
                                      )
                                  : null,
                              onSecondaryAction: vendorRequest.status ==
                                      'pending'
                                  ? () =>
                                      _vendorsController.respondToVendorRequest(
                                        session,
                                        requestId: vendorRequest.id,
                                        status: 'declined',
                                      )
                                  : null,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ];
      case UserRole.sponsor:
        return [
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Brand profile',
            accent: const Color(0xFF8B5526),
            icon: Icons.apartment_rounded,
            child: _sponsorsController.mySponsorProfile == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add a sponsor profile so organizers understand your fit.',
                        style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => _openSponsorProfileSheet(session),
                        child: const Text('Create sponsor profile'),
                      ),
                    ],
                  )
                : _SponsorProfileCard(
                    profile: _sponsorsController.mySponsorProfile!,
                    onEditProfile: () => _openSponsorProfileSheet(session),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'My interests',
            accent: const Color(0xFFB26B2D),
            icon: Icons.flag_circle_rounded,
            child: _sponsorsController.myInterests.isEmpty
                ? const Text(
                    'You have not responded to any opportunities yet.',
                    style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
                  )
                : Column(
                    children: _sponsorsController.myInterests
                        .map(
                          (interest) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SponsorshipInterestCard(interest: interest),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (_aiController.recommendedOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'AI-ranked opportunity matches',
              accent: const Color(0xFF7A4F20),
              icon: Icons.auto_graph_rounded,
              child: Column(
                children: _aiController.recommendedOpportunities
                    .take(4)
                    .map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecommendationCard(
                          title: recommendation.opportunity.title,
                          reason: recommendation.reasonSummary,
                          score: recommendation.score,
                          meta: recommendation.opportunity.event.title,
                          onTap: () => _openExpressInterestSheet(
                            session,
                            recommendation.opportunity,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ];
    }
  }

  List<Widget> _buildInboxSections(AuthSession session, UserModel user) {
    return [
      const SizedBox(height: 16),
      _SignalStrip(signals: _inboxSignals(user.role)),
      const SizedBox(height: 16),
      _SectionCard(
        title: _notificationsController.unreadCount > 0
            ? 'Alerts (${_notificationsController.unreadCount})'
            : 'Alerts',
        accent: const Color(0xFF145B52),
        icon: Icons.notifications_active_rounded,
        child: _notificationsController.notifications.isEmpty
            ? const Text(
                'No notifications yet. Booking, payment, vendor, sponsor, and support updates will appear here.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_notificationsController.unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: FilledButton.tonal(
                        onPressed: _notificationsController.isSubmitting
                            ? null
                            : () =>
                                _notificationsController.markAllRead(session),
                        child: Text(
                          _notificationsController.isSubmitting
                              ? 'Updating...'
                              : 'Mark all read',
                        ),
                      ),
                    ),
                  ..._notificationsController.notifications.take(8).map(
                        (notification) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NotificationCard(
                            notification: notification,
                            onTap: notification.unread
                                ? () => _notificationsController.markRead(
                                      session,
                                      notification.id,
                                    )
                                : null,
                          ),
                        ),
                      ),
                ],
              ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Messages',
        accent: const Color(0xFF5D4A6D),
        icon: Icons.mark_chat_unread_rounded,
        child: _chatController.conversations.isEmpty
            ? const Text(
                'No conversations yet. Start one from discovery, vendors, or sponsorship opportunities.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              )
            : Column(
                children: _chatController.conversations
                    .map(
                      (conversation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ConversationCard(
                          conversation: conversation,
                          currentUserId: user.id,
                          onTap: () =>
                              _openConversationSheet(session, conversation),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Support',
        accent: const Color(0xFFB26B2D),
        icon: Icons.support_agent_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.tonal(
              onPressed: () => _openCreateSupportTicketSheet(session),
              child: const Text('Create support ticket'),
            ),
            const SizedBox(height: 14),
            if (_supportController.tickets.isEmpty)
              const Text(
                'No support tickets yet.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              )
            else
              ..._supportController.tickets.map(
                (ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SupportTicketCard(ticket: ticket),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildProfileSections(AuthSession session, UserModel user) {
    return [
      const SizedBox(height: 16),
      _ProfileSummaryCard(user: user),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Account tools',
        accent: const Color(0xFF145B52),
        icon: Icons.tune_rounded,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _openEditProfileSheet(session),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openCreateSupportTicketSheet(session),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Support'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Preferences',
        accent: const Color(0xFF8A5A22),
        icon: Icons.shield_moon_rounded,
        child: Column(
          children: [
            _PreferenceRow(
              label: 'Notifications',
              value: user.settings?.notificationsEnabled == true ? 'On' : 'Off',
            ),
            _PreferenceRow(
              label: 'AI assist',
              value: user.settings?.aiAssistEnabled == true
                  ? 'Enabled'
                  : 'Disabled',
            ),
            _PreferenceRow(
              label: 'Privacy',
              value: user.settings?.privacyLevel ?? 'community',
            ),
            _PreferenceRow(
              label: 'Role',
              value: user.role.name,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'Recent activity',
        accent: const Color(0xFF5D4A6D),
        icon: Icons.history_toggle_off_rounded,
        child: _eventsController.recentlyViewedEvents.isEmpty
            ? const Text(
                'Open an event detail screen to build your recent activity trail.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              )
            : Column(
                children: _eventsController.recentlyViewedEvents
                    .take(4)
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventCard(
                          event: event,
                          accent: const Color(0xFF54686B),
                          onTap: () => _openEventDetail(
                            session,
                            event.id,
                            manageMode: false,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
      ),
    ];
  }

  List<EventModel> _filteredPublicEvents() {
    final query = _eventSearch.trim().toLowerCase();
    return _eventsController.publicEvents.where((event) {
      final categoryMatches = _selectedCategorySlug == null ||
          event.category.slug == _selectedCategorySlug;
      if (!categoryMatches) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack =
          '${event.title} ${event.city} ${event.venue} ${event.category.name} ${event.description}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  FloatingActionButton? _buildFloatingActionButton(
    AuthSession session,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.organizer:
        return FloatingActionButton.small(
          onPressed: () => _openCreateEventSheet(session),
          tooltip: 'Create event',
          child: const Icon(Icons.add_rounded),
        );
      case UserRole.admin:
        return null;
      case UserRole.vendor:
        return FloatingActionButton.small(
          onPressed: () => _vendorsController.myVendorProfile == null
              ? _openVendorProfileSheet(session)
              : _openVendorServiceSheet(session),
          tooltip: _vendorsController.myVendorProfile == null
              ? 'Set profile'
              : 'Add service',
          child: Icon(
            _vendorsController.myVendorProfile == null
                ? Icons.store_rounded
                : Icons.design_services_rounded,
          ),
        );
      case UserRole.sponsor:
        return FloatingActionButton.small(
          onPressed: () => _openSponsorProfileSheet(session),
          tooltip: 'Brand profile',
          child: const Icon(Icons.campaign_rounded),
        );
      case UserRole.attendee:
        return null;
    }
  }

  List<_NavDestinationData> _navigationForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return const [
          _NavDestinationData(
            label: 'Explore',
            headline: 'Explore',
            description:
                'Search, filter, and discover live events worth saving or booking.',
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
          ),
          _NavDestinationData(
            label: 'Plans',
            headline: 'Plans',
            description:
                'Your registrations, shortlist, and payment history in one place.',
            icon: Icons.confirmation_number_outlined,
            selectedIcon: Icons.confirmation_number_rounded,
          ),
          _NavDestinationData(
            label: 'Inbox',
            headline: 'Inbox',
            description:
                'Notifications, conversations, and support updates stay together.',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          _NavDestinationData(
            label: 'Profile',
            headline: 'Profile',
            description: 'Account settings, identity, and recent activity.',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.organizer:
        return const [
          _NavDestinationData(
            label: 'Overview',
            headline: 'Overview',
            description:
                'Monitor discovery, vendor supply, and sponsor demand from one surface.',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          _NavDestinationData(
            label: 'Studio',
            headline: 'Studio',
            description:
                'Run event creation, planning, and marketplace workflows.',
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
          ),
          _NavDestinationData(
            label: 'Inbox',
            headline: 'Inbox',
            description: 'Messages, alerts, and support conversations.',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          _NavDestinationData(
            label: 'Profile',
            headline: 'Profile',
            description:
                'Your account state, settings, and recent platform activity.',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.vendor:
        return const [
          _NavDestinationData(
            label: 'Market',
            headline: 'Market',
            description:
                'Watch demand signals, event inventory, and open opportunities.',
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
          ),
          _NavDestinationData(
            label: 'Work',
            headline: 'Work',
            description: 'Manage your catalog and incoming organizer requests.',
            icon: Icons.work_outline_rounded,
            selectedIcon: Icons.work_rounded,
          ),
          _NavDestinationData(
            label: 'Inbox',
            headline: 'Inbox',
            description:
                'Stay on top of messages, support, and booking alerts.',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          _NavDestinationData(
            label: 'Profile',
            headline: 'Profile',
            description:
                'Account identity, settings, and recently viewed items.',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.sponsor:
        return const [
          _NavDestinationData(
            label: 'Explore',
            headline: 'Explore',
            description:
                'Scan open opportunities, event momentum, and fit signals.',
            icon: Icons.travel_explore_outlined,
            selectedIcon: Icons.travel_explore_rounded,
          ),
          _NavDestinationData(
            label: 'Deals',
            headline: 'Deals',
            description:
                'Manage brand profile, interests, and AI-ranked matches.',
            icon: Icons.handshake_outlined,
            selectedIcon: Icons.handshake_rounded,
          ),
          _NavDestinationData(
            label: 'Inbox',
            headline: 'Inbox',
            description: 'Messages, support, and sponsor-side alerts.',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          _NavDestinationData(
            label: 'Profile',
            headline: 'Profile',
            description: 'Identity, settings, and recent activity.',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
      case UserRole.admin:
        return const [
          _NavDestinationData(
            label: 'Pulse',
            headline: 'Pulse',
            description:
                'Watch public activity, vendor coverage, and platform movement.',
            icon: Icons.monitor_heart_outlined,
            selectedIcon: Icons.monitor_heart_rounded,
          ),
          _NavDestinationData(
            label: 'Review',
            headline: 'Review',
            description:
                'Review live events, vendors, sponsor demand, and support status.',
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check_rounded,
          ),
          _NavDestinationData(
            label: 'Inbox',
            headline: 'Inbox',
            description: 'Watch support, alerts, and real-time conversations.',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
          ),
          _NavDestinationData(
            label: 'Profile',
            headline: 'Profile',
            description: 'Account state, preferences, and recent activity.',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ];
    }
  }

  List<_QuickActionData> _quickActionsForRole(
    AuthSession session,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.attendee:
        return [
          _QuickActionData(
            label: 'Saved',
            icon: Icons.bookmark_rounded,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _QuickActionData(
            label: 'Tickets',
            icon: Icons.confirmation_number_rounded,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _QuickActionData(
            label: 'Support',
            icon: Icons.support_agent_rounded,
            onTap: () => _openCreateSupportTicketSheet(session),
          ),
        ];
      case UserRole.organizer:
        return [
          _QuickActionData(
            label: 'New event',
            icon: Icons.add_box_rounded,
            onTap: () => _openCreateEventSheet(session),
          ),
          _QuickActionData(
            label: 'Plan',
            icon: Icons.auto_awesome_rounded,
            onTap: () => _openPlanningAssistantSheet(session),
          ),
          _QuickActionData(
            label: 'Sponsor',
            icon: Icons.campaign_rounded,
            onTap: () => _openCreateOpportunitySheet(session),
          ),
        ];
      case UserRole.admin:
        return [
          _QuickActionData(
            label: 'Pulse',
            icon: Icons.monitor_heart_rounded,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _QuickActionData(
            label: 'Review',
            icon: Icons.fact_check_rounded,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _QuickActionData(
            label: 'Inbox',
            icon: Icons.forum_rounded,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ];
      case UserRole.vendor:
        return [
          _QuickActionData(
            label: 'Profile',
            icon: Icons.store_rounded,
            onTap: () => _openVendorProfileSheet(session),
          ),
          _QuickActionData(
            label: 'Service',
            icon: Icons.design_services_rounded,
            onTap: () => _openVendorServiceSheet(session),
          ),
          _QuickActionData(
            label: 'Package',
            icon: Icons.inventory_2_rounded,
            onTap: () => _openVendorPackageSheet(session),
          ),
        ];
      case UserRole.sponsor:
        return [
          _QuickActionData(
            label: 'Profile',
            icon: Icons.apartment_rounded,
            onTap: () => _openSponsorProfileSheet(session),
          ),
          _QuickActionData(
            label: 'Pipeline',
            icon: Icons.handshake_rounded,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _QuickActionData(
            label: 'Support',
            icon: Icons.support_agent_rounded,
            onTap: () => _openCreateSupportTicketSheet(session),
          ),
        ];
    }
  }

  bool _canCreateEvents(UserRole role) {
    return role == UserRole.organizer;
  }

  Future<void> _openEventDetail(
    AuthSession session,
    String eventId, {
    required bool manageMode,
  }) async {
    if (!manageMode) {
      await _eventsController.recordEventView(session, eventId);
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRouter.eventDetail,
      arguments: EventDetailScreenArgs(
        eventId: eventId,
        manageMode: manageMode,
      ),
    );

    if (mounted) {
      await _loadAll(session);
    }
  }

  String _workspaceLabelForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Meloo platforms';
      case UserRole.attendee:
        return 'Attendee desk';
      case UserRole.organizer:
        return 'Organizer desk';
      case UserRole.vendor:
        return 'Vendor desk';
      case UserRole.sponsor:
        return 'Sponsor desk';
    }
  }

}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    this.onTap,
  });

  final AppNotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColorFor(notification.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: notification.unread
                ? const [
                    Color(0xFFFFFCF7),
                    Color(0xFFF4F8F7),
                  ]
                : const [
                    Colors.white,
                    Color(0xFFF8F5EF),
                  ],
          ),
          border: Border.all(
            color: notification.unread
                ? accent
                : const Color(0xFFE0D9CB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(notification.type), color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeTimestamp(notification.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF7A7369),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(
                  label: notification.unread ? 'new' : notification.type,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.body,
              style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
            ),
            if (notification.resourceType != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaLabel(label: notification.resourceType!),
                  _MetaLabel(label: _formatCompactTimestamp(notification.createdAt)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'chat':
        return Icons.mark_chat_unread_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'booking':
        return Icons.confirmation_number_rounded;
      case 'vendor':
        return Icons.storefront_rounded;
      case 'sponsor':
        return Icons.campaign_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _accentColorFor(String type) {
    switch (type) {
      case 'chat':
        return const Color(0xFF4F5BD5);
      case 'payment':
        return const Color(0xFF0E6B5C);
      case 'booking':
        return const Color(0xFFB26B2D);
      case 'vendor':
        return const Color(0xFF8B4D18);
      case 'sponsor':
        return const Color(0xFF6A4CC2);
      case 'support':
        return const Color(0xFFC25B3F);
      default:
        return const Color(0xFF145B52);
    }
  }
}

class _PlanningBriefCard extends StatelessWidget {
  const _PlanningBriefCard({required this.planningBrief});

  final AiPlanningAssistantResponseModel planningBrief;

  @override
  Widget build(BuildContext context) {
    Widget buildList(String title, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: const TextStyle(
                  color: Color(0xFF5F645F),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planningBrief.overview,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 14),
          buildList('Checklist', planningBrief.checklist),
          const SizedBox(height: 12),
          buildList('Vendor coverage', planningBrief.vendorCategories),
          const SizedBox(height: 12),
          buildList('Timeline', planningBrief.timelineMilestones),
          const SizedBox(height: 12),
          buildList('Sponsorship angles', planningBrief.sponsorshipAngles),
          const SizedBox(height: 12),
          buildList('Budget guidance', planningBrief.budgetGuidance),
          const SizedBox(height: 12),
          buildList('Operational risks', planningBrief.operationalRisks),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.roleLabel,
    required this.headline,
    required this.supporting,
    required this.metrics,
    required this.palette,
  });

  final String roleLabel;
  final String headline;
  final String supporting;
  final List<_HeroMetric> metrics;
  final _RolePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            palette.canvasTop,
          ],
        ),
        border: Border.all(color: palette.accent.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
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
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/branding/meloo-mark-v1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 22,
              height: 1.06,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supporting,
            maxLines: 3,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: metrics
                .map(
                  (metric) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.value,
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.label,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric {
  const _HeroMetric(this.label, this.value);

  final String label;
  final String value;
}

class _RolePalette {
  const _RolePalette({
    required this.canvasTop,
    required this.canvasBottom,
    required this.surface,
    required this.accent,
    required this.support,
  });

  final Color canvasTop;
  final Color canvasBottom;
  final Color surface;
  final Color accent;
  final Color support;
}

class _LeadSignal {
  const _LeadSignal({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
}

class _BannerMessage {
  const _BannerMessage(this.message, this.color);

  final String message;
  final Color color;
}

class _NavDestinationData {
  const _NavDestinationData({
    required this.label,
    required this.headline,
    required this.description,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final String headline;
  final String description;
  final IconData icon;
  final IconData? selectedIcon;
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _RoleLeadPanel extends StatelessWidget {
  const _RoleLeadPanel({
    required this.title,
    required this.actions,
    required this.signals,
    required this.palette,
  });

  final String title;
  final List<_QuickActionData> actions;
  final List<_LeadSignal> signals;
  final _RolePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(color: palette.accent.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard_customize_rounded,
                    size: 18, color: palette.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionStrip(actions: actions),
          const SizedBox(height: 12),
          _SignalStrip(signals: signals, compact: true),
        ],
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF8FAFB),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(action.icon, size: 17, color: const Color(0xFF2F6B57)),
                        const SizedBox(width: 8),
                        Text(
                          action.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SignalStrip extends StatelessWidget {
  const _SignalStrip({
    required this.signals,
    this.compact = false,
  });

  final List<_LeadSignal> signals;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: signals
            .map(
              (signal) => Padding(
                padding: EdgeInsets.only(right: compact ? 10 : 12),
                child: Container(
                  width: compact ? 154 : 180,
                  padding: EdgeInsets.all(compact ? 14 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(compact ? 18 : 20),
                    color: Colors.white,
                    border:
                        Border.all(color: signal.color.withValues(alpha: 0.18)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08101828),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 34 : 38,
                        height: compact ? 34 : 38,
                        decoration: BoxDecoration(
                          color: signal.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(signal.icon, color: signal.color, size: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        signal.value,
                        style: TextStyle(
                          fontSize: compact ? 20 : 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signal.label,
                        style: TextStyle(
                          color: signal.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 6),
                        Text(
                          signal.note,
                          style: const TextStyle(
                            color: Color(0xFF5F645F),
                            height: 1.45,
                          ),
                        ),
                      ],
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

class _FeaturedEventPanel extends StatelessWidget {
  const _FeaturedEventPanel({
    required this.event,
    required this.onTap,
  });

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String two(int value) => value.toString().padLeft(2, '0');
    final start = event.startAt;
    final window =
        '${two(start.day)}/${two(start.month)} • ${two(start.hour)}:${two(start.minute)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A403B),
              Color(0xFF25584F),
              Color(0xFFB07335),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24163E3A),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Featured • ${event.category.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 28,
                height: 1.02,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE8F0EE), height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FeaturePill(label: window),
                _FeaturePill(label: '${event.venue}, ${event.city}'),
                _FeaturePill(label: event.visibility),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySpotlightPanel extends StatelessWidget {
  const _CitySpotlightPanel({required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final event in events) {
      grouped.update(event.city, (count) => count + 1, ifAbsent: () => 1);
    }
    final cityPairs = grouped.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF9),
            Color(0xFFF4EADC),
          ],
        ),
        border: Border.all(color: const Color(0xFFE2D7C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_city_rounded, color: Color(0xFFBA7B2F)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'City radar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start with the cities that already have momentum on the platform.',
            style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cityPairs
                .take(6)
                .map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2D7C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value} live event${entry.value == 1 ? '' : 's'}',
                          style: const TextStyle(color: Color(0xFF5F645F)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final profile = user.profile;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF8),
            Color(0xFFF1E9DD),
          ],
        ),
        border: Border.all(color: const Color(0xFFD8D1C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF145B52),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              (profile?.fullName ?? user.email)
                  .trim()
                  .characters
                  .first
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? 'Account profile',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: const TextStyle(color: Color(0xFF5F645F), height: 1.4),
                ),
                if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    profile.bio!,
                    style:
                        const TextStyle(color: Color(0xFF5F645F), height: 1.45),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(user.role.name)),
                    Chip(label: Text(user.status)),
                    if (profile?.phone != null && profile!.phone!.isNotEmpty)
                      Chip(label: Text(profile.phone!)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF5F645F)),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.accent = const Color(0xFF145B52),
    this.icon = Icons.radio_button_checked_rounded,
  });

  final String title;
  final Widget child;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.accent,
    this.onTap,
  });

  final EventModel event;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFCFCFD),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06101828),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(label: event.status, color: accent),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: event.category.name, color: accent),
                _MetaLabel(label: _formatEventWindow(event)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaLabel(label: '${event.venue}, ${event.city}'),
                _MetaLabel(label: event.visibility),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventWindow(EventModel event) {
    String two(int value) => value.toString().padLeft(2, '0');
    final start = event.startAt;
    final end = event.endAt;
    return '${two(start.day)}/${two(start.month)}/${start.year} ${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.registration});

  final RegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registration.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: registration.status,
                color: const Color(0xFF0E6B5C),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${registration.ticketType.name} • ${registration.quantity} ticket(s)',
            style: const TextStyle(
              color: Color(0xFF5F645F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(
                label:
                    '${registration.event.venue}, ${registration.event.city}',
              ),
              _MetaLabel(
                label:
                    '${registration.event.startAt.day}/${registration.event.startAt.month}/${registration.event.startAt.year}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SponsorProfileCard extends StatelessWidget {
  const _SponsorProfileCard({
    required this.profile,
    required this.onEditProfile,
  });

  final SponsorProfileModel profile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.logoUrl != null && profile.logoUrl!.isNotEmpty) ...[
            _NetworkShowcase(
              imageUrl: profile.logoUrl!,
              semanticsLabel: profile.companyName,
              height: 152,
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.companyName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: profile.verified ? 'verified' : 'pending review',
                color: const Color(0xFF0E6B5C),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.description,
            style: const TextStyle(
              color: Color(0xFF5F645F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(label: profile.industries),
              if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty)
                _MetaLabel(label: profile.websiteUrl!),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onEditProfile,
                child: const Text('Edit profile'),
              ),
              if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty)
                OutlinedButton(
                  onPressed: () => launchUrlString(
                    profile.websiteUrl!,
                    mode: LaunchMode.platformDefault,
                  ),
                  child: const Text('Open website'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SponsorshipOpportunityCard extends StatelessWidget {
  const _SponsorshipOpportunityCard({
    required this.opportunity,
    required this.accent,
    this.actionLabel,
    this.secondaryActionLabel,
    this.onAction,
    this.onSecondaryAction,
  });

  final SponsorshipOpportunityModel opportunity;
  final Color accent;
  final String? actionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(label: opportunity.status, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            opportunity.event.title,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            opportunity.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(label: 'Target ${opportunity.requiredAmount}'),
              _MetaLabel(label: opportunity.targetAudience),
              _MetaLabel(
                label: '${opportunity.event.venue}, ${opportunity.event.city}',
              ),
              _MetaLabel(label: _formatOpportunityWindow(opportunity)),
            ],
          ),
          if ((actionLabel != null && onAction != null) ||
              (secondaryActionLabel != null && onSecondaryAction != null)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (actionLabel != null && onAction != null)
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SponsorshipInterestCard extends StatelessWidget {
  const _SponsorshipInterestCard({
    required this.interest,
    this.actionLabel,
    this.onAction,
  });

  final SponsorshipInterestModel interest;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  interest.opportunity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: interest.status,
                color: const Color(0xFF0E6B5C),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            interest.opportunity.event.title,
            style: const TextStyle(
              color: Color(0xFFCC7A00),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            interest.message,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(
                  label: 'Target ${interest.opportunity.requiredAmount}'),
              _MetaLabel(
                label:
                    '${interest.opportunity.event.venue}, ${interest.opportunity.event.city}',
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpportunityInterestsSheet extends StatelessWidget {
  const _OpportunityInterestsSheet({
    required this.opportunity,
    required this.interests,
    required this.onStartChat,
  });

  final SponsorshipOpportunityModel opportunity;
  final List<SponsorshipInterestModel> interests;
  final ValueChanged<SponsorshipInterestModel> onStartChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            opportunity.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Sponsors interested in ${opportunity.event.title}',
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 16),
          if (interests.isEmpty)
            const Text(
              'No sponsor interest has been submitted yet.',
              style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: interests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final interest = interests[index];
                  return _SponsorshipInterestCard(
                    interest: interest,
                    actionLabel: 'Chat with sponsor',
                    onAction: () => onStartChat(interest),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _VendorDiscoveryCard extends StatelessWidget {
  const _VendorDiscoveryCard({
    required this.vendor,
    this.actionLabel,
    this.secondaryActionLabel,
    this.onAction,
    this.onSecondaryAction,
  });

  final VendorProfileModel vendor;
  final String? actionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vendor.businessName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: vendor.verified ? 'verified' : vendor.category,
                color: const Color(0xFFCC7A00),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vendor.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(label: vendor.serviceArea),
              if (vendor.distanceKm != null)
                _MetaLabel(label: '${vendor.distanceKm!.toStringAsFixed(1)} km away'),
              if (vendor.travelRadiusKm != null)
                _MetaLabel(
                  label: 'travels ${vendor.travelRadiusKm!.toStringAsFixed(0)} km',
                ),
              if (vendor.withinTravelRadius != null)
                _MetaLabel(
                  label: vendor.withinTravelRadius! ? 'within travel radius' : 'outside travel radius',
                ),
              _MetaLabel(
                label: vendor.bookingPreference?.allowDirectBooking == true
                    ? 'direct booking'
                    : 'request booking',
              ),
              if (vendor.services.isNotEmpty)
                _MetaLabel(label: '${vendor.services.length} service(s)'),
            ],
          ),
          if ((actionLabel != null && onAction != null) ||
              (secondaryActionLabel != null && onSecondaryAction != null)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (actionLabel != null && onAction != null)
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NetworkShowcase extends StatelessWidget {
  const _NetworkShowcase({
    required this.imageUrl,
    required this.semanticsLabel,
    required this.height,
  });

  final String imageUrl;
  final String semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: semanticsLabel,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4ECE0),
                  Color(0xFFE8DDCD),
                ],
              ),
            ),
            child: const Text(
              'Preview unavailable',
              style: TextStyle(
                color: Color(0xFF6A655D),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VendorRequestCard extends StatelessWidget {
  const _VendorRequestCard({
    required this.vendorRequest,
    this.actionLabel,
    this.secondaryActionLabel,
    this.onAction,
    this.onSecondaryAction,
  });

  final VendorRequestModel vendorRequest;
  final String? actionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vendorRequest.vendor.businessName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: vendorRequest.status,
                color: vendorRequest.status == 'booked'
                    ? const Color(0xFF0E6B5C)
                    : vendorRequest.status == 'declined'
                        ? const Color(0xFFB3261E)
                        : const Color(0xFFCC7A00),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vendorRequest.event.title,
            style: const TextStyle(
              color: Color(0xFF0E6B5C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            vendorRequest.message,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(label: 'Budget ${vendorRequest.proposedBudget}'),
              _MetaLabel(
                label:
                    '${vendorRequest.event.venue}, ${vendorRequest.event.city}',
              ),
            ],
          ),
          if ((actionLabel != null && onAction != null) ||
              (secondaryActionLabel != null && onSecondaryAction != null)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (actionLabel != null && onAction != null)
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final counterpart = conversation.counterpartFor(currentUserId);
    final title = counterpart?.displayName ?? 'Conversation';
    final subtitle = conversation.lastMessage?.previewText ?? 'No messages yet';
    final activityTime =
        conversation.lastMessage?.createdAt ?? conversation.createdAt;
    final initial =
        title.trim().isEmpty ? 'M' : title.trim().characters.first.toUpperCase();
    final lastMessage = conversation.lastMessage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F5EF),
            ],
          ),
          border: Border.all(
            color: lastMessage?.isAssistant == true
                ? const Color(0x1F4F5BD5)
                : const Color(0x1F173B63),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: lastMessage?.isAssistant == true
                      ? const [
                          Color(0xFF4F5BD5),
                          Color(0xFF7A87FF),
                        ]
                      : const [
                          Color(0xFF173B63),
                          Color(0xFF145B52),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _formatRelativeTimestamp(activityTime),
                        style: const TextStyle(
                          color: Color(0xFF7A7369),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: counterpart?.role.name ?? conversation.type,
                        color: const Color(0xFF0E6B5C),
                      ),
                      if (lastMessage?.isAssistant == true)
                        const _StatusChip(
                          label: 'AI draft',
                          color: Color(0xFF4F5BD5),
                        ),
                      _MetaLabel(label: _formatCompactTimestamp(activityTime)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5F645F),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _RoleHomeScreenState {
  Future<T?> _pushWorkflowPage<T>(WidgetBuilder builder) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => WorkflowPageScaffold(
          child: builder(context),
        ),
      ),
    );
  }
}

String _formatCompactTimestamp(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)} ${two(value.hour)}:${two(value.minute)}';
}

String _formatRelativeTimestamp(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) {
    return 'now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d';
  }
  return _formatCompactTimestamp(value);
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({required this.ticket});

  final SupportTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F5EF),
          ],
        ),
        border: Border.all(color: const Color(0x1FB26B2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: ticket.status,
                color: ticket.escalation == null
                    ? const Color(0xFF0E6B5C)
                    : const Color(0xFFB3261E),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(label: ticket.category),
              _MetaLabel(label: 'priority ${ticket.priority}'),
              if (ticket.aiConfidence != null)
                _MetaLabel(label: 'confidence ${ticket.aiConfidence}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          if (ticket.assistantSuggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                ticket.assistantSuggestion!,
                style: const TextStyle(
                  color: Color(0xFF5F645F),
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (ticket.escalation != null) ...[
            const SizedBox(height: 12),
            Text(
              'Escalated: ${ticket.escalation!.reason}',
              style: const TextStyle(
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentCheckoutModel payment;

  @override
  Widget build(BuildContext context) {
    final paid = payment.payment.status == 'paid';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: paid
              ? const [
                  Color(0xFFF8FBF9),
                  Color(0xFFEAF4F0),
                ]
              : const [
                  Color(0xFFFFFCF8),
                  Color(0xFFF5EBDD),
                ],
        ),
        border: Border.all(
          color: paid ? const Color(0xFFBFD7CE) : const Color(0xFFE0D9CB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.registration.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(
                label: payment.payment.status,
                color: paid ? const Color(0xFF0E6B5C) : const Color(0xFFB3261E),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaLabel(
                label: '${payment.payment.currency} ${payment.payment.amount}',
              ),
              _MetaLabel(label: payment.registration.ticketType.name),
              _MetaLabel(label: payment.booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Provider ref: ${payment.payment.providerRef}',
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.reason,
    required this.score,
    required this.meta,
    required this.onTap,
  });

  final String title;
  final String reason;
  final double score;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0D9CB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(
                  label: 'score ${score.toStringAsFixed(2)}',
                  color: const Color(0xFF0E6B5C),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
            ),
            const SizedBox(height: 12),
            _MetaLabel(label: meta),
          ],
        ),
      ),
    );
  }
}

class _ChatConversationSheet extends StatefulWidget {
  const _ChatConversationSheet({
    required this.title,
    required this.messages,
    required this.currentUserId,
    required this.currentUserRole,
    required this.aiAssistEnabled,
    required this.isLoading,
    required this.isSending,
    required this.isDrafting,
    required this.onSend,
    required this.onGenerateDraft,
  });

  final String title;
  final List<ChatMessageModel> messages;
  final String currentUserId;
  final UserRole currentUserRole;
  final bool aiAssistEnabled;
  final bool isLoading;
  final bool isSending;
  final bool isDrafting;
  final Future<void> Function(String body) onSend;
  final Future<AiAssistantDraftModel> Function({
    required AiAssistantDraftIntent intent,
    String? prompt,
  }) onGenerateDraft;

  @override
  State<_ChatConversationSheet> createState() => _ChatConversationSheetState();
}

class _ChatConversationSheetState extends State<_ChatConversationSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant _ChatConversationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length ||
        oldWidget.isLoading != widget.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) {
      return;
    }
    try {
      await widget.onSend(body);
      if (mounted) {
        _messageController.clear();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send')),
      );
    }
  }

  Future<void> _requestDraft(AiAssistantDraftIntent intent) async {
    try {
      final draft = await widget.onGenerateDraft(
        intent: intent,
        prompt: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _messageController
        ..text = draft.content
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: draft.content.length),
        );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${draft.title} ready')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI draft failed')),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDrafts = <AiAssistantDraftIntent>[
      switch (widget.currentUserRole) {
        UserRole.vendor => AiAssistantDraftIntent.vendorProposal,
        UserRole.sponsor => AiAssistantDraftIntent.sponsorProposal,
        _ => AiAssistantDraftIntent.chatReply,
      },
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF173B63),
                    Color(0xFF145B52),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.forum_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.aiAssistEnabled
                                  ? 'Direct thread with AI drafting available'
                                  : 'Direct thread',
                              style: const TextStyle(
                                color: Color(0xFFE8F0EE),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.messages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              'No messages yet. Start the thread with a specific next step.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF5F645F),
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F3EB),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: widget.messages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final message = widget.messages[index];
                              final isMine =
                                  message.sender.userId == widget.currentUserId;
                              final bubbleColor = message.isSystem
                                  ? const Color(0xFFF4EFE3)
                                  : message.isAssistant
                                      ? const Color(0xFFF1F3FF)
                                      : isMine
                                          ? const Color(0xFF173B63)
                                          : Colors.white;
                              final textColor = isMine
                                  ? Colors.white
                                  : const Color(0xFF5F645F);

                              return Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.76,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: message.isAssistant
                                          ? const Color(0x334F5BD5)
                                          : isMine
                                              ? const Color(0x33173B63)
                                              : const Color(0x1F173B63),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x120F2030),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!isMine || message.isAssistant) ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                message.isAssistant
                                                    ? '${message.sender.displayName} AI'
                                                    : message.sender.displayName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: message.isAssistant
                                                      ? const Color(0xFF4F5BD5)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            if (message.isAssistant)
                                              const _StatusChip(
                                                label: 'AI',
                                                color: Color(0xFF4F5BD5),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Text(
                                        message.body,
                                        style: TextStyle(
                                          color: textColor,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatCompactTimestamp(message.createdAt),
                                        style: TextStyle(
                                          color: isMine
                                              ? const Color(0xCCE8F0EE)
                                              : const Color(0xFF7A7369),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            if (widget.aiAssistEnabled) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableDrafts
                      .map(
                        (intent) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: OutlinedButton.icon(
                            onPressed: widget.isDrafting
                                ? null
                                : () => _requestDraft(intent),
                            icon: Icon(
                              intent == AiAssistantDraftIntent.chatReply
                                  ? Icons.auto_awesome_rounded
                                  : Icons.description_rounded,
                            ),
                            label: Text(
                              widget.isDrafting
                                  ? 'Drafting...'
                                  : intent == AiAssistantDraftIntent.chatReply
                                      ? 'AI message draft'
                                      : 'AI proposal draft',
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Write a clear next step or use AI to draft one',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.isSending ? null : _submit,
                  child: Text(widget.isSending ? 'Sending...' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatOpportunityWindow(SponsorshipOpportunityModel opportunity) {
  String two(int value) => value.toString().padLeft(2, '0');
  final start = opportunity.event.startAt;
  final end = opportunity.event.endAt;
  return '${two(start.day)}/${two(start.month)}/${start.year} ${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
}

class _VendorProfileCard extends StatelessWidget {
  const _VendorProfileCard({
    required this.profile,
    required this.onEditProfile,
    required this.onAddService,
    required this.onAddPackage,
  });

  final VendorProfileModel profile;
  final VoidCallback onEditProfile;
  final VoidCallback onAddService;
  final VoidCallback onAddPackage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0D9CB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.portfolioImageUrl != null &&
                  profile.portfolioImageUrl!.isNotEmpty) ...[
                _NetworkShowcase(
                  imageUrl: profile.portfolioImageUrl!,
                  semanticsLabel: profile.businessName,
                  height: 168,
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.businessName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(
                    label: profile.verified ? 'verified' : profile.category,
                    color: const Color(0xFF0E6B5C),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile.description,
                style: const TextStyle(
                  color: Color(0xFF5F645F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MetaLabel(label: profile.serviceArea),
                  if (profile.travelRadiusKm != null)
                    _MetaLabel(
                      label:
                          'travels ${profile.travelRadiusKm!.toStringAsFixed(0)} km',
                    ),
                  _MetaLabel(
                    label: profile.bookingPreference?.allowDirectBooking == true
                        ? 'direct enabled'
                        : 'direct disabled',
                  ),
                  _MetaLabel(
                    label:
                        profile.bookingPreference?.allowRequestBooking == false
                            ? 'requests off'
                            : 'requests on',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: onEditProfile,
                    child: const Text('Edit profile'),
                  ),
                  OutlinedButton(
                    onPressed: onAddService,
                    child: const Text('Add service'),
                  ),
                  OutlinedButton(
                    onPressed: onAddPackage,
                    child: const Text('Add package'),
                  ),
                  if (profile.verificationDocumentUrl != null &&
                      profile.verificationDocumentUrl!.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => launchUrlString(
                        profile.verificationDocumentUrl!,
                        mode: LaunchMode.platformDefault,
                      ),
                      child: const Text('View verification'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (profile.services.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...profile.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VendorMiniCard(
                title: service.name,
                subtitle:
                    '${service.pricingModel} • ${service.basePrice}\n${service.description}',
              ),
            ),
          ),
        ],
        if (profile.packages.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Packages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...profile.packages.map(
            (vendorPackage) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VendorMiniCard(
                title: vendorPackage.name,
                subtitle:
                    '${vendorPackage.price}\n${vendorPackage.description}',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VendorMiniCard extends StatelessWidget {
  const _VendorMiniCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D9CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6DED1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF463F36),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
