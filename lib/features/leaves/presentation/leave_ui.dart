import 'package:flutter/material.dart';

import '../../../core/theme/glass_tokens.dart';
import '../domain/leave_model.dart';

Color leaveStatusColor(String status) {
  switch (status) {
    case LeaveStatus.pending:
      return GlassTokens.warningOrange;
    case LeaveStatus.approved:
      return GlassTokens.successGreen;
    case LeaveStatus.rejected:
      return GlassTokens.errorRed;
    default:
      return GlassTokens.textSecondary;
  }
}

String leaveStatusLabel(String status) {
  switch (status) {
    case LeaveStatus.pending:
      return 'En attente';
    case LeaveStatus.approved:
      return 'Acceptée';
    case LeaveStatus.rejected:
      return 'Refusée';
    default:
      return status;
  }
}

String leaveTypeLabel(String type) {
  switch (type) {
    case LeaveType.annual:
      return 'Annuel';
    case LeaveType.sick:
      return 'Maladie';
    case LeaveType.personal:
      return 'Personnel';
    case LeaveType.unpaid:
      return 'Sans solde';
    default:
      return type;
  }
}

IconData leaveTypeIcon(String type) {
  switch (type) {
    case LeaveType.annual:
      return Icons.beach_access_outlined;
    case LeaveType.sick:
      return Icons.local_hospital_outlined;
    case LeaveType.personal:
      return Icons.person_outline;
    case LeaveType.unpaid:
      return Icons.money_off_outlined;
    default:
      return Icons.event_outlined;
  }
}

/// Affiche une date backend (`YYYY-MM-DD` ou ISO) en `JJ/MM/AAAA`.
String formatLeaveDate(String? value) {
  final String? only = leaveDateOnly(value);
  if (only == null) {
    return '—';
  }
  final DateTime date = DateTime.parse(only);
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Badge coloré du statut d'une demande.
class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = leaveStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        leaveStatusLabel(status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
