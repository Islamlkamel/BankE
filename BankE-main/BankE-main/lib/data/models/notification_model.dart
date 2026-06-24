class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String? type;
  final int? referenceId;
  final String? actorType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.referenceId,
    this.actorType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      referenceId: json['referenceId'] != null ? (json['referenceId'] as num).toInt() : null,
      actorType: json['actorType']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      referenceId: referenceId,
      actorType: actorType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
