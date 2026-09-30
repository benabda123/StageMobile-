import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tasks_repository.dart';
import '../domain/task.dart';

final tasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(tasksRepositoryProvider).getMyTasks();
});

/// Toutes les tâches (admin / manager).
final allTasksProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(tasksRepositoryProvider).getAllTasks();
});
