import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/department_model.dart';

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return DepartmentRepository(ref.watch(dioProvider));
});

class DepartmentRepository {
  DepartmentRepository(this._dio);

  final Dio _dio;

  /// Liste des départements (`GET /departments`) — tout utilisateur
  /// authentifié peut lire.
  Future<List<Department>> getDepartments() async {
    final Response<dynamic> response = await _dio.get('/departments');
    final dynamic data = response.data;
    if (data is! List) {
      return const <Department>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Department.fromJson)
        .toList();
  }

  /// Crée un département (`POST /departments`), admin uniquement.
  Future<Department> createDepartment({
    required String name,
    String? description,
  }) async {
    final Response<dynamic> response = await _dio.post(
      '/departments',
      data: <String, dynamic>{
        'name': name,
        'description': description,
      },
    );
    return _parseDepartment(response.data);
  }

  /// Modifie un département (`PUT /departments/:id`), admin uniquement.
  Future<Department> updateDepartment(
    int id, {
    required String name,
    String? description,
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/departments/$id',
      data: <String, dynamic>{
        'name': name,
        'description': description,
      },
    );
    return _parseDepartment(response.data);
  }

  /// Supprime un département (`DELETE /departments/:id`), admin uniquement.
  Future<void> deleteDepartment(int id) async {
    await _dio.delete('/departments/$id');
  }

  Department _parseDepartment(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Department.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }
}
