import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../domain/leave_model.dart';
import 'leaves_provider.dart';

/// Tableau de bord des congés (statistiques) — accessible depuis la bottom
/// navigation de l'employé. Donne accès à la liste et au formulaire.
class LeaveDashboardScreen extends ConsumerWidget {
  const LeaveDashboardScreen({super.key, this.embedded = false});

  /// `true` quand l'écran est intégré dans un onglet (l'AppBar est alors
  /// portée par l'écran parent).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Leave>> leaves = ref.watch(myLeavesProvider);

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(
              title: const Text('Mes congés'),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Se déconnecter',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
      body: leaves.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => ListView(
          children: <Widget>[
            const SizedBox(height: 48),
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Impossible de charger vos congés.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        data: (List<Leave> items) {
          final LeaveStats stats = LeaveStats.fromLeaves(items);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myLeavesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: <Widget>[
                    _StatCard(
                      label: 'Congés restants',
                      value: '${stats.daysRemaining}',
                      icon: Icons.hourglass_bottom,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatCard(
                      label: 'En attente',
                      value: '${stats.pendingCount}',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Acceptées',
                      value: '${stats.approvedCount}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Refusées',
                      value: '${stats.rejectedCount}',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/leaves/mine'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Mes demandes'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/leaves/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle demande'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
