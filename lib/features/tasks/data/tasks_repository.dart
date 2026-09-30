import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/task.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(dioProvider));
});

class TasksRepository {
  TasksRepository(this._dio);

  final Dio _dio;

  Future<List<Task>> getMyTasks() async {
    final Response<dynamic> response = await _dio.get('/tasks/my');
    return _parseTaskList(response.data);
  }

  /// Toutes les tâches de l'entreprise (réservé admin / manager).
  Future<List<Task>> getAllTasks() async {
    final Response<dynamic> response = await _dio.get('/tasks');
    return _parseTaskList(response.data);
  }

  List<Task> _parseTaskList(dynamic data) {
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['tasks'] is List) {
      list = data['tasks'] as List;
    } else {
      return const <Task>[];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }

  Future<Task> updateTaskStatus(String taskId, String status) async {
    final Response<dynamic> response =
        await _dio.patch('/tasks/$taskId/status', data: <String, dynamic>{
      'status': status,
    });
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return Task.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }
}
