import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../ai/ai_models.dart';
import '../../chat/chat_models.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../uploads/upload_models.dart';
import '../../uploads/uploads_api_client.dart';
import '../../widgets/remote_media.dart';
import '../../widgets/workflow_page_scaffold.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.title,
    required this.accessToken,
    required this.messages,
    required this.currentUserId,
    required this.currentUserRole,
    required this.aiAssistEnabled,
    required this.isLoading,
    required this.isSending,
    required this.isDrafting,
    required this.onSend,
    required this.onSendAttachment,
    required this.onGenerateDraft,
    super.key,
  });

  final String title;
  final String accessToken;
  final List<ChatMessageModel> messages;
  final String currentUserId;
  final UserRole currentUserRole;
  final bool aiAssistEnabled;
  final bool isLoading;
  final bool isSending;
  final bool isDrafting;
  final Future<void> Function(String body) onSend;
  final Future<void> Function(UploadedAssetModel asset, {String? note})
      onSendAttachment;
  final Future<AiAssistantDraftModel> Function({
    required AiAssistantDraftIntent intent,
    String? prompt,
  }) onGenerateDraft;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UploadsApiClient _uploadsApiClient = UploadsApiClient();
  bool _isUploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
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

  List<AiAssistantDraftIntent> get _availableDrafts {
    switch (widget.currentUserRole) {
      case UserRole.vendor:
        return const [
          AiAssistantDraftIntent.chatReply,
          AiAssistantDraftIntent.vendorProposal,
        ];
      case UserRole.sponsor:
        return const [
          AiAssistantDraftIntent.chatReply,
          AiAssistantDraftIntent.sponsorProposal,
        ];
      default:
        return const [AiAssistantDraftIntent.chatReply];
    }
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

  Future<void> _pickAndSendAttachment(UploadAssetKind kind) async {
    final picked = await FilePicker.platform.pickFiles(
      type: kind == UploadAssetKind.image ? FileType.image : FileType.any,
      withData: true,
      allowedExtensions: kind == UploadAssetKind.image
          ? null
          : const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
    );

    if (picked == null || picked.files.isEmpty || !mounted) {
      return;
    }

    setState(() => _isUploadingAttachment = true);
    try {
      final asset = await _uploadsApiClient.uploadFile(
        accessToken: widget.accessToken,
        file: picked.files.single,
        kind: kind,
      );
      await widget.onSendAttachment(
        asset,
        note: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == UploadAssetKind.image ? 'Photo shared' : 'File shared',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment failed to send')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
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
    return WorkflowPageScaffold(
      trailing: widget.aiAssistEnabled
          ? Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDCE3E8)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Color(0xFF2E4A62),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Draft assist',
                    style: TextStyle(
                      color: Color(0xFF2E4A62),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.84,
        child: Column(
          children: [
            _ConversationHeader(
              title: widget.title,
              aiAssistEnabled: widget.aiAssistEnabled,
              currentUserRole: widget.currentUserRole,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFD),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFDCE3E8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12101828),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : widget.messages.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 28),
                                    child: Text(
                                      _emptyStateText(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF66717D),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    18,
                                    16,
                                    14,
                                  ),
                                  itemCount: widget.messages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final message = widget.messages[index];
                                    return _ConversationBubble(
                                      message: message,
                                      currentUserId: widget.currentUserId,
                                    );
                                  },
                                ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFDCE3E8)),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (widget.aiAssistEnabled) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableDrafts
                                    .map(
                                      (intent) => FilledButton.tonalIcon(
                                        onPressed: widget.isDrafting ||
                                                widget.isSending ||
                                                _isUploadingAttachment
                                            ? null
                                            : () => _requestDraft(intent),
                                        icon: widget.isDrafting
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 16,
                                              ),
                                        label: Text(_labelForDraft(intent)),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_isUploadingAttachment)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF0F5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Uploading attachment...',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8FA),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFDCE3E8)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed:
                                      _isUploadingAttachment || widget.isSending
                                          ? null
                                          : () => _pickAndSendAttachment(
                                                UploadAssetKind.image,
                                              ),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  tooltip: 'Share photo',
                                ),
                                IconButton(
                                  onPressed:
                                      _isUploadingAttachment || widget.isSending
                                          ? null
                                          : () => _pickAndSendAttachment(
                                                UploadAssetKind.document,
                                              ),
                                  icon: const Icon(Icons.attach_file_rounded),
                                  tooltip: 'Share file',
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    minLines: 1,
                                    maxLines: 5,
                                    textInputAction: TextInputAction.newline,
                                    decoration: InputDecoration(
                                      hintText: _composerHintText(),
                                      border: InputBorder.none,
                                      isDense: true,
                                      filled: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  onPressed:
                                      widget.isSending || _isUploadingAttachment
                                          ? null
                                          : _submit,
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(14),
                                    minimumSize: const Size(48, 48),
                                  ),
                                  child: widget.isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 18,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForDraft(AiAssistantDraftIntent intent) {
    switch (intent) {
      case AiAssistantDraftIntent.chatReply:
        return 'Draft reply';
      case AiAssistantDraftIntent.organizerPlan:
        return 'Organizer plan';
      case AiAssistantDraftIntent.vendorProposal:
        return 'Vendor proposal';
      case AiAssistantDraftIntent.sponsorProposal:
        return 'Sponsor proposal';
    }
  }

  String _emptyStateText() {
    switch (widget.currentUserRole) {
      case UserRole.organizer:
        return 'No messages yet. Open with the next event decision, vendor ask, or sponsor step you want to move.';
      case UserRole.vendor:
        return 'No messages yet. Start with scope, availability, or the exact service step you want to confirm.';
      case UserRole.sponsor:
        return 'No messages yet. Start with audience fit, activation goals, or the commercial next step.';
      case UserRole.admin:
        return 'No messages yet. Start with the operational action, trust call, or support decision that needs to move.';
      case UserRole.attendee:
        return 'No messages yet. Start with the exact question or next step you need help with.';
    }
  }

  String _composerHintText() {
    switch (widget.currentUserRole) {
      case UserRole.organizer:
        return 'Write the next event, vendor, or sponsor step';
      case UserRole.vendor:
        return 'Write scope, availability, pricing posture, or a next step';
      case UserRole.sponsor:
        return 'Write fit, activation value, or the next commercial step';
      case UserRole.admin:
        return 'Write the operational response or moderation action';
      case UserRole.attendee:
        return 'Write your message, note, or attachment caption';
    }
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.title,
    required this.aiAssistEnabled,
    required this.currentUserRole,
  });

  final String title;
  final bool aiAssistEnabled;
  final UserRole currentUserRole;

  @override
  Widget build(BuildContext context) {
    final initial =
        title.trim().isEmpty ? 'M' : title.trim().characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E4A62),
            Color(0xFF496479),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aiAssistEnabled
                      ? '${_roleLabel(currentUserRole)} thread with drafting assist'
                      : '${_roleLabel(currentUserRole)} thread',
                  style: const TextStyle(
                    color: Color(0xFFDDE6EE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.sponsor:
        return 'Sponsor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.attendee:
        return 'Attendee';
    }
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.message,
    required this.currentUserId,
  });

  final ChatMessageModel message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isMine = message.sender.userId == currentUserId;
    final attachment = message.attachment;
    final bubbleColor = message.isSystem
        ? const Color(0xFFF4F6F8)
        : message.isAssistant
            ? const Color(0xFFF2F4FF)
            : isMine
                ? const Color(0xFF2E4A62)
                : Colors.white;
    final textColor =
        isMine ? Colors.white : const Color(0xFF17212B);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: message.isAssistant
                ? const Color(0x334F5BD5)
                : isMine
                    ? const Color(0x332E4A62)
                    : const Color(0x1F173B63),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine || message.isAssistant) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.isAssistant
                          ? '${message.sender.displayName} draft'
                          : message.sender.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: message.isAssistant
                            ? const Color(0xFF4F5BD5)
                            : isMine
                                ? Colors.white
                                : const Color(0xFF4A5562),
                      ),
                    ),
                  ),
                  if (message.isAssistant)
                    const _AiChip(label: 'Draft'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (attachment != null)
              _AttachmentCard(
                attachment: attachment,
                onOpen: () => launchUrlString(
                  attachment.url,
                  mode: LaunchMode.platformDefault,
                ),
              ),
            if (attachment != null && attachment.note?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  attachment.note!.trim(),
                  style: TextStyle(color: textColor, height: 1.5),
                ),
              ),
            if (attachment == null)
              Text(
                message.previewText,
                style: TextStyle(color: textColor, height: 1.5),
              ),
            const SizedBox(height: 8),
            Text(
              _formatCompactTimestamp(message.createdAt),
              style: TextStyle(
                color: isMine
                    ? const Color(0xFFE4ECF2)
                    : const Color(0xFF7A8591),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.onOpen,
  });

  final ChatAttachmentModel attachment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              MelooRemoteImage(
                imageUrl: attachment.url,
                fallbackLabel: attachment.name,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                fontSize: 28,
                fallbackGradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E4A62),
                    Color(0xFF4D6478),
                    Color(0xFF7A8F9E),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE3E8)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF2E4A62),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17212B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatBytes(attachment.size),
                    style: const TextStyle(
                      color: Color(0xFF66717D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4F5BD5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatCompactTimestamp(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)} ${two(value.hour)}:${two(value.minute)}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
