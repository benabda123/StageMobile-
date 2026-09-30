import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_tokens.dart';
import 'notifications_provider.dart';

/// Icône cloche avec badge du nombre de notifications non lues.
/// Poll automatique via [notificationsProvider] (30 s).
class NotificationBellWidget extends ConsumerWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsProvider);
    final int unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: GlassTokens.errorRed,
        label: Text(
          '$unreadCount',
          style: const TextStyle(color: GlassTokens.textPrimary, fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined, color: GlassTokens.textPrimary),
      ),
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
    );
  }
}
