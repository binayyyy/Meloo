import 'package:flutter/material.dart';
import '../../chat/chat_controller.dart';
import '../../chat/chat_models.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../widgets/workflow_page_scaffold.dart';

class ChatHubScreen extends StatelessWidget {
  const ChatHubScreen({
    required this.controller,
    required this.session,
    required this.onOpenConversation,
    required this.onStartConversationByEmail,
    super.key,
  });

  final ChatController controller;
  final AuthSession session;
  final Future<void> Function(
    ConversationModel conversation, {
    String? title,
  }) onOpenConversation;
  final Future<void> Function(String participantEmail) onStartConversationByEmail;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return WorkflowPageScaffold(
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: 'Start chat by email',
                onPressed: () =>
                    _showStartConversationDialog(context, controller, session),
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE3D5C5)),
                ),
                child: Text(
                  '${controller.conversations.length} threads',
                  style: const TextStyle(
                    color: Color(0xFF6B4D2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF9F3EB),
                      Color(0xFFF5F8FB),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFE4D9CB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12101828),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitleForRole(session.user.role),
                      style: const TextStyle(
                        color: Color(0xFF5E6975),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.load(session),
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.conversations.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 110),
                                _ChatEmptyState(),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 12),
                              itemCount: controller.conversations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final conversation =
                                    controller.conversations[index];
                                final counterpart =
                                    controller.counterpartFor(conversation);
                                final preview =
                                    conversation.lastMessage?.previewText ??
                                        'No messages yet';
                                final timestamp =
                                    conversation.lastMessage?.createdAt ??
                                        conversation.createdAt;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () => onOpenConversation(
                                      conversation,
                                      title: counterpart?.displayName,
                                    ),
                                    child: Ink(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFE1E6EB),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _AvatarBadge(
                                            label: counterpart?.displayName ??
                                                'Thread',
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        counterpart
                                                                ?.displayName ??
                                                            'Conversation',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      _formatRelativeTimestamp(
                                                        timestamp,
                                                      ),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF70808E),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  counterpart?.role.name
                                                          .toUpperCase() ??
                                                      conversation.type
                                                          .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Color(0xFF98734D),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  preview,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF51606D),
                                                    height: 1.45,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStartConversationDialog(
    BuildContext context,
    ChatController controller,
    AuthSession session,
  ) async {
    final emailController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Start chat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the exact account email of the person you want to message.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Account email',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final isValidEmail = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);
                    if (!isValidEmail) {
                      setState(() {
                        errorText = 'Enter a valid email address.';
                      });
                      return;
                    }

                    try {
                      Navigator.of(dialogContext).pop();
                      await onStartConversationByEmail(email);
                    } on ApiException {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.errorMessage ??
                                'Unable to start the conversation.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  String _subtitleForRole(UserRole role) {
    switch (role) {
      case UserRole.attendee:
        return 'Keep plans, confirmations, and event questions in one clean thread list.';
      case UserRole.organizer:
        return 'Stay on top of vendor, sponsor, and event operations conversations.';
      case UserRole.vendor:
        return 'Track organizer outreach, service questions, and booking decisions.';
      case UserRole.sponsor:
        return 'Keep partnership conversations focused, current, and easy to reopen.';
      case UserRole.admin:
        return 'Admin messaging is handled on web.';
    }
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE2E7EC)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 34,
              color: Color(0xFF7B8C9B),
            ),
            SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation from a vendor, sponsor, or opportunity card and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5F6B78),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initial =
        label.trim().isEmpty ? 'M' : label.trim().characters.first.toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34516A),
            Color(0xFF607B92),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}
