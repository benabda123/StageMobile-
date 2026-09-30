import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_repository.dart';
import '../domain/learning_item.dart';

final learningSearchProvider =
    FutureProvider.family<List<LearningItem>, String>((ref, String query) async {
  if (query.trim().isEmpty) {
    return const <LearningItem>[];
  }
  final LearningRepository repo = ref.watch(learningRepositoryProvider);
  return repo.searchLearning(query);
});
