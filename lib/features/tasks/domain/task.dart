class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.employeeId,
    this.employeeUsername,
    this.createdBy,
    this.priority = 'MEDIUM',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      employeeId: json['employeeId']?.toString(),
      employeeUsername: json['employeeUsername']?.toString(),
      createdBy: json['createdBy']?.toString(),
      status: json['status']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      dueDate: json['dueDate']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? employeeId;
  final String? employeeUsername;
  final String? createdBy;
  final String status;
  final String priority;
  final String? dueDate;
  final String? createdAt;
  final String? updatedAt;

  Task copyWith({String? status}) {
    return Task(
      id: id,
      title: title,
      description: description,
      employeeId: employeeId,
      employeeUsername: employeeUsername,
      createdBy: createdBy,
      status: status ?? this.status,
      priority: priority,
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
