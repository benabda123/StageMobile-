import 'package:flutter/material.dart';

import '../../../core/theme/glass_tokens.dart';

Color taskStatusColor(String status) {
  switch (status) {
    case 'TODO':
      return GlassTokens.textSecondary;
    case 'IN_PROGRESS':
      return GlassTokens.warningOrange;
    case 'DONE':
      return GlassTokens.successGreen;
    default:
      return GlassTokens.textSecondary;
  }
}

String taskStatusLabel(String status) {
  switch (status) {
    case 'TODO':
      return 'À faire';
    case 'IN_PROGRESS':
      return 'En cours';
    case 'DONE':
      return 'Terminée';
    default:
      return status;
  }
}

Color taskPriorityColor(String priority) {
  switch (priority) {
    case 'LOW':
      return Colors.green;
    case 'MEDIUM':
      return Colors.orange;
    case 'HIGH':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

String taskPriorityLabel(String priority) {
  switch (priority) {
    case 'LOW':
      return 'Basse';
    case 'MEDIUM':
      return 'Moyenne';
    case 'HIGH':
      return 'Haute';
    default:
      return priority;
  }
}
