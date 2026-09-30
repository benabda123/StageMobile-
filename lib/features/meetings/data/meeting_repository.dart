import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/meeting_model.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository(ref.watch(dioProvider));
});

class MeetingRepository {
  MeetingRepository(this._dio);

  final Dio _dio;

  /// Mes réunions (`GET /meetings/mine`).
  Future<List<Meeting>> getMyMeetings() async {
    final Response<dynamic> response = await _dio.get('/meetings/mine');
    return _parseList(response.data);
  }

  /// Toutes les réunions, filtrable côté serveur par statut
  /// (`GET /meetings?status=...`), réservé admin / manager.
  Future<List<Meeting>> getAllMeetings({String? status}) async {
    final Response<dynamic> response = await _dio.get(
      '/meetings',
      queryParameters:
          status == null ? null : <String, dynamic>{'status': status},
    );
    return _parseList(response.data);
  }

  /// Crée une réunion (`POST /meetings`). Une erreur 400 du backend
  /// (ex. « Room unavailable for this time slot ») remonte telle quelle.
  Future<Meeting> createMeeting({
    required String title,
    String? description,
    required String date,
    required String startTime,
    required String endTime,
    required String type,
    String? roomId,
    String? meetingLink,
    List<String> participants = const <String>[],
  }) async {
    final Response<dynamic> response = await _dio.post(
      '/meetings',
      data: <String, dynamic>{
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'type': type,
        if (type == MeetingType.presentiel && roomId != null)
          'room_id': int.tryParse(roomId),
        if (type == MeetingType.online &&
            meetingLink != null &&
            meetingLink.trim().isNotEmpty)
          'meeting_link': meetingLink.trim(),
        'participants': participants,
      },
    );
    return _parseMeeting(response.data);
  }

  /// Approuve une réunion (`PUT /meetings/:id/approve`), admin / manager.
  Future<Meeting> approveMeeting(String meetingId) async {
    final Response<dynamic> response =
        await _dio.put('/meetings/$meetingId/approve');
    return _parseMeeting(response.data);
  }

  /// Refuse une réunion (`PUT /meetings/:id/reject`), admin / manager.
  Future<Meeting> rejectMeeting(String meetingId) async {
    final Response<dynamic> response =
        await _dio.put('/meetings/$meetingId/reject');
    return _parseMeeting(response.data);
  }

  /// Demande un changement (`PUT /meetings/:id/request-change`), créateur.
  Future<Meeting> requestMeetingChange(
    String meetingId, {
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/meetings/$meetingId/request-change',
      data: <String, dynamic>{
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'reason': reason,
      },
    );
    return _parseMeeting(response.data);
  }

  /// Résout une demande de changement (`PUT /meetings/:id/resolve-change`),
  /// admin / manager.
  Future<Meeting> resolveMeetingChange(
    String meetingId, {
    required bool accept,
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/meetings/$meetingId/resolve-change',
      data: <String, dynamic>{'accept': accept},
    );
    return _parseMeeting(response.data);
  }

  /// Annule une réunion (`PUT /meetings/:id/cancel`), créateur.
  Future<Meeting> cancelMeeting(
    String meetingId, {
    required String reason,
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/meetings/$meetingId/cancel',
      data: <String, dynamic>{'reason': reason},
    );
    return _parseMeeting(response.data);
  }

  Meeting _parseMeeting(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Meeting.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  List<Meeting> _parseList(dynamic data) {
    if (data is! List) {
      return const <Meeting>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Meeting.fromJson)
        .toList();
  }
}
