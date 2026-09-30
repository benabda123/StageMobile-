import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../domain/leave_model.dart';
import 'leave_ui.dart';
import 'leaves_provider.dart';

/// Mes demandes de congé (`GET /leaves/mine`).
class MyLeavesScreen extends ConsumerWidget {
  const MyLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Leave>> leaves = ref.watch(myLeavesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes congés'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/leaves/new'),
        tooltip: 'Nouvelle demande',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myLeavesProvider.future),
        child: leaves.when(
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
            if (items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 48),
                  Icon(Icons.beach_access_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucune demande de congé.', textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(
                    'Touchez + pour créer une demande.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Leave leave = items[index];
                return ListTile(
                  leading: Icon(
                    leaveTypeIcon(leave.type),
                    color: leaveStatusColor(leave.status),
                  ),
                  title: Text(leaveTypeLabel(leave.type)),
                  subtitle: Text(
                    '${formatLeaveDate(leave.startDate)} → '
                    '${formatLeaveDate(leave.endDate)}'
                    '${leave.reason == null || leave.reason!.isEmpty ? '' : '\n${leave.reason}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: LeaveStatusBadge(status: leave.status),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
