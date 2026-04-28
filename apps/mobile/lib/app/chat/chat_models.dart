import 'dart:convert';
import '../session/auth_models.dart';
import '../uploads/upload_models.dart';

const _chatAttachmentPrefix = 'meloo://attachment/';

class ChatParticipantModel {
  const ChatParticipantModel({
    required this.userId,
    required this.email,
    required this.role,
    required this.fullName,
  });

  final String userId;
  final String email;
  final UserRole role;
  final String? fullName;

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : email;

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      role: userRoleFromApi(json['role'] as String? ?? 'attendee'),
      fullName: json['fullName'] as String?,
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.messageType,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final ChatParticipantModel sender;
  final String body;
  final String messageType;
  final DateTime createdAt;

  bool get isSystem => messageType == 'system';
  bool get isAssistant => messageType == 'assistant';
  ChatAttachmentModel? get attachment => ChatAttachmentModel.tryParse(body);
  bool get hasAttachment => attachment != null;
  String get previewText => attachment?.previewText ?? body;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: ChatParticipantModel.fromJson(
        Map<String, dynamic>.from(json['sender'] as Map),
      ),
      body: json['body'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class ChatAttachmentModel {
  const ChatAttachmentModel({
    required this.kind,
    required this.url,
    required this.name,
    required this.mimeType,
    required this.size,
    this.note,
  });

  final UploadAssetKind kind;
  final String url;
  final String name;
  final String mimeType;
  final int size;
  final String? note;

  bool get isImage => kind == UploadAssetKind.image;
  String get previewText {
    final noteText = note?.trim();
    if (noteText != null && noteText.isNotEmpty) {
      return noteText;
    }
    return isImage ? 'Shared a photo' : 'Shared a file';
  }

  factory ChatAttachmentModel.fromUpload(
    UploadedAssetModel asset, {
    String? note,
  }) {
    return ChatAttachmentModel(
      kind: asset.kind,
      url: asset.url,
      name: asset.originalName,
      mimeType: asset.mimeType,
      size: asset.size,
      note: note,
    );
  }

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      kind: (json['kind'] as String? ?? 'image') == 'document'
          ? UploadAssetKind.document
          : UploadAssetKind.image,
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? 'Attachment',
      mimeType: json['mimeType'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind == UploadAssetKind.document ? 'document' : 'image',
      'url': url,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'note': note,
    };
  }

  static ChatAttachmentModel? tryParse(String body) {
    if (!body.startsWith(_chatAttachmentPrefix)) {
      return null;
    }
    try {
      final decoded = jsonDecode(
        body.substring(_chatAttachmentPrefix.length),
      );
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ChatAttachmentModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

String encodeChatAttachmentBody(
  UploadedAssetModel asset, {
  String? note,
}) {
  final payload = ChatAttachmentModel.fromUpload(
    asset,
    note: note?.trim().isEmpty == true ? null : note?.trim(),
  );
  return '$_chatAttachmentPrefix${jsonEncode(payload.toJson())}';
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.type,
    required this.participants,
    required this.lastMessage,
    required this.createdAt,
  });

  final String id;
  final String type;
  final List<ChatParticipantModel> participants;
  final ChatMessageModel? lastMessage;
  final DateTime createdAt;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      participants: (json['participants'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => ChatParticipantModel.fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false),
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessageModel.fromJson(
              Map<String, dynamic>.from(json['lastMessage'] as Map),
            ),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  ChatParticipantModel? counterpartFor(String userId) {
    for (final participant in participants) {
      if (participant.userId != userId) {
        return participant;
      }
    }
    return participants.isEmpty ? null : participants.first;
  }
}
