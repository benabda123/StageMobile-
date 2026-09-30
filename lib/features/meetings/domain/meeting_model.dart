/// Types de réunions supportés par le backend meeting-service.
class MeetingType {
  MeetingType._();

  static const String online = 'ONLINE';
  static const String presentiel = 'PRESENTIEL';

  static const List<String> values = <String>[online, presentiel];
}

/// Statuts d'une réunion.
class MeetingStatus {
  MeetingStatus._();

  static const String pending = 'PENDING';
  static const String confirmed = 'CONFIRMED';
  static const String rejected = 'REJECTED';
  static const String changeRequestPending = 'CHANGE_REQUEST_PENDING';
  static const String cancelled = 'CANCELLED';

  static const List<String> values = <String>[
    pending,
    confirmed,
    rejected,
    changeRequestPending,
    cancelled,
  ];
}

/// Demande de changement d'une réunion (`change_request_data`).
class MeetingChangeRequest {
  const MeetingChangeRequest({
    this.proposedDate,
    this.proposedStartTime,
    this.proposedEndTime,
    this.reason,
  });

  factory MeetingChangeRequest.fromJson(Map<String, dynamic> json) {
    return MeetingChangeRequest(
      proposedDate: json['proposed_date']?.toString(),
      proposedStartTime: json['proposed_start_time']?.toString(),
      proposedEndTime: json['proposed_end_time']?.toString(),
      reason: json['reason']?.toString(),
    );
  }

  final String? proposedDate;
  final String? proposedStartTime;
  final String? proposedEndTime;
  final String? reason;
}

/// Réunion (`GET /meetings/mine`, `GET /meetings`, `POST /meetings`).
///
/// Le backend sérialise en snake_case (`start_time`, `room_id`…) et renvoie
/// [date] sous forme ISO (`2026-08-11T00:00:00.000Z`) ou `YYYY-MM-DD` ; les
/// heures sont des chaînes `HH:MM:SS`.
class Meeting {
  const Meeting({
    required this.id,
    this.title = '',
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.type = MeetingType.presentiel,
    this.roomId,
    this.meetingLink,
    this.participants = const <String>[],
    this.createdById,
    this.createdByUsername,
    this.status = MeetingStatus.pending,
    this.changeRequestData,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    final dynamic rawChange = json['change_request_data'];
    final MeetingChangeRequest? change =
        rawChange is Map<String, dynamic>
            ? MeetingChangeRequest.fromJson(rawChange)
            : null;
    return Meeting(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      date: json['date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      type: json['type']?.toString() ?? MeetingType.presentiel,
      roomId: json['room_id']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
      participants: _stringList(json['participants']),
      createdById: json['created_by_id']?.toString(),
      createdByUsername: json['created_by_username']?.toString(),
      status: json['status']?.toString() ?? MeetingStatus.pending,
      changeRequestData: change,
      cancellationReason: json['cancellation_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((dynamic e) => e?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  final String id;
  final String title;
  final String? description;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String type;
  final String? roomId;
  final String? meetingLink;
  final List<String> participants;
  final String? createdById;
  final String? createdByUsername;
  final String status;
  final MeetingChangeRequest? changeRequestData;
  final String? cancellationReason;
  final String? createdAt;
  final String? updatedAt;
}

/// Extrait `YYYY-MM-DD` d'une date backend (`YYYY-MM-DD` ou ISO `T...Z`).
String? meetingDateOnly(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final RegExpMatch? match =
      RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(value);
  return match?.group(1);
}

/// Extrait `HH:MM` d'une heure backend (`HH:MM:SS`).
String? meetingTimeOnly(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final RegExpMatch? match = RegExp(r'^(\d{2}:\d{2})').firstMatch(value);
  return match?.group(1);
}

/// Compare deux réunions par date puis heure de début (tri ascendant).
int compareMeetingsByDate(Meeting a, Meeting b) {
  final String ad = a.date ?? '';
  final String bd = b.date ?? '';
  if (ad != bd) {
    return ad.compareTo(bd);
  }
  final String as = a.startTime ?? '';
  final String bs = b.startTime ?? '';
  return as.compareTo(bs);
}
