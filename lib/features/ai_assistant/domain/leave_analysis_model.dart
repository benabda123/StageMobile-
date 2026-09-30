class LeaveAnalysis {
  const LeaveAnalysis({
    required this.teamAvailabilityPercent,
    required this.activeTasks,
    this.criticalDeadlineWarning,
    required this.riskLevel,
    required this.riskReason,
    required this.recommendation,
  });

  final int teamAvailabilityPercent;
  final int activeTasks;
  final String? criticalDeadlineWarning;
  final String riskLevel;
  final String riskReason;
  final String recommendation;

  factory LeaveAnalysis.fromJson(Map<String, dynamic> json) {
    return LeaveAnalysis(
      teamAvailabilityPercent:
          (json['teamAvailabilityPercent'] as num?)?.toInt() ?? 0,
      activeTasks: (json['activeTasks'] as num?)?.toInt() ?? 0,
      criticalDeadlineWarning: json['criticalDeadlineWarning'] as String?,
      riskLevel: (json['riskLevel'] as String?) ?? 'LOW',
      riskReason: json['riskReason'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}
