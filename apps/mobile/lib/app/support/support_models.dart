import '../session/auth_models.dart';
import '../core/json_value.dart';

class SupportEscalationModel {
  const SupportEscalationModel({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.reason,
    required this.aiConfidence,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sourceType;
  final String sourceId;
  final String reason;
  final String aiConfidence;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportEscalationModel.fromJson(Map<String, dynamic> json) {
    return SupportEscalationModel(
      id: stringValue(json['id']),
      sourceType: stringValue(json['sourceType']),
      sourceId: stringValue(json['sourceId']),
      reason: stringValue(json['reason']),
      aiConfidence: stringValue(json['aiConfidence']),
      status: stringValue(json['status']),
      assignedTo: nullableStringValue(json['assignedTo']),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
      updatedAt: DateTime.parse(stringValue(json['updatedAt'])).toLocal(),
    );
  }
}

class SupportRequesterModel {
  const SupportRequesterModel({
    required this.userId,
    required this.email,
    required this.role,
    required this.fullName,
  });

  final String userId;
  final String email;
  final UserRole role;
  final String? fullName;

  factory SupportRequesterModel.fromJson(Map<String, dynamic> json) {
    return SupportRequesterModel(
      userId: stringValue(json['userId']),
      email: stringValue(json['email']),
      role: userRoleFromApi(stringValue(json['role'], fallback: 'attendee')),
      fullName: nullableStringValue(json['fullName']),
    );
  }
}

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.requester,
    required this.assignedAdminId,
    required this.assistantSuggestion,
    required this.aiConfidence,
    required this.escalation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final SupportRequesterModel requester;
  final String? assignedAdminId;
  final String? assistantSuggestion;
  final String? aiConfidence;
  final SupportEscalationModel? escalation;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: stringValue(json['id']),
      category: stringValue(json['category']),
      subject: stringValue(json['subject']),
      description: stringValue(json['description']),
      status: stringValue(json['status']),
      priority: stringValue(json['priority']),
      requester: SupportRequesterModel.fromJson(
        Map<String, dynamic>.from(json['requester'] as Map),
      ),
      assignedAdminId: nullableStringValue(json['assignedAdminId']),
      assistantSuggestion: nullableStringValue(json['assistantSuggestion']),
      aiConfidence: nullableStringValue(json['aiConfidence']),
      escalation: json['escalation'] == null
          ? null
          : SupportEscalationModel.fromJson(
              Map<String, dynamic>.from(json['escalation'] as Map),
            ),
      createdAt: DateTime.parse(stringValue(json['createdAt'])).toLocal(),
      updatedAt: DateTime.parse(stringValue(json['updatedAt'])).toLocal(),
    );
  }
}

class CreateSupportTicketRequest {
  const CreateSupportTicketRequest({
    required this.category,
    required this.subject,
    required this.description,
  });

  final String category;
  final String subject;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'subject': subject,
      'description': description,
    };
  }
}
