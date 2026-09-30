import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leave_repository.dart';
import '../domain/leave_model.dart';

/// Mes demandes de congé (`GET /leaves/mine`).
final myLeavesProvider = FutureProvider<List<Leave>>((ref) {
  return ref.watch(leaveRepositoryProvider).getMyLeaves();
});

/// Toutes les demandes (`GET /leaves`), réservé admin / hr.
final allLeavesProvider = FutureProvider<List<Leave>>((ref) {
  return ref.watch(leaveRepositoryProvider).getAllLeaves();
});
