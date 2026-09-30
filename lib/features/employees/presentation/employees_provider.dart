import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_repository.dart';
import '../domain/employee_model.dart';

/// Liste des employés (`GET /auth/employees`).
final employeesProvider = FutureProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).getEmployees();
});
