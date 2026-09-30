/// Types de congés supportés par le backend leave-service.
class LeaveType {
  LeaveType._();

  static const String annual = 'annuel';
  static const String sick = 'maladie';
  static const String personal = 'personnel';
  static const String unpaid = 'sans_solde';

  static const List<String> values = <String>[
    annual,
    sick,
    personal,
    unpaid,
  ];
}

/// Statuts d'une demande de congé.
class LeaveStatus {
  LeaveStatus._();

  static const String pending = 'en_attente';
  static const String approved = 'accepte';
  static const String rejected = 'refuse';

  static const List<String> values = <String>[pending, approved, rejected];
}

/// Nombre de jours de congés annuels accordés par défaut.
const int leaveAnnualQuota = 18;

/// Demande de congé (`GET /leaves/mine`, `GET /leaves`, `POST /leaves`).
class Leave {
  const Leave({
    required this.id,
    this.employeeId,
    this.employeeUsername,
    this.type = '',
    this.startDate,
    this.endDate,
    this.reason,
    this.status = LeaveStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString(),
      employeeUsername: json['employeeUsername']?.toString(),
      type: json['type']?.toString() ?? '',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? LeaveStatus.pending,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  final String id;
  final String? employeeId;
  final String? employeeUsername;
  final String type;
  final String? startDate;
  final String? endDate;
  final String? reason;
  final String status;
  final String? createdAt;
  final String? updatedAt;
}

/// Statistiques calculées depuis la liste des demandes de l'employé.
class LeaveStats {
  const LeaveStats({
    required this.daysRemaining,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  /// 18 jours − somme des jours des demandes acceptées.
  /// [approvedDays] est exposé pour les tests.
  factory LeaveStats.fromLeaves(List<Leave> leaves) {
    int approvedDays = 0;
    for (final Leave leave in leaves) {
      if (leave.status == LeaveStatus.approved) {
        approvedDays += leaveDays(leave.startDate, leave.endDate);
      }
    }
    final int remaining = leaveAnnualQuota - approvedDays;
    return LeaveStats(
      daysRemaining: remaining < 0 ? 0 : remaining,
      pendingCount: leaves
          .where((Leave l) => l.status == LeaveStatus.pending)
          .length,
      approvedCount: leaves
          .where((Leave l) => l.status == LeaveStatus.approved)
          .length,
      rejectedCount: leaves
          .where((Leave l) => l.status == LeaveStatus.rejected)
          .length,
    );
  }

  final int daysRemaining;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
}

/// Extrait `YYYY-MM-DD` d'une date backend (`YYYY-MM-DD` ou ISO `T...Z`).
String? leaveDateOnly(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final RegExpMatch? match =
      RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(value);
  return match?.group(1);
}

/// Nombre de jours d'une demande (bornes incluses : fin − début + 1).
int leaveDays(String? start, String? end) {
  final String? startOnly = leaveDateOnly(start);
  final String? endOnly = leaveDateOnly(end);
  if (startOnly == null || endOnly == null) {
    return 0;
  }
  final DateTime s = DateTime.parse(startOnly);
  final DateTime e = DateTime.parse(endOnly);
  if (e.isBefore(s)) {
    return 0;
  }
  return e.difference(s).inDays + 1;
}
