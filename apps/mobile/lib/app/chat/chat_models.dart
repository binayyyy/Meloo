import '../session/auth_models.dart';

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
