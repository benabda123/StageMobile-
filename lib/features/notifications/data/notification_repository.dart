import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  /// Mes notifications (`GET /notifications/my`).
  Future<List<AppNotification>> getMyNotifications() async {
    final Response<dynamic> response = await _dio.get('/notifications/my');
    final dynamic data = response.data;
    if (data is! List) {
      return const <AppNotification>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  /// Marque une notification comme lue (`PUT /notifications/:id/read`).
  Future<void> markAsRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  /// Marque toutes les notifications comme lues (`PUT /notifications/read-all`).
  Future<void> markAllAsRead() async {
    await _dio.put('/notifications/read-all');
  }

  /// Supprime une notification (`DELETE /notifications/:id`).
  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id');
  }
}
