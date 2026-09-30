/// Catégories de tickets supportées par le backend.
class TicketCategory {
  TicketCategory._();

  static const String hardware = 'HARDWARE';
  static const String software = 'SOFTWARE';
  static const String network = 'NETWORK';
  static const String accessRequest = 'ACCESS_REQUEST';
  static const String security = 'SECURITY';

  static const List<String> values = <String>[
    hardware,
    software,
    network,
    accessRequest,
    security,
  ];
}

/// Priorités de tickets.
class TicketPriority {
  TicketPriority._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const List<String> values = <String>[low, medium, high];
}

/// Statuts de tickets.
class TicketStatus {
  TicketStatus._();

  static const String open = 'OPEN';
  static const String assigned = 'ASSIGNED';
  static const String inProgress = 'IN_PROGRESS';
  static const String resolved = 'RESOLVED';
  static const String closed = 'CLOSED';

  static const List<String> values = <String>[
    open,
    assigned,
    inProgress,
    resolved,
    closed,
  ];
}

class Ticket {
  const Ticket({
    required this.id,
    required this.title,
    this.description,
    this.category = '',
    this.priority = TicketPriority.medium,
    this.status = TicketStatus.open,
    this.employeeId,
    this.employeeUsername,
    this.assignedToId,
    this.assignedToUsername,
    this.attachmentUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? TicketPriority.medium,
      status: json['status']?.toString() ?? TicketStatus.open,
      employeeId: json['employeeId']?.toString(),
      employeeUsername: json['employeeUsername']?.toString(),
      assignedToId: json['assignedToId']?.toString(),
      assignedToUsername: json['assignedToUsername']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final String? employeeId;
  final String? employeeUsername;
  final String? assignedToId;
  final String? assignedToUsername;
  final String? attachmentUrl;
  final String? createdAt;
  final String? updatedAt;

  bool get isAssigned => assignedToId != null && assignedToId!.isNotEmpty;
}

class TicketComment {
  const TicketComment({
    required this.id,
    this.ticketId,
    this.authorId,
    this.authorUsername,
    this.message,
    this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString(),
      authorId: json['authorId']?.toString(),
      authorUsername: json['authorUsername']?.toString(),
      message: json['message']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String id;
  final String? ticketId;
  final String? authorId;
  final String? authorUsername;
  final String? message;
  final String? createdAt;
}

/// Réponse de `GET /tickets/:id` : le ticket + ses commentaires.
class TicketDetails {
  const TicketDetails({required this.ticket, required this.comments});

  final Ticket ticket;
  final List<TicketComment> comments;
}
