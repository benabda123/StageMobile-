import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../notifications/presentation/notification_bell_widget.dart';
import '../../profile/presentation/profile_avatar_widget.dart';

/// Entrée de menu d'un écran d'accueil back-office.
class ModuleMenuItem {
  const ModuleMenuItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}

/// Liste de cartes glass cliquables.
class ModuleMenuList extends StatelessWidget {
  const ModuleMenuList({super.key, required this.items});

  final List<ModuleMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ModuleMenuItem item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassBlur(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(item.icon, color: GlassTokens.accentBorder),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    color: GlassTokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: GlassTokens.textSecondary,
                ),
                onTap: () => context.push(item.path),
              ),
            ),
          ),
      ],
    );
  }
}

/// Gabarit accueil back-office avec header glass + fond WAVES.
class RoleHomeScaffold extends ConsumerWidget {
  const RoleHomeScaffold({super.key, required this.title, required this.items});

  final String title;
  final List<ModuleMenuItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole role = ref.watch(userRoleProvider) ?? UserRole.employee;

    return GlassScaffold(
      appBar: GlassAppBar(
        actions: <Widget>[
          const NotificationBellWidget(),
          const ProfileAvatar(),
          IconButton(
            icon: const Icon(Icons.logout, color: GlassTokens.textSecondary),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          GlassBlur(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const Icon(Icons.badge_outlined, color: GlassTokens.accentBorder),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rôle : ${role.label}',
                        style: const TextStyle(color: GlassTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModuleMenuList(items: items),
        ],
      ),
    );
  }
}
