import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

/// Liste des notifications avec polling toutes les 30 secondes.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

/// Nombre de notifications non lues (badge cloche).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (List<AppNotification> items) =>
            items.where((AppNotification n) => n.isUnread).length,
        orElse: () => 0,
      );
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  Timer? _pollTimer;

  @override
  Future<List<AppNotification>> build() async {
    ref.watch(authControllerProvider);
    ref.onDispose(() => _pollTimer?.cancel());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollSilently(),
    );
    return ref.read(notificationRepositoryProvider).getMyNotifications();
  }

  Future<void> _pollSilently() async {
    if (ref.read(authControllerProvider).status != AuthStatus.authenticated) {
      return;
    }
    try {
      final List<AppNotification> items =
          await ref.read(notificationRepositoryProvider).getMyNotifications();
      state = AsyncData(items);
    } catch (_) {
      // Conserve l'état courant en cas d'échec réseau ponctuel.
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).getMyNotifications(),
    );
  }

  Future<void> markAsRead(int id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    final List<AppNotification>? current = state.value;
    if (current == null) {
      return;
    }
    final String now = DateTime.now().toUtc().toIso8601String();
    state = AsyncData(
      current
          .map(
            (AppNotification n) => n.id == id
                ? n.copyWith(
                    status: NotificationStatus.read,
                    readAt: now,
                  )
                : n,
          )
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    final List<AppNotification>? current = state.value;
    if (current == null) {
      return;
    }
    final String now = DateTime.now().toUtc().toIso8601String();
    state = AsyncData(
      current
          .map(
            (AppNotification n) => n.isUnread
                ? n.copyWith(
                    status: NotificationStatus.read,
                    readAt: now,
                  )
                : n,
          )
          .toList(),
    );
  }

  Future<void> deleteNotification(int id) async {
    await ref.read(notificationRepositoryProvider).deleteNotification(id);
    final List<AppNotification>? current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.where((AppNotification n) => n.id != id).toList(),
    );
  }
}
