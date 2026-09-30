/// Notification utilisateur (`GET /notifications/my`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'];
    return AppNotification(
      id: idValue is int ? idValue : int.tryParse('$idValue') ?? 0,
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      type: NotificationType.fromApi(json['type'] as String?),
      status: NotificationStatus.fromApi(json['status'] as String?),
      createdAt: (json['createdAt'] ?? json['created_at']) as String?,
      readAt: (json['readAt'] ?? json['read_at']) as String?,
    );
  }

  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final String? createdAt;
  final String? readAt;

  bool get isUnread => status == NotificationStatus.unread;

  AppNotification copyWith({
    NotificationStatus? status,
    String? readAt,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

enum NotificationType {
  task,
  leave,
  meeting,
  system,
  employee,
  announcement;

  static const String apiTask = 'TASK';
  static const String apiLeave = 'LEAVE';
  static const String apiMeeting = 'MEETING';
  static const String apiSystem = 'SYSTEM';
  static const String apiEmployee = 'EMPLOYEE';
  static const String apiAnnouncement = 'ANNOUNCEMENT';

  static NotificationType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case apiTask:
        return NotificationType.task;
      case apiLeave:
        return NotificationType.leave;
      case apiMeeting:
        return NotificationType.meeting;
      case apiSystem:
        return NotificationType.system;
      case apiEmployee:
        return NotificationType.employee;
      case apiAnnouncement:
        return NotificationType.announcement;
      default:
        return NotificationType.system;
    }
  }
}

enum NotificationStatus {
  unread,
  read;

  static const String apiUnread = 'UNREAD';
  static const String apiRead = 'READ';

  static NotificationStatus fromApi(String? value) {
    if (value?.toUpperCase() == apiRead) {
      return NotificationStatus.read;
    }
    return NotificationStatus.unread;
  }
}
