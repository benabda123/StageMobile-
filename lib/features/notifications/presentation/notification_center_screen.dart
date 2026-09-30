import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../domain/notification_model.dart';
import 'notifications_provider.dart';

/// Regroupement par jour pour l'affichage de la liste.
enum _DayGroup {
  today,
  yesterday,
  older,
}

/// Centre de notifications (`GET /notifications/my`).
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key, this.embedded = false});

  /// `true` dans l'onglet employé — l'AppBar est portée par le parent.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> notifications =
        ref.watch(notificationsProvider);

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('Notifications'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => _markAllRead(context, ref),
                  child: const Text('Tout marquer lu'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Se déconnecter',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _markAllRead(context, ref),
                  child: const Text('Tout marquer lu'),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
              child: notifications.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => ListView(
                  children: <Widget>[
                    const SizedBox(height: 48),
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Impossible de charger les notifications.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                data: (List<AppNotification> items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: const <Widget>[
                        SizedBox(height: 48),
                        Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Aucune notification pour le moment',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  final Map<_DayGroup, List<AppNotification>> grouped =
                      _groupByDay(items);

                  return ListView(
                    children: <Widget>[
                      for (final MapEntry<_DayGroup, List<AppNotification>> entry
                          in grouped.entries)
                        if (entry.value.isNotEmpty) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _dayGroupLabel(entry.key),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ),
                          for (final AppNotification notification
                              in entry.value)
                            _NotificationTile(
                              notification: notification,
                              onTap: () =>
                                  _onTap(context, ref, notification),
                              onDismiss: () =>
                                  _delete(context, ref, notification),
                            ),
                        ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsProvider.notifier).markAllAsRead();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isUnread) {
      return;
    }
    try {
      await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    try {
      await ref
          .read(notificationsProvider.notifier)
          .deleteNotification(notification.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Map<_DayGroup, List<AppNotification>> _groupByDay(
    List<AppNotification> items,
  ) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    final List<AppNotification> sorted = List<AppNotification>.from(items)
      ..sort((AppNotification a, AppNotification b) {
        final DateTime? da = _parseDate(a.createdAt);
        final DateTime? db = _parseDate(b.createdAt);
        if (da == null && db == null) {
          return 0;
        }
        if (da == null) {
          return 1;
        }
        if (db == null) {
          return -1;
        }
        return db.compareTo(da);
      });

    final Map<_DayGroup, List<AppNotification>> grouped =
        <_DayGroup, List<AppNotification>>{
      _DayGroup.today: <AppNotification>[],
      _DayGroup.yesterday: <AppNotification>[],
      _DayGroup.older: <AppNotification>[],
    };

    for (final AppNotification notification in sorted) {
      final DateTime? created = _parseDate(notification.createdAt);
      if (created == null) {
        grouped[_DayGroup.older]!.add(notification);
        continue;
      }
      final DateTime day =
          DateTime(created.year, created.month, created.day);
      if (day == today) {
        grouped[_DayGroup.today]!.add(notification);
      } else if (day == yesterday) {
        grouped[_DayGroup.yesterday]!.add(notification);
      } else {
        grouped[_DayGroup.older]!.add(notification);
      }
    }
    return grouped;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _dayGroupLabel(_DayGroup group) {
    switch (group) {
      case _DayGroup.today:
        return 'Aujourd\'hui';
      case _DayGroup.yesterday:
        return 'Hier';
      case _DayGroup.older:
        return 'Plus ancien';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey<int>(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: notification.isUnread
            ? colors.primary.withValues(alpha: 0.06)
            : null,
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Icon(
                _iconForType(notification.type),
                color: colors.primary,
              ),
              if (notification.isUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            notification.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return Icons.task_alt;
      case NotificationType.leave:
        return Icons.event_available;
      case NotificationType.meeting:
        return Icons.calendar_month;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.employee:
        return Icons.person;
      case NotificationType.announcement:
        return Icons.campaign;
    }
  }
}
