import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/department_repository.dart';
import '../domain/department_model.dart';

/// Liste des départements (`GET /departments`).
final departmentsProvider = FutureProvider<List<Department>>((ref) {
  return ref.watch(departmentRepositoryProvider).getDepartments();
});
