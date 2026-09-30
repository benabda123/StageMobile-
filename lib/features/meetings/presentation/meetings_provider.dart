import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_repository.dart';
import '../data/room_repository.dart';
import '../domain/meeting_model.dart';
import '../domain/room_model.dart';

/// Mes réunions (`GET /meetings/mine`).
final myMeetingsProvider = FutureProvider<List<Meeting>>((ref) {
  return ref.watch(meetingRepositoryProvider).getMyMeetings();
});

/// Toutes les réunions (`GET /meetings`), réservé admin / manager.
final allMeetingsProvider = FutureProvider<List<Meeting>>((ref) {
  return ref.watch(meetingRepositoryProvider).getAllMeetings();
});

/// Liste des salles (`GET /rooms`).
final roomsProvider = FutureProvider<List<MeetingRoom>>((ref) {
  return ref.watch(roomRepositoryProvider).getRooms();
});
