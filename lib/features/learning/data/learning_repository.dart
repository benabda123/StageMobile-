import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/learning_item.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(dioProvider));
});

class LearningRepository {
  LearningRepository(this._dio);

  final Dio _dio;

  Future<List<LearningItem>> searchLearning(String query) async {
    debugPrint('Fetching learning search: $query');
    try {
      final Response<dynamic> response = await _dio.get(
        '/learning/search',
        queryParameters: <String, dynamic>{'query': query},
      );
      debugPrint('Learning response: ${response.data}');
      final dynamic data = response.data;
      final List<dynamic> list;
      if (data is Map<String, dynamic> && data['results'] is List) {
        list = data['results'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return const <LearningItem>[];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(LearningItem.fromJson)
          .toList();
    } catch (error) {
      debugPrint('Learning error: $error');
      rethrow;
    }
  }
}
