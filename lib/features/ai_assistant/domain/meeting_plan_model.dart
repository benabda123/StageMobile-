class MeetingPlanParticipant {
  const MeetingPlanParticipant({
    required this.username,
    required this.reason,
  });

  final String username;
  final String reason;

  factory MeetingPlanParticipant.fromJson(Map<String, dynamic> json) {
    return MeetingPlanParticipant(
      username: json['username'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class MeetingPlanAgendaItem {
  const MeetingPlanAgendaItem({
    required this.topic,
    required this.minutes,
  });

  final String topic;
  final int minutes;

  factory MeetingPlanAgendaItem.fromJson(Map<String, dynamic> json) {
    return MeetingPlanAgendaItem(
      topic: json['topic'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class MeetingPlan {
  const MeetingPlan({
    required this.title,
    required this.objective,
    required this.durationMinutes,
    required this.durationReason,
    required this.participants,
    required this.agenda,
    required this.suggestedQuestions,
  });

  final String title;
  final String objective;
  final int durationMinutes;
  final String durationReason;
  final List<MeetingPlanParticipant> participants;
  final List<MeetingPlanAgendaItem> agenda;
  final Map<String, List<String>> suggestedQuestions;

  factory MeetingPlan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> participantsJson =
        json['participants'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> agendaJson =
        json['agenda'] as List<dynamic>? ?? const <dynamic>[];

    final Map<String, dynamic> questionsJson =
        json['suggestedQuestions'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
    final Map<String, List<String>> questions = questionsJson.map(
      (String key, dynamic value) => MapEntry<String, List<String>>(
        key,
        (value as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList() ??
            const <String>[],
      ),
    );

    return MeetingPlan(
      title: json['title'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      durationReason: json['durationReason'] as String? ?? '',
      participants: participantsJson
          .map((dynamic e) =>
              MeetingPlanParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      agenda: agendaJson
          .map((dynamic e) =>
              MeetingPlanAgendaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestedQuestions: questions,
    );
  }
}
