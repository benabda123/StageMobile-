import 'package:flutter/material.dart';

import '../domain/meeting_model.dart';
import '../domain/room_model.dart';

Color meetingStatusColor(String status) {
  switch (status) {
    case MeetingStatus.pending:
      return Colors.orange;
    case MeetingStatus.confirmed:
      return Colors.green;
    case MeetingStatus.changeRequestPending:
      return Colors.blue;
    case MeetingStatus.cancelled:
      return Colors.grey;
    case MeetingStatus.rejected:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String meetingStatusLabel(String status) {
  switch (status) {
    case MeetingStatus.pending:
      return 'En attente';
    case MeetingStatus.confirmed:
      return 'Confirmée';
    case MeetingStatus.changeRequestPending:
      return 'Changement demandé';
    case MeetingStatus.cancelled:
      return 'Annulée';
    case MeetingStatus.rejected:
      return 'Refusée';
    default:
      return status;
  }
}

String meetingTypeLabel(String type) {
  switch (type) {
    case MeetingType.online:
      return 'En ligne';
    case MeetingType.presentiel:
      return 'Présentielle';
    default:
      return type;
  }
}

IconData meetingTypeIcon(String type) {
  switch (type) {
    case MeetingType.online:
      return Icons.videocam_outlined;
    case MeetingType.presentiel:
      return Icons.groups_outlined;
    default:
      return Icons.event_outlined;
  }
}

/// Affiche une date backend (`YYYY-MM-DD` ou ISO) en `JJ/MM/AAAA`.
String formatMeetingDate(String? value) {
  final String? only = meetingDateOnly(value);
  if (only == null) {
    return '—';
  }
  final DateTime date = DateTime.parse(only);
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Affiche une heure backend (`HH:MM:SS`) en `HH:MM`.
String formatMeetingTime(String? value) {
  return meetingTimeOnly(value) ?? '—';
}

/// Lieu d'une réunion : nom de la salle (résolu depuis [roomsById]) ou
/// « En ligne » pour une réunion ONLINE.
String meetingLocation(Meeting meeting, Map<String, MeetingRoom> roomsById) {
  if (meeting.type == MeetingType.online) {
    return 'En ligne';
  }
  if (meeting.roomId == null) {
    return 'Salle supprimée';
  }
  final MeetingRoom? room = roomsById[meeting.roomId];
  return room?.name ?? 'Salle ${meeting.roomId}';
}

/// Badge coloré du statut d'une réunion.
class MeetingStatusBadge extends StatelessWidget {
  const MeetingStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = meetingStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        meetingStatusLabel(status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
