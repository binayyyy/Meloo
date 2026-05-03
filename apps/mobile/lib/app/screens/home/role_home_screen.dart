import 'package:flutter/material.dart';
import '../../ai/ai_controller.dart';
import '../../ai/ai_models.dart';
import '../../chat/chat_controller.dart';
import '../../chat/chat_models.dart';
import '../../events/event_models.dart';
import '../../events/events_controller.dart';
import '../../notifications/notification_models.dart';
import '../../notifications/notifications_controller.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_controller.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../session/auth_scope.dart';
import '../../sponsors/sponsor_models.dart';
import '../../sponsors/sponsors_controller.dart';
import '../../support/support_controller.dart';
import '../../support/support_models.dart';
import '../../vendors/vendor_models.dart';
import '../../vendors/vendors_controller.dart';
import '../../widgets/brand_lockup.dart';
import '../../widgets/remote_media.dart';
import '../../widgets/workflow_page_scaffold.dart';
import '../../router.dart';
import '../chat/chat_hub_screen.dart';
import '../chat/conversation_screen.dart';
import '../platform_access_blocked_screen.dart';
import 'event_detail_screen.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/create_sponsorship_opportunity_sheet.dart';
import 'widgets/create_support_ticket_sheet.dart';
import 'widgets/create_vendor_package_sheet.dart';
import 'widgets/create_vendor_request_sheet.dart';
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

  final Set<String> _loadedTabs = <String>{};
  final Set<String> _loadingTabs = <String>{};

  int _selectedTab = 0;
  String? _loadedForAccessToken;
  bool _didPresentEntryAction = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context).session;
    final accessToken = session?.tokens.accessToken;

    if (session == null || accessToken == null) {
      return;
    }

    if (accessToken != _loadedForAccessToken) {
      _loadedForAccessToken = accessToken;
      _didPresentEntryAction = false;
      _loadedTabs.clear();
      _loadingTabs.clear();
      _selectedTab = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await _loadTab(session, _selectedTab, force: true);
        await _maybePresentEntryAction(session);
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

  Future<void> _maybePresentEntryAction(AuthSession session) async {
    if (_didPresentEntryAction) {
      return;
    }

    final entrySheet = Uri.base.queryParameters['entry_sheet'];
    if (entrySheet == null || entrySheet.isEmpty) {
      return;
    }

    _didPresentEntryAction = true;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }

    switch (entrySheet) {
      case 'create-event':
        await _openCreateEventSheet(session);
        return;
      case 'vendor-profile':
        await _loadVendorRoleData(session);
        await _openVendorProfileSheet(session);
        return;
      case 'vendor-service':
        await _loadVendorRoleData(session);
        await _openVendorServiceSheet(session);
        return;
      case 'vendor-package':
        await _loadVendorRoleData(session);
        await _openVendorPackageSheet(session);
        return;
      case 'support-ticket':
        await _openCreateSupportTicketSheet(session);
        return;
      case 'planning-assistant':
        await _loadOrganizerRoleData(session);
        await _openPlanningAssistantSheet(session);
        return;
      case 'sponsor-profile':
        await _loadSponsorRoleData(session);
        await _openSponsorProfileSheet(session);
        return;
      case 'sponsor-opportunity':
        await _loadOrganizerRoleData(session);
        await _openCreateOpportunitySheet(session);
        return;
      case 'sponsor-interest':
        await _loadSponsorRoleData(session);
        final opportunity = _sponsorsController.openOpportunities.isNotEmpty
            ? _sponsorsController.openOpportunities.first
            : null;
        if (opportunity != null) {
          await _openExpressInterestSheet(session, opportunity);
        }
        return;
      case 'conversation':
        await _openChatHub(session);
        return;
      default:
        return;
    }
  }

  Future<void> _loadTab(
    AuthSession session,
    int tabIndex, {
    bool force = false,
  }) async {
    final key = _tabKey(session, tabIndex);
    if (_loadingTabs.contains(key)) {
      return;
    }
    if (!force && _loadedTabs.contains(key)) {
      return;
    }

    setState(() => _loadingTabs.add(key));
    try {
      switch (tabIndex) {
        case 0:
          await _loadExploreData(session);
          break;
        case 1:
          await _loadWorkspaceData(session);
          break;
        case 2:
          await _loadInboxData(session);
          break;
        case 3:
          await _loadProfileData(session);
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTabs.remove(key);
          _loadedTabs.add(key);
        });
      }
    }
  }

  Future<void> _refreshCurrentTab(AuthSession session) {
    return _loadTab(session, _selectedTab, force: true);
  }

  Future<void> _loadExploreData(AuthSession session) async {
    await _eventsController.load(session);

    switch (session.user.role) {
      case UserRole.organizer:
        await _loadOrganizerRoleData(session);
        return;
      case UserRole.sponsor:
        await Future.wait([
          _sponsorsController.load(session),
          _aiController.load(session),
        ]);
        return;
      case UserRole.vendor:
        return;
      case UserRole.attendee:
        return;
      case UserRole.admin:
        return;
    }
  }

  Future<void> _loadWorkspaceData(AuthSession session) async {
    switch (session.user.role) {
      case UserRole.attendee:
        await Future.wait([
          _eventsController.load(session),
          _paymentsController.load(session),
        ]);
        return;
      case UserRole.organizer:
        await _loadOrganizerRoleData(session);
        return;
      case UserRole.vendor:
        await _loadVendorRoleData(session);
        return;
      case UserRole.sponsor:
        await _loadSponsorRoleData(session);
        return;
      case UserRole.admin:
        return;
    }
  }

  Future<void> _loadInboxData(AuthSession session) async {
    await Future.wait([
      _notificationsController.load(session),
      _supportController.load(session),
    ]);
  }

  Future<void> _loadProfileData(AuthSession session) async {
    switch (session.user.role) {
      case UserRole.vendor:
        await _loadVendorRoleData(session);
        return;
      case UserRole.sponsor:
        await _loadSponsorRoleData(session);
        return;
      case UserRole.organizer:
      case UserRole.attendee:
      case UserRole.admin:
        return;
    }
  }

  Future<void> _loadOrganizerRoleData(AuthSession session) async {
    if (!_eventsController.hasLoaded) {
      await _eventsController.load(session);
    }
    final focusEvent =
        _eventsController.myEvents.isNotEmpty ? _eventsController.myEvents.first : null;
    await Future.wait([
      _vendorsController.load(session, focusEvent: focusEvent),
      _sponsorsController.load(session),
      _aiController.load(session, organizerEventId: focusEvent?.id),
    ]);
  }

  Future<void> _loadVendorRoleData(AuthSession session) async {
    await _vendorsController.load(session);
  }

  Future<void> _loadSponsorRoleData(AuthSession session) async {
    await _sponsorsController.load(session);
  }

  Future<void> _openCreateEventSheet(AuthSession session) async {
    await _eventsController.refreshCategories();
    if (_eventsController.categories.isEmpty && !_eventsController.hasLoaded) {
      await _eventsController.load(session);
    }
    if (_eventsController.categories.isEmpty) {
      _showSnack('Event categories are unavailable right now.');
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
                await _eventsController.load(session);
                if (mounted) {
                  _showSnack(
                    _eventsController.successMessage ?? 'Event saved.',
                  );
                  _loadedTabs.remove(_tabKey(session, 0));
                  _loadedTabs.remove(_tabKey(session, 1));
                }
                return true;
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _eventsController.errorMessage ?? 'Event save failed.',
                  );
                }
                return false;
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
    }
  }

  Future<void> _openEditProfileSheet(AuthSession session) async {
    final authController = AuthScope.of(context);

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
                _showSnack('Profile updated.');
              }
            },
          );
        },
      );
    });
  }

  Future<void> _openVendorProfileSheet(AuthSession session) async {
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
                  _showSnack(
                    _vendorsController.successMessage ?? 'Vendor profile saved.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _vendorsController.errorMessage ??
                        'Vendor profile update failed.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
      await _loadTab(session, 3, force: true);
    }
  }

  Future<void> _openVendorServiceSheet(AuthSession session) async {
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
                  _showSnack(
                    _vendorsController.successMessage ?? 'Service added.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _vendorsController.errorMessage ?? 'Unable to add service.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
    }
  }

  Future<void> _openVendorPackageSheet(AuthSession session) async {
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
                  _showSnack(
                    _vendorsController.successMessage ?? 'Package added.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _vendorsController.errorMessage ?? 'Unable to add package.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
    }
  }

  Future<void> _openVendorRequestSheet(
    AuthSession session,
    VendorProfileModel vendor,
  ) async {
    if (_eventsController.myEvents.isEmpty) {
      await _loadOrganizerRoleData(session);
    }
    if (_eventsController.myEvents.isEmpty) {
      _showSnack('Create an event before reaching out to vendors.');
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
                  _showSnack(
                    _vendorsController.successMessage ?? 'Request sent.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _vendorsController.errorMessage ??
                        'Unable to send vendor request.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
    }
  }

  Future<void> _openCreateSupportTicketSheet(AuthSession session) async {
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
                  _showSnack(
                    _supportController.successMessage ?? 'Support ticket created.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _supportController.errorMessage ??
                        'Unable to create support ticket.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 2, force: true);
    }
  }

  Future<void> _openPlanningAssistantSheet(AuthSession session) async {
    if (_eventsController.myEvents.isEmpty) {
      await _eventsController.load(session);
    }

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
                  _showSnack('Planning brief ready.');
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _aiController.errorMessage ??
                        'Unable to generate a planning brief.',
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
                  _showSnack(
                    _sponsorsController.successMessage ?? 'Sponsor profile saved.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _sponsorsController.errorMessage ??
                        'Unable to update sponsor profile.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
      await _loadTab(session, 3, force: true);
    }
  }

  Future<void> _openCreateOpportunitySheet(AuthSession session) async {
    if (_eventsController.myEvents.isEmpty) {
      await _eventsController.load(session);
    }
    if (_eventsController.myEvents.isEmpty) {
      _showSnack('Create an event before opening sponsor packages.');
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
                  _showSnack(
                    _sponsorsController.successMessage ??
                        'Sponsorship opportunity created.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _sponsorsController.errorMessage ??
                        'Unable to create sponsorship opportunity.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
      await _loadTab(session, 0, force: true);
    }
  }

  Future<void> _openExpressInterestSheet(
    AuthSession session,
    SponsorshipOpportunityModel opportunity,
  ) async {
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
                  _showSnack(
                    _sponsorsController.successMessage ?? 'Interest submitted.',
                  );
                }
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _sponsorsController.errorMessage ??
                        'Unable to submit interest.',
                  );
                }
              }
            },
          );
        },
      );
    });

    if (mounted) {
      await _loadTab(session, 1, force: true);
      await _loadTab(session, 0, force: true);
    }
  }

  Future<void> _openDirectConversation(
    AuthSession session, {
    required String participantUserId,
    required String participantLabel,
  }) async {
    try {
      final conversation = await _chatController.createDirectConversation(
        session,
        participantUserId,
      );
      if (!mounted) {
        return;
      }
      await _openConversationScreen(
        session,
        conversation,
        title: participantLabel,
      );
    } on ApiException {
      if (mounted) {
        _showSnack(
          _chatController.errorMessage ?? 'Unable to open conversation.',
        );
      }
    }
  }

  Future<void> _openChatHub(AuthSession session) async {
    await _chatController.load(session);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return ChatHubScreen(
            controller: _chatController,
            session: session,
            onOpenConversation: (
              conversation, {
              String? title,
            }) =>
                _openConversationScreen(
              session,
              conversation,
              title: title,
            ),
            onStartConversationByEmail: (participantEmail) async {
              final conversation = await _chatController
                  .createDirectConversationByEmail(session, participantEmail);
              if (!context.mounted) {
                return;
              }
              await _openConversationScreen(
                session,
                conversation,
                title: _chatController
                    .counterpartFor(conversation)
                    ?.displayName,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openConversationScreen(
    AuthSession session,
    ConversationModel conversation, {
    String? title,
  }) async {
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
                  aiAssistEnabled:
                      session.user.settings?.aiAssistEnabled ?? false,
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
        _showSnack(
          _chatController.errorMessage ?? 'Unable to load conversation.',
        );
      }
    }
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
      await _loadTab(session, 0, force: true);
      await _loadTab(session, 1, force: true);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

    if (user.role == UserRole.admin) {
      return PlatformAccessBlockedScreen(
        onSignOut: authController.signOut,
      );
    }

    final palette = _paletteForRole(user.role);
    final tabKey = _tabKey(session, _selectedTab);
    final isFirstLoad = _loadingTabs.contains(tabKey) && !_loadedTabs.contains(tabKey);

    return Scaffold(
      backgroundColor: palette.canvasTop,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _openChatHub(session),
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        tooltip: 'Messages',
        child: const Icon(Icons.forum_outlined),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == _selectedTab) {
            return;
          }
          setState(() => _selectedTab = index);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadTab(session, index);
            }
          });
        },
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: palette.accent.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_customize_rounded),
            label: 'Workspace',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_active_rounded),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      body: DecoratedBox(
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
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -60,
                child: _SoftOrb(
                  size: 240,
                  color: palette.accent.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: -50,
                bottom: 80,
                child: _SoftOrb(
                  size: 200,
                  color: palette.support.withValues(alpha: 0.08),
                ),
              ),
              Column(
                children: [
                  _ShellTopBar(
                    title: _pageTitleForTab(_selectedTab),
                    subtitle: _pageSubtitleForTab(user.role, _selectedTab),
                    palette: palette,
                    roleLabel: _workspaceLabelForRole(user.role),
                    onLogout: authController.signOut,
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _aiController,
                        _chatController,
                        _eventsController,
                        _notificationsController,
                        _paymentsController,
                        _supportController,
                        _sponsorsController,
                        _vendorsController,
                        authController,
                      ]),
                      builder: (context, _) {
                        if (isFirstLoad) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildTabPage(
                            key: ValueKey('${user.role.name}-$_selectedTab'),
                            session: session,
                            user: user,
                            palette: palette,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPage({
    required Key key,
    required AuthSession session,
    required UserModel user,
    required _RolePalette palette,
  }) {
    final metrics = _metricsForPage(user.role, _selectedTab);
    final banners = _messagesForPage(user.role, _selectedTab);

    return RefreshIndicator(
      key: key,
      onRefresh: () => _refreshCurrentTab(session),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 128),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _PageHeroCard(
            title: _pageTitleForTab(_selectedTab),
            subtitle: _pageSubtitleForTab(user.role, _selectedTab),
            palette: palette,
            metrics: metrics,
            actions: _pageActions(session, user.role),
          ),
          for (final banner in banners)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _BannerCard(message: banner),
            ),
          const SizedBox(height: 12),
          ...switch (_selectedTab) {
            0 => _buildExploreSections(session, user.role, palette),
            1 => _buildWorkspaceSections(session, user.role, palette),
            2 => _buildInboxSections(session, user.role, palette),
            _ => _buildProfileSections(session, user, palette),
          },
        ],
      ),
    );
  }

  List<_HeroMetric> _metricsForPage(UserRole role, int tabIndex) {
    switch (tabIndex) {
      case 0:
        switch (role) {
          case UserRole.attendee:
            return [
              _HeroMetric('Events', _eventsController.publicEvents.length.toString()),
              _HeroMetric('Saved', _eventsController.favoriteEvents.length.toString()),
              _HeroMetric(
                'Registered',
                _eventsController.myRegistrations.length.toString(),
              ),
            ];
          case UserRole.organizer:
            return [
              _HeroMetric('Events', _eventsController.myEvents.length.toString()),
              _HeroMetric(
                'Vendors',
                _vendorsController.publicVendors.length.toString(),
              ),
              _HeroMetric(
                'Open deals',
                _sponsorsController.openOpportunities.length.toString(),
              ),
            ];
          case UserRole.vendor:
            return [
              _HeroMetric('Events', _eventsController.publicEvents.length.toString()),
              _HeroMetric(
                'Cities',
                _eventsController.publicEvents
                    .map((event) => event.city)
                    .toSet()
                    .length
                    .toString(),
              ),
              _HeroMetric(
                'Categories',
                _eventsController.publicEvents
                    .map((event) => event.category.name)
                    .toSet()
                    .length
                    .toString(),
              ),
            ];
          case UserRole.sponsor:
            return [
              _HeroMetric(
                'Open deals',
                _sponsorsController.openOpportunities.length.toString(),
              ),
              _HeroMetric(
                'AI matches',
                _aiController.recommendedOpportunities.length.toString(),
              ),
              _HeroMetric('Events', _eventsController.publicEvents.length.toString()),
            ];
          case UserRole.admin:
            return const [];
        }
      case 1:
        switch (role) {
          case UserRole.attendee:
            return [
              _HeroMetric(
                'Tickets',
                _eventsController.myRegistrations.length.toString(),
              ),
              _HeroMetric('Payments', _paymentsController.payments.length.toString()),
              _HeroMetric(
                'Favorites',
                _eventsController.favoriteEvents.length.toString(),
              ),
            ];
          case UserRole.organizer:
            return [
              _HeroMetric('My events', _eventsController.myEvents.length.toString()),
              _HeroMetric(
                'Vendor reqs',
                _vendorsController.myOrganizerRequests.length.toString(),
              ),
              _HeroMetric(
                'Sponsor ops',
                _sponsorsController.myOpportunities.length.toString(),
              ),
            ];
          case UserRole.vendor:
            return [
              _HeroMetric(
                'Requests',
                _vendorsController.myVendorRequests.length.toString(),
              ),
              _HeroMetric(
                'Services',
                (_vendorsController.myVendorProfile?.services.length ?? 0)
                    .toString(),
              ),
              _HeroMetric(
                'Packages',
                (_vendorsController.myVendorProfile?.packages.length ?? 0)
                    .toString(),
              ),
            ];
          case UserRole.sponsor:
            return [
              _HeroMetric(
                'Interests',
                _sponsorsController.myInterests.length.toString(),
              ),
              _HeroMetric(
                'Open deals',
                _sponsorsController.openOpportunities.length.toString(),
              ),
              _HeroMetric(
                'Verified',
                _sponsorsController.mySponsorProfile?.verified == true
                    ? 'Yes'
                    : 'No',
              ),
            ];
          case UserRole.admin:
            return const [];
        }
      case 2:
        return [
          _HeroMetric(
            'Unread',
            _notificationsController.unreadCount.toString(),
          ),
          _HeroMetric(
            'Tickets',
            _supportController.tickets.length.toString(),
          ),
          _HeroMetric(
            'Escalated',
            _supportController.tickets
                .where((ticket) => ticket.escalation != null)
                .length
                .toString(),
          ),
        ];
      default:
        return [
          _HeroMetric('Role', role.name.toUpperCase()),
          _HeroMetric(
            'Alerts',
            (AuthScope.of(context).session?.user.settings?.notificationsEnabled ??
                    true)
                ? 'On'
                : 'Off',
          ),
          _HeroMetric(
            'AI',
            (AuthScope.of(context).session?.user.settings?.aiAssistEnabled ??
                    false)
                ? 'On'
                : 'Off',
          ),
        ];
    }
  }

  List<String> _messagesForPage(UserRole role, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return [
          if (_eventsController.errorMessage != null)
            _eventsController.errorMessage!,
          if (role == UserRole.organizer &&
              _vendorsController.errorMessage != null)
            _vendorsController.errorMessage!,
          if ((role == UserRole.organizer || role == UserRole.sponsor) &&
              _sponsorsController.errorMessage != null)
            _sponsorsController.errorMessage!,
          if ((role == UserRole.organizer || role == UserRole.sponsor) &&
              _aiController.errorMessage != null)
            _aiController.errorMessage!,
        ];
      case 1:
        return [
          if (_eventsController.errorMessage != null &&
              (role == UserRole.attendee || role == UserRole.organizer))
            _eventsController.errorMessage!,
          if (_paymentsController.errorMessage != null &&
              role == UserRole.attendee)
            _paymentsController.errorMessage!,
          if (_vendorsController.errorMessage != null &&
              (role == UserRole.organizer || role == UserRole.vendor))
            _vendorsController.errorMessage!,
          if (_sponsorsController.errorMessage != null &&
              (role == UserRole.organizer || role == UserRole.sponsor))
            _sponsorsController.errorMessage!,
          if (_aiController.errorMessage != null && role == UserRole.organizer)
            _aiController.errorMessage!,
        ];
      case 2:
        return [
          if (_notificationsController.errorMessage != null)
            _notificationsController.errorMessage!,
          if (_supportController.errorMessage != null)
            _supportController.errorMessage!,
        ];
      default:
        return const [];
    }
  }

  List<Widget> _pageActions(AuthSession session, UserRole role) {
    switch (_selectedTab) {
      case 0:
        switch (role) {
          case UserRole.organizer:
            return [
              _ActionButton(
                label: 'New event',
                icon: Icons.add_circle_outline_rounded,
                onTap: () => _openCreateEventSheet(session),
              ),
              _ActionButton(
                label: 'Plan',
                icon: Icons.auto_awesome_rounded,
                onTap: () => _openPlanningAssistantSheet(session),
              ),
            ];
          case UserRole.sponsor:
            return [
              _ActionButton(
                label: 'Profile',
                icon: Icons.business_center_outlined,
                onTap: () => _openSponsorProfileSheet(session),
              ),
            ];
          case UserRole.vendor:
            return [
              _ActionButton(
                label: 'Profile',
                icon: Icons.storefront_outlined,
                onTap: () => _openVendorProfileSheet(session),
              ),
            ];
          case UserRole.attendee:
            return [
              _ActionButton(
                label: 'Support',
                icon: Icons.support_agent_rounded,
                onTap: () => _openCreateSupportTicketSheet(session),
              ),
            ];
          case UserRole.admin:
            return const [];
        }
      case 1:
        switch (role) {
          case UserRole.organizer:
            return [
              _ActionButton(
                label: 'New event',
                icon: Icons.event_available_rounded,
                onTap: () => _openCreateEventSheet(session),
              ),
              _ActionButton(
                label: 'Sponsor package',
                icon: Icons.campaign_outlined,
                onTap: () => _openCreateOpportunitySheet(session),
              ),
            ];
          case UserRole.vendor:
            return [
              _ActionButton(
                label: 'Add service',
                icon: Icons.tune_rounded,
                onTap: () => _openVendorServiceSheet(session),
              ),
              _ActionButton(
                label: 'Add package',
                icon: Icons.inventory_2_outlined,
                onTap: () => _openVendorPackageSheet(session),
              ),
            ];
          case UserRole.sponsor:
            return [
              _ActionButton(
                label: 'Edit brand',
                icon: Icons.apartment_rounded,
                onTap: () => _openSponsorProfileSheet(session),
              ),
            ];
          case UserRole.attendee:
            return [
              _ActionButton(
                label: 'Support',
                icon: Icons.support_agent_rounded,
                onTap: () => _openCreateSupportTicketSheet(session),
              ),
            ];
          case UserRole.admin:
            return const [];
        }
      case 2:
        return [
          _ActionButton(
            label: 'New ticket',
            icon: Icons.add_comment_outlined,
            onTap: () => _openCreateSupportTicketSheet(session),
          ),
          if (_notificationsController.unreadCount > 0)
            _ActionButton(
              label: 'Mark all read',
              icon: Icons.done_all_rounded,
              onTap: () async {
                try {
                  await _notificationsController.markAllRead(session);
                  if (mounted) {
                    _showSnack('Notifications cleared.');
                  }
                } on ApiException {
                  if (mounted) {
                    _showSnack(
                      _notificationsController.errorMessage ??
                          'Unable to update notifications.',
                    );
                  }
                }
              },
            ),
        ];
      default:
        return [
          _ActionButton(
            label: 'Edit profile',
            icon: Icons.edit_outlined,
            onTap: () => _openEditProfileSheet(session),
          ),
        ];
    }
  }

  List<Widget> _buildExploreSections(
    AuthSession session,
    UserRole role,
    _RolePalette palette,
  ) {
    switch (role) {
      case UserRole.attendee:
        return [
          _SectionBlock(
            title: 'Upcoming events',
            subtitle: 'Live events worth booking next.',
            child: _EventList(
              events: _eventsController.publicEvents.take(5).toList(),
              manageMode: false,
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Saved',
            subtitle: 'Events you marked for later.',
            child: _EventList(
              events: _eventsController.favoriteEvents.take(3).toList(),
              manageMode: false,
              emptyMessage: 'Favorite events will land here.',
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Recently viewed',
            subtitle: 'Jump back into events you opened.',
            child: _EventList(
              events: _eventsController.recentlyViewedEvents.take(3).toList(),
              manageMode: false,
              emptyMessage: 'Viewed events will appear here.',
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
        ];
      case UserRole.organizer:
        return [
          _SectionBlock(
            title: 'Public event market',
            subtitle: 'Benchmark timing and positioning.',
            child: _EventList(
              events: _eventsController.publicEvents.take(4).toList(),
              manageMode: false,
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Vendor shortlist',
            subtitle: 'Move from discovery into outreach.',
            child: _VendorList(
              vendors: _vendorsController.publicVendors.take(4).toList(),
              onMessage: (vendor) => _openDirectConversation(
                session,
                participantUserId: vendor.userId,
                participantLabel: vendor.businessName,
              ),
              onPrimaryAction: (vendor) => _openVendorRequestSheet(
                session,
                vendor,
              ),
              primaryActionLabel: 'Request quote',
            ),
          ),
          _SectionBlock(
            title: 'AI vendor fit',
            subtitle: 'Priority matches for your current event context.',
            child: _AiVendorList(
              recommendations: _aiController.recommendedVendors.take(3).toList(),
              onOpenVendor: (vendor) => _openDirectConversation(
                session,
                participantUserId: vendor.userId,
                participantLabel: vendor.businessName,
              ),
            ),
          ),
        ];
      case UserRole.vendor:
        final cityInsights = _eventsController.publicEvents
            .map((event) => event.city)
            .toSet()
            .take(8)
            .toList(growable: false);
        final categoryInsights = _eventsController.publicEvents
            .map((event) => event.category.name)
            .toSet()
            .take(8)
            .toList(growable: false);
        return [
          _SectionBlock(
            title: 'Event opportunities',
            subtitle: 'Live events you can pitch right now.',
            child: _EventList(
              events: _eventsController.publicEvents.take(5).toList(),
              manageMode: false,
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Demand by city',
            subtitle: 'Use city concentration to guide outreach.',
            child: _InsightWrap(
              values: cityInsights,
              emptyMessage: 'City signals will appear when events are live.',
            ),
          ),
          _SectionBlock(
            title: 'Active categories',
            subtitle: 'Use the category mix to sharpen packaging.',
            child: _InsightWrap(
              values: categoryInsights,
              emptyMessage:
                  'Category signals will appear when events are published.',
            ),
          ),
        ];
      case UserRole.sponsor:
        return [
          _SectionBlock(
            title: 'Open sponsorships',
            subtitle: 'Packages currently open for review.',
            child: _OpportunityList(
              opportunities:
                  _sponsorsController.openOpportunities.take(4).toList(),
              onPrimaryAction: (opportunity) => _openExpressInterestSheet(
                session,
                opportunity,
              ),
              primaryActionLabel: 'Express interest',
            ),
          ),
          _SectionBlock(
            title: 'Ranked matches',
            subtitle: 'AI surfaced the strongest-fit opportunities.',
            child: _AiOpportunityList(
              recommendations: _aiController.recommendedOpportunities
                  .take(3)
                  .toList(),
              onPrimaryAction: (opportunity) => _openExpressInterestSheet(
                session,
                opportunity,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Event slate',
            subtitle: 'Stay close to the live event slate.',
            child: _EventList(
              events: _eventsController.publicEvents.take(3).toList(),
              manageMode: false,
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
        ];
      case UserRole.admin:
        return const [];
    }
  }

  List<Widget> _buildWorkspaceSections(
    AuthSession session,
    UserRole role,
    _RolePalette palette,
  ) {
    switch (role) {
      case UserRole.attendee:
        return [
          _SectionBlock(
            title: 'Tickets',
            subtitle: 'Every confirmed registration in one place.',
            child: _RegistrationList(
              registrations: _eventsController.myRegistrations,
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: false,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Payments',
            subtitle: 'Track completed and pending checkouts.',
            child: _PaymentList(payments: _paymentsController.payments),
          ),
        ];
      case UserRole.organizer:
        return [
          _SectionBlock(
            title: 'My events',
            subtitle: 'Live and draft events you control.',
            child: _EventList(
              events: _eventsController.myEvents,
              manageMode: true,
              emptyMessage: 'Create your first event to start your workspace.',
              onOpen: (eventId) => _openEventDetail(
                session,
                eventId,
                manageMode: true,
              ),
            ),
          ),
          _SectionBlock(
            title: 'Vendor requests',
            subtitle: 'Requests already sent and still moving.',
            child: _VendorRequestList(
              requests: _vendorsController.myOrganizerRequests,
            ),
          ),
          _SectionBlock(
            title: 'Sponsor packages',
            subtitle: 'Opportunities currently available to brands.',
            child: _OpportunityList(
              opportunities: _sponsorsController.myOpportunities,
              emptyMessage: 'Create an opportunity to start sponsor outreach.',
            ),
          ),
          if (_aiController.planningBrief != null)
            _SectionBlock(
              title: 'Planning brief',
              subtitle: 'Latest assistant output for your plan.',
              child: _PlanningBriefCard(brief: _aiController.planningBrief!),
            ),
        ];
      case UserRole.vendor:
        final profile = _vendorsController.myVendorProfile;
        return [
          _SectionBlock(
            title: 'Business profile',
            subtitle: 'How organizers see your storefront.',
            child: profile == null
                ? _EmptyCard(
                    message:
                        'Set up your vendor profile to show services, proof, and travel coverage.',
                    actionLabel: 'Create profile',
                    onAction: () => _openVendorProfileSheet(session),
                  )
                : _VendorProfileSummaryCard(
                    profile: profile,
                    onEdit: () => _openVendorProfileSheet(session),
                  ),
          ),
          _SectionBlock(
            title: 'Incoming requests',
            subtitle: 'Active organizer demand and booking conversations.',
            child: _VendorRequestList(
              requests: _vendorsController.myVendorRequests,
            ),
          ),
          if (profile != null)
            _SectionBlock(
              title: 'Services and packages',
              subtitle: 'Keep offers current and easy to scan.',
              child: _VendorOfferSummary(
                profile: profile,
                onAddService: () => _openVendorServiceSheet(session),
                onAddPackage: () => _openVendorPackageSheet(session),
              ),
            ),
        ];
      case UserRole.sponsor:
        return [
          _SectionBlock(
            title: 'Brand profile',
            subtitle: 'What organizers see first.',
            child: _sponsorsController.mySponsorProfile == null
                ? _EmptyCard(
                    message:
                        'Create a sponsor profile so organizers can evaluate fit quickly.',
                    actionLabel: 'Create profile',
                    onAction: () => _openSponsorProfileSheet(session),
                  )
                : _SponsorProfileSummaryCard(
                    profile: _sponsorsController.mySponsorProfile!,
                    onEdit: () => _openSponsorProfileSheet(session),
                  ),
          ),
          _SectionBlock(
            title: 'Submitted interests',
            subtitle: 'Every opportunity you have already stepped into.',
            child: _InterestList(
              interests: _sponsorsController.myInterests,
            ),
          ),
          _SectionBlock(
            title: 'Priority matches',
            subtitle: 'Keep the next best-fit opportunities moving.',
            child: _AiOpportunityList(
              recommendations: _aiController.recommendedOpportunities
                  .take(3)
                  .toList(),
              onPrimaryAction: (opportunity) => _openExpressInterestSheet(
                session,
                opportunity,
              ),
            ),
          ),
        ];
      case UserRole.admin:
        return const [];
    }
  }

  List<Widget> _buildInboxSections(
    AuthSession session,
    UserRole role,
    _RolePalette palette,
  ) {
    return [
      _SectionBlock(
        title: 'Notifications',
        subtitle: 'System activity and workflow changes.',
        child: _NotificationList(
          notifications: _notificationsController.notifications,
          onTap: (notification) async {
            if (notification.unread) {
              try {
                await _notificationsController.markRead(session, notification.id);
              } on ApiException {
                if (mounted) {
                  _showSnack(
                    _notificationsController.errorMessage ??
                        'Unable to update notification.',
                  );
                }
              }
            }
          },
        ),
      ),
      _SectionBlock(
        title: 'Support',
        subtitle: 'Open tickets and escalation status.',
        child: _SupportTicketList(tickets: _supportController.tickets),
      ),
    ];
  }

  List<Widget> _buildProfileSections(
    AuthSession session,
    UserModel user,
    _RolePalette palette,
  ) {
    return [
      _SectionBlock(
        title: 'Account',
        subtitle: '',
        child: _AccountCard(
          user: user,
          palette: palette,
          onEdit: () => _openEditProfileSheet(session),
        ),
      ),
      _SectionBlock(
        title: 'Preferences',
        subtitle: '',
        child: _PreferenceGrid(user: user),
      ),
      _SectionBlock(
        title: _roleProfileSectionTitle(user.role),
        subtitle: _roleProfileSectionSubtitle(user.role),
        child: _RoleProfileActions(
          role: user.role,
          vendorProfile: _vendorsController.myVendorProfile,
          sponsorProfile: _sponsorsController.mySponsorProfile,
          onPrimaryAction: () {
            switch (user.role) {
              case UserRole.organizer:
                _openCreateEventSheet(session);
                return;
              case UserRole.vendor:
                _openVendorProfileSheet(session);
                return;
              case UserRole.sponsor:
                _openSponsorProfileSheet(session);
                return;
              case UserRole.attendee:
                _openCreateSupportTicketSheet(session);
                return;
              case UserRole.admin:
                return;
            }
          },
          onSecondaryAction: () {
            switch (user.role) {
              case UserRole.organizer:
                _openPlanningAssistantSheet(session);
                return;
              case UserRole.vendor:
                _openVendorServiceSheet(session);
                return;
              case UserRole.sponsor:
                final opportunity =
                    _sponsorsController.openOpportunities.isNotEmpty
                        ? _sponsorsController.openOpportunities.first
                        : null;
                if (opportunity != null) {
                  _openExpressInterestSheet(session, opportunity);
                } else {
                  _showSnack('No open sponsor opportunities are available yet.');
                }
                return;
              case UserRole.attendee:
                _openChatHub(session);
                return;
              case UserRole.admin:
                return;
            }
          },
        ),
      ),
    ];
  }

  String _roleProfileSectionTitle(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return 'Member tools';
      case UserRole.organizer:
        return 'Organizer controls';
      case UserRole.vendor:
        return 'Vendor storefront';
      case UserRole.sponsor:
        return 'Brand presence';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _roleProfileSectionSubtitle(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return 'Fast access to support and conversations.';
      case UserRole.organizer:
        return 'Launch events and keep planning moving.';
      case UserRole.vendor:
        return 'Keep your profile, services, and packages current.';
      case UserRole.sponsor:
        return 'Maintain the sponsor story shown to organizers.';
      case UserRole.admin:
        return 'Admin access is web only.';
    }
  }

  String _pageTitleForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Explore';
      case 1:
        return 'Workspace';
      case 2:
        return 'Inbox';
      default:
        return 'Profile';
    }
  }

  String _pageSubtitleForTab(UserRole role, int tabIndex) {
    switch (tabIndex) {
      case 0:
        switch (role) {
          case UserRole.attendee:
            return 'Find what is worth attending.';
          case UserRole.organizer:
            return 'Track events, vendors, and sponsor demand.';
          case UserRole.vendor:
            return 'See where demand is building.';
          case UserRole.sponsor:
            return 'Review live sponsor openings.';
          case UserRole.admin:
            return 'Admin is handled on web.';
        }
      case 1:
        switch (role) {
          case UserRole.attendee:
            return 'Your tickets and payment activity.';
          case UserRole.organizer:
            return 'Run your event pipeline in one place.';
          case UserRole.vendor:
            return 'Manage your storefront and incoming work.';
          case UserRole.sponsor:
            return 'Keep brand details and active interests moving.';
          case UserRole.admin:
            return 'Admin is handled on web.';
        }
      case 2:
        return 'Alerts, support, and follow-ups.';
      default:
        return 'Account details and quick controls.';
    }
  }

  String _workspaceLabelForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return 'Attendee';
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.sponsor:
        return 'Sponsor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _tabKey(AuthSession session, int tabIndex) {
    return '${session.user.role.name}:$tabIndex:${session.tokens.accessToken}';
  }

  _RolePalette _paletteForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return const _RolePalette(
          canvasTop: Color(0xFFF8F4ED),
          canvasBottom: Color(0xFFEEE6DA),
          surface: Color(0xFFFFFBF6),
          accent: Color(0xFF8A6841),
          support: Color(0xFFB18C64),
        );
      case UserRole.organizer:
        return const _RolePalette(
          canvasTop: Color(0xFFF2F7F2),
          canvasBottom: Color(0xFFE4EDE4),
          surface: Color(0xFFFBFEFB),
          accent: Color(0xFF2F6B57),
          support: Color(0xFF7AA28C),
        );
      case UserRole.vendor:
        return const _RolePalette(
          canvasTop: Color(0xFFF8F2EC),
          canvasBottom: Color(0xFFF0E4D8),
          surface: Color(0xFFFFFBF7),
          accent: Color(0xFF7C583A),
          support: Color(0xFFB68A61),
        );
      case UserRole.sponsor:
        return const _RolePalette(
          canvasTop: Color(0xFFF3F6FA),
          canvasBottom: Color(0xFFE6ECF2),
          surface: Color(0xFFFCFDFF),
          accent: Color(0xFF4E627B),
          support: Color(0xFF7B8EA7),
        );
      case UserRole.admin:
        return const _RolePalette(
          canvasTop: Color(0xFFF3F6FA),
          canvasBottom: Color(0xFFE6ECF2),
          surface: Color(0xFFFCFDFF),
          accent: Color(0xFF4E627B),
          support: Color(0xFF7B8EA7),
        );
    }
  }

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

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.roleLabel,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final _RolePalette palette;
  final String roleLabel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14101828),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const MelooBrandLockup(
              compact: true,
              showCaption: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.support.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF44515D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeroCard extends StatelessWidget {
  const _PageHeroCard({
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.metrics,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final _RolePalette palette;
  final List<_HeroMetric> metrics;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface,
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: palette.support.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12101828),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5F6D7B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map(
                  (metric) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
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
                        const SizedBox(height: 3),
                        Text(
                          metric.label,
                          style: const TextStyle(
                            color: Color(0xFF5F6C79),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF1F4F7),
        foregroundColor: const Color(0xFF21303E),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF62707D),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8B9B2)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9D2C1F),
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.manageMode,
    required this.onOpen,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final List<EventModel> events;
  final bool manageMode;
  final Future<void> Function(String eventId) onOpen;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyCard(message: emptyMessage);
    }

    return Column(
      children: events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                onTap: () => onOpen(event.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MediaThumb(
                      imageUrl: event.coverImageUrl,
                      fallbackLabel: event.title,
                      width: 118,
                      height: 88,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${event.category.name} · ${event.city}',
                            style: const TextStyle(
                              color: Color(0xFF7A5C3A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaChip(label: _formatDateRange(event.startAt, event.endAt)),
                              _MetaChip(label: event.venue),
                              _MetaChip(
                                label: manageMode
                                    ? event.status.toUpperCase()
                                    : 'View event',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _VendorList extends StatelessWidget {
  const _VendorList({
    required this.vendors,
    required this.onMessage,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
  });

  final List<VendorProfileModel> vendors;
  final ValueChanged<VendorProfileModel> onMessage;
  final ValueChanged<VendorProfileModel> onPrimaryAction;
  final String primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const _EmptyCard(
        message: 'Vendor results will appear here once profiles are available.',
      );
    }

    return Column(
      children: vendors
          .map(
            (vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MediaThumb(
                          imageUrl: vendor.portfolioImageUrl,
                          fallbackLabel: vendor.businessName,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor.businessName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${vendor.category} · ${vendor.serviceArea}',
                                style: const TextStyle(
                                  color: Color(0xFF7A5C3A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                vendor.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF566472),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MetaChip(label: vendor.verified ? 'Verified' : 'Reviewing'),
                                  _MetaChip(label: 'Rating ${vendor.ratingAverage}'),
                                  if (vendor.travelRadiusKm != null)
                                    _MetaChip(
                                      label:
                                          'Travel ${vendor.travelRadiusKm!.toStringAsFixed(0)} km',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed: () => onPrimaryAction(vendor),
                          child: Text(primaryActionLabel),
                        ),
                        OutlinedButton(
                          onPressed: () => onMessage(vendor),
                          child: const Text('Message'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  const _OpportunityList({
    required this.opportunities,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final List<SponsorshipOpportunityModel> opportunities;
  final ValueChanged<SponsorshipOpportunityModel>? onPrimaryAction;
  final String? primaryActionLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) {
      return _EmptyCard(message: emptyMessage);
    }

    return Column(
      children: opportunities
          .map(
            (opportunity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${opportunity.event.title} · ${opportunity.event.city}',
                      style: const TextStyle(
                        color: Color(0xFF4B627D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      opportunity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF566472),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: 'Need ${opportunity.requiredAmount}'),
                        _MetaChip(label: opportunity.status.toUpperCase()),
                        _MetaChip(label: opportunity.targetAudience),
                      ],
                    ),
                    if (onPrimaryAction != null && primaryActionLabel != null) ...[
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => onPrimaryAction!(opportunity),
                        child: Text(primaryActionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AiVendorList extends StatelessWidget {
  const _AiVendorList({
    required this.recommendations,
    required this.onOpenVendor,
  });

  final List<AiVendorRecommendationModel> recommendations;
  final ValueChanged<VendorProfileModel> onOpenVendor;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _EmptyCard(
        message: 'AI vendor recommendations will appear after your event context is available.',
      );
    }

    return Column(
      children: recommendations
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.vendor.businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _ScorePill(score: item.score),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.reasonSummary,
                      style: const TextStyle(
                        color: Color(0xFF586573),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => onOpenVendor(item.vendor),
                      child: const Text('Open conversation'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AiOpportunityList extends StatelessWidget {
  const _AiOpportunityList({
    required this.recommendations,
    required this.onPrimaryAction,
  });

  final List<AiOpportunityRecommendationModel> recommendations;
  final ValueChanged<SponsorshipOpportunityModel> onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _EmptyCard(
        message: 'AI opportunity recommendations will appear once sponsor signals are available.',
      );
    }

    return Column(
      children: recommendations
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.opportunity.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _ScorePill(score: item.score),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.opportunity.event.title} · ${item.opportunity.event.city}',
                      style: const TextStyle(
                        color: Color(0xFF4B627D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.reasonSummary,
                      style: const TextStyle(
                        color: Color(0xFF586573),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => onPrimaryAction(item.opportunity),
                      child: const Text('Express interest'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RegistrationList extends StatelessWidget {
  const _RegistrationList({
    required this.registrations,
    required this.onOpen,
  });

  final List<RegistrationModel> registrations;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (registrations.isEmpty) {
      return const _EmptyCard(
        message: 'Registrations will show up after you book an event.',
      );
    }

    return Column(
      children: registrations
          .map(
            (registration) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                onTap: () => onOpen(registration.event.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${registration.ticketType.name} · ${registration.quantity} ticket${registration.quantity == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF7A5C3A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: registration.status.toUpperCase()),
                        _MetaChip(
                          label: _formatDateRange(
                            registration.event.startAt,
                            registration.event.endAt,
                          ),
                        ),
                        _MetaChip(label: registration.event.venue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.payments});

  final List<PaymentCheckoutModel> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const _EmptyCard(
        message: 'Payment history will appear after your first checkout.',
      );
    }

    return Column(
      children: payments
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.registration.event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: item.payment.status.toUpperCase()),
                        _MetaChip(
                          label: '${item.payment.amount} ${item.payment.currency}',
                        ),
                        _MetaChip(label: item.payment.provider.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Created ${_formatFullDate(item.payment.createdAt)}',
                      style: const TextStyle(
                        color: Color(0xFF586573),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _VendorRequestList extends StatelessWidget {
  const _VendorRequestList({required this.requests});

  final List<VendorRequestModel> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyCard(
        message: 'Vendor requests will appear here once outreach starts.',
      );
    }

    return Column(
      children: requests
          .map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.vendor.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.event.title,
                      style: const TextStyle(
                        color: Color(0xFF7A5C3A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      request.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF566472),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: request.status.toUpperCase()),
                        _MetaChip(label: 'Budget ${request.proposedBudget}'),
                        _MetaChip(label: _formatCompactDate(request.updatedAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PlanningBriefCard extends StatelessWidget {
  const _PlanningBriefCard({required this.brief});

  final AiPlanningAssistantResponseModel brief;

  @override
  Widget build(BuildContext context) {
    return _InteractiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brief.overview,
            style: const TextStyle(
              color: Color(0xFF51606D),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          if (brief.checklist.isNotEmpty)
            _BulletGroup(title: 'Checklist', items: brief.checklist.take(4).toList()),
          if (brief.vendorCategories.isNotEmpty) ...[
            const SizedBox(height: 14),
            _BulletGroup(
              title: 'Vendor categories',
              items: brief.vendorCategories.take(4).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorProfileSummaryCard extends StatelessWidget {
  const _VendorProfileSummaryCard({
    required this.profile,
    required this.onEdit,
  });

  final VendorProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _InteractiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MelooRemoteImage(
            imageUrl: profile.portfolioImageUrl,
            fallbackLabel: profile.businessName,
            height: 156,
            width: double.infinity,
            fontSize: 34,
            borderRadius: BorderRadius.circular(18),
            fallbackGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E4A62),
                Color(0xFF4D6478),
                Color(0xFF6D7D8B),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.businessName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF54626F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: profile.category),
              _MetaChip(label: profile.serviceArea),
              _MetaChip(label: profile.verified ? 'Verified' : 'Reviewing'),
              _MetaChip(label: '${profile.services.length} services'),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorOfferSummary extends StatelessWidget {
  const _VendorOfferSummary({
    required this.profile,
    required this.onAddService,
    required this.onAddPackage,
  });

  final VendorProfileModel profile;
  final VoidCallback onAddService;
  final VoidCallback onAddPackage;

  @override
  Widget build(BuildContext context) {
    return _InteractiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: onAddService,
                child: const Text('Add service'),
              ),
              FilledButton.tonal(
                onPressed: onAddPackage,
                child: const Text('Add package'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (profile.services.isNotEmpty) ...[
            const Text(
              'Services',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...profile.services.take(4).map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${service.name} · ${service.basePrice}',
                      style: const TextStyle(
                        color: Color(0xFF51606D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
          if (profile.packages.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Packages',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...profile.packages.take(4).map(
                  (package) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${package.name} · ${package.price}',
                      style: const TextStyle(
                        color: Color(0xFF51606D),
                        fontWeight: FontWeight.w600,
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

class _SponsorProfileSummaryCard extends StatelessWidget {
  const _SponsorProfileSummaryCard({
    required this.profile,
    required this.onEdit,
  });

  final SponsorProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _InteractiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MelooRemoteImage(
            imageUrl: profile.logoUrl,
            fallbackLabel: profile.companyName,
            height: 148,
            width: double.infinity,
            fontSize: 34,
            borderRadius: BorderRadius.circular(18),
            fallbackGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF324A61),
                Color(0xFF6A5C4B),
                Color(0xFF907A63),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.companyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF54626F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: profile.industries),
              _MetaChip(label: profile.verified ? 'Verified' : 'Reviewing'),
              if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty)
                _MetaChip(label: profile.websiteUrl!),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestList extends StatelessWidget {
  const _InterestList({required this.interests});

  final List<SponsorshipInterestModel> interests;

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return const _EmptyCard(
        message: 'Submitted sponsorship interests will show here.',
      );
    }

    return Column(
      children: interests
          .map(
            (interest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interest.opportunity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      interest.opportunity.event.title,
                      style: const TextStyle(
                        color: Color(0xFF4B627D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      interest.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF566472),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: interest.status.toUpperCase()),
                        _MetaChip(label: _formatCompactDate(interest.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notifications,
    required this.onTap,
  });

  final List<AppNotificationModel> notifications;
  final ValueChanged<AppNotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const _EmptyCard(
        message: 'Notifications will land here when workflow activity starts.',
      );
    }

    return Column(
      children: notifications
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                onTap: () => onTap(item),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: item.unread
                            ? const Color(0xFFB36D2A)
                            : const Color(0xFFD0D6DE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: Color(0xFF566472),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatFullDate(item.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF748291),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SupportTicketList extends StatelessWidget {
  const _SupportTicketList({required this.tickets});

  final List<SupportTicketModel> tickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const _EmptyCard(
        message: 'Support tickets will appear here once created.',
      );
    }

    return Column(
      children: tickets
          .map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InteractiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF566472),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: ticket.status.toUpperCase()),
                        _MetaChip(label: ticket.priority.toUpperCase()),
                        if (ticket.escalation != null)
                          const _MetaChip(label: 'Escalated'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.palette,
    required this.onEdit,
  });

  final UserModel user;
  final _RolePalette palette;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = user.profile?.fullName?.trim();
    final displayName = (name != null && name.isNotEmpty) ? name : user.email;
    final bio = user.profile?.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;

    return _InteractiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MelooRemoteImage(
                imageUrl: user.profile?.avatarUrl,
                fallbackLabel: displayName,
                width: 64,
                height: 64,
                fontSize: 24,
                borderRadius: BorderRadius.circular(22),
                fallbackGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.accent,
                    palette.support,
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFF62707D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasBio) ...[
                      const SizedBox(height: 10),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF54626F),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: user.role.name.toUpperCase()),
              _MetaChip(label: user.status.toUpperCase()),
              if (user.profile?.phone != null && user.profile!.phone!.isNotEmpty)
                _MetaChip(label: user.profile!.phone!),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onEdit,
            child: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}

class _PreferenceGrid extends StatelessWidget {
  const _PreferenceGrid({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final settings = user.settings;
    final entries = [
      _PreferenceItem(
        label: 'Notifications',
        value: settings?.notificationsEnabled == false ? 'Off' : 'On',
      ),
      _PreferenceItem(
        label: 'Marketing',
        value: settings?.marketingEnabled == true ? 'On' : 'Off',
      ),
      _PreferenceItem(
        label: 'Privacy',
        value: _formatPrivacyValue(settings?.privacyLevel),
      ),
      _PreferenceItem(
        label: 'AI assist',
        value: settings?.aiAssistEnabled == true ? 'On' : 'Off',
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries
          .map(
            (entry) => Container(
              width: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4EF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4DCCE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: const TextStyle(
                      color: Color(0xFF66717D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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

class _RoleProfileActions extends StatelessWidget {
  const _RoleProfileActions({
    required this.role,
    required this.vendorProfile,
    required this.sponsorProfile,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final UserRole role;
  final VendorProfileModel? vendorProfile;
  final SponsorProfileModel? sponsorProfile;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.organizer:
        return _InteractiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Launch events and keep planning moving.',
                style: TextStyle(
                  color: Color(0xFF54626F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: const Text('Create event'),
                  ),
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: const Text('Planning brief'),
                  ),
                ],
              ),
            ],
          ),
        );
      case UserRole.vendor:
        return _InteractiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendorProfile == null
                    ? 'Set up your storefront.'
                    : 'Your storefront is live.',
                style: const TextStyle(
                  color: Color(0xFF54626F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: Text(
                      vendorProfile == null ? 'Create profile' : 'Edit profile',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: const Text('Add service'),
                  ),
                ],
              ),
            ],
          ),
        );
      case UserRole.sponsor:
        return _InteractiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sponsorProfile == null
                    ? 'Set up your sponsor profile.'
                    : 'Your sponsor profile is live.',
                style: const TextStyle(
                  color: Color(0xFF54626F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: Text(
                      sponsorProfile == null ? 'Create profile' : 'Edit profile',
                    ),
                  ),
                  if (sponsorProfile != null)
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      child: const Text('Express interest'),
                    ),
                ],
              ),
            ],
          ),
        );
      case UserRole.attendee:
        return _InteractiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reach support fast and keep messages close by.',
                style: TextStyle(
                  color: Color(0xFF54626F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: const Text('Open ticket'),
                  ),
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: const Text('Messages'),
                  ),
                ],
              ),
            ],
          ),
        );
      case UserRole.admin:
        return const _EmptyCard(message: 'Admin is web only.');
    }
  }
}

class _InsightWrap extends StatelessWidget {
  const _InsightWrap({
    required this.values,
    required this.emptyMessage,
  });

  final List<String> values;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _EmptyCard(message: emptyMessage);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map((value) => _MetaChip(label: value))
          .toList(growable: false),
    );
  }
}

class _BulletGroup extends StatelessWidget {
  const _BulletGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFF6A7A88),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF54626F),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveCard extends StatelessWidget {
  const _InteractiveCard({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E2D7)),
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: content,
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.imageUrl,
    required this.fallbackLabel,
    this.width = 82,
    this.height = 82,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final String? imageUrl;
  final String fallbackLabel;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return MelooRemoteImage(
      imageUrl: imageUrl,
      fallbackLabel: fallbackLabel,
      width: width,
      height: height,
      fontSize: 26,
      borderRadius: borderRadius,
      fallbackGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E4A62),
          Color(0xFF4D6478),
          Color(0xFF7A8F9E),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF61707D),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: Color(0xFF38516A),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D9C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF5E6B77),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
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

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric {
  const _HeroMetric(this.label, this.value);

  final String label;
  final String value;
}

class _PreferenceItem {
  const _PreferenceItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

String _formatPrivacyValue(String? value) {
  switch (value) {
    case 'community':
      return 'Community';
    case 'private':
      return 'Private';
    case 'contacts_only':
    default:
      return 'Contacts only';
  }
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

String _formatCompactDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _formatFullDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

String _formatDateRange(DateTime start, DateTime end) {
  final startDay = start.day.toString().padLeft(2, '0');
  final startMonth = start.month.toString().padLeft(2, '0');
  final endDay = end.day.toString().padLeft(2, '0');
  final endMonth = end.month.toString().padLeft(2, '0');
  return '$startDay/$startMonth-$endDay/$endMonth';
}
