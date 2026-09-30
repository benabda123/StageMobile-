import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/leave_model.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(dioProvider));
});

class LeaveRepository {
  LeaveRepository(this._dio);

  final Dio _dio;

  /// Mes demandes (`GET /leaves/mine`).
  Future<List<Leave>> getMyLeaves() async {
    final Response<dynamic> response = await _dio.get('/leaves/mine');
    return _parseList(response.data);
  }

  /// Toutes les demandes, filtrable côté serveur par statut
  /// (`GET /leaves?status=...`), réservé admin / hr.
  Future<List<Leave>> getAllLeaves({String? status}) async {
    final Response<dynamic> response = await _dio.get(
      '/leaves',
      queryParameters:
          status == null ? null : <String, dynamic>{'status': status},
    );
    return _parseList(response.data);
  }

  /// Crée une demande (`POST /leaves`).
  Future<Leave> createLeave({
    required String type,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final Response<dynamic> response = await _dio.post(
      '/leaves',
      data: <String, dynamic>{
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return Leave.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  /// Approuve une demande (`PUT /leaves/:id/approve`), admin / hr.
  Future<Leave> approveLeave(String leaveId) async {
    final Response<dynamic> response =
        await _dio.put('/leaves/$leaveId/approve');
    return _parseLeave(response.data);
  }

  /// Refuse une demande (`PUT /leaves/:id/reject`), admin / hr.
  Future<Leave> rejectLeave(String leaveId) async {
    final Response<dynamic> response =
        await _dio.put('/leaves/$leaveId/reject');
    return _parseLeave(response.data);
  }

  Leave _parseLeave(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Leave.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  List<Leave> _parseList(dynamic data) {
    if (data is! List) {
      return const <Leave>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Leave.fromJson)
        .toList();
  }
}
