import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/leave_model.dart';
import 'leave_ui.dart';
import 'leaves_provider.dart';

/// Onglet Congés : liste en cartes glass + accès au formulaire.
class LeaveTabScreen extends ConsumerWidget {
  const LeaveTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Leave>> leaves = ref.watch(myLeavesProvider);

    return RefreshIndicator(
      color: GlassTokens.accentBorder,
      onRefresh: () => ref.refresh(myLeavesProvider.future),
      child: leaves.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => ListView(
          children: <Widget>[
            GlassEmptyState(
              message: 'Impossible de charger vos congés',
              subtitle: '$error',
              icon: Icons.error_outline,
            ),
          ],
        ),
        data: (List<Leave> items) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Mes congés',
                          style: TextStyle(
                            color: GlassTokens.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/leaves/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nouveau'),
                        style: TextButton.styleFrom(
                          foregroundColor: GlassTokens.accentBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  child: GlassEmptyState(
                    message: 'Aucune demande de congé',
                    subtitle: 'Créez votre première demande',
                    icon: Icons.beach_access_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final Leave leave = items[index];
                        return GlassListCard(
                          icon: leaveTypeIcon(leave.type),
                          title: leaveTypeLabel(leave.type),
                          subtitle:
                              '${formatLeaveDate(leave.startDate)} → ${formatLeaveDate(leave.endDate)}'
                              '${leave.reason == null || leave.reason!.isEmpty ? '' : '\n${leave.reason}'}',
                          badge: LeaveStatusBadge(status: leave.status),
                          footer: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/leaves/mine'),
                              child: const Text('Détails'),
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
