import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/employee_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(dioProvider));
});

class EmployeeRepository {
  EmployeeRepository(this._dio);

  final Dio _dio;

  /// Liste des employés (`GET /auth/employees`), admin / hr.
  Future<List<Employee>> getEmployees() async {
    final Response<dynamic> response = await _dio.get('/auth/employees');
    final dynamic data = response.data;
    if (data is! List) {
      return const <Employee>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Employee.fromJson)
        .toList();
  }

  /// Crée un employé (`POST /auth/employees`), admin / hr.
  Future<void> createEmployee({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    String? position,
    String? phone,
  }) async {
    final EmployeeAttributes attributes = EmployeeAttributes(
      position: position,
      phone: phone,
    );
    final Map<String, dynamic> body = <String, dynamic>{
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
    };
    final Map<String, List<String>> attrs = attributes.toCreateJson();
    if (attrs.isNotEmpty) {
      body['attributes'] = attrs;
    }
    await _dio.post('/auth/employees', data: body);
  }

  /// Supprime un employé (`DELETE /auth/employees/:id`), admin / hr.
  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/auth/employees/$id');
  }
}
