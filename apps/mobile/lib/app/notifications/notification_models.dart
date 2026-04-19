class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.resourceType,
    required this.resourceId,
    required this.readAt,
    required this.createdAt,
    required this.unread,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? resourceType;
  final String? resourceId;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool unread;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      resourceType: json['resourceType'] as String?,
      resourceId: json['resourceId'] as String?,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String).toLocal(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      unread: json['unread'] as bool? ?? false,
    );
  }
}
