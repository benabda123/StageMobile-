import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/room_model.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(ref.watch(dioProvider));
});

class RoomRepository {
  RoomRepository(this._dio);

  final Dio _dio;

  /// Liste des salles (`GET /rooms`).
  Future<List<MeetingRoom>> getRooms() async {
    final Response<dynamic> response = await _dio.get('/rooms');
    final dynamic data = response.data;
    if (data is! List) {
      return const <MeetingRoom>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(MeetingRoom.fromJson)
        .toList();
  }

  /// Crée une salle (`POST /rooms`), admin / manager.
  Future<MeetingRoom> createRoom({
    required String name,
    required int capacity,
    List<String> equipment = const <String>[],
  }) async {
    final Response<dynamic> response = await _dio.post(
      '/rooms',
      data: <String, dynamic>{
        'name': name,
        'capacity': capacity,
        'equipment': equipment,
      },
    );
    return _parseRoom(response.data);
  }

  /// Modifie une salle (`PUT /rooms/:id`), admin / manager.
  Future<MeetingRoom> updateRoom(
    String roomId, {
    required String name,
    required int capacity,
    List<String> equipment = const <String>[],
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/rooms/$roomId',
      data: <String, dynamic>{
        'name': name,
        'capacity': capacity,
        'equipment': equipment,
      },
    );
    return _parseRoom(response.data);
  }

  /// Supprime une salle (`DELETE /rooms/:id`), admin / manager.
  Future<void> deleteRoom(String roomId) async {
    await _dio.delete('/rooms/$roomId');
  }

  MeetingRoom _parseRoom(dynamic data) {
    if (data is Map<String, dynamic>) {
      return MeetingRoom.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }
}
