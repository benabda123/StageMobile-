import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../domain/task.dart';
import 'task_ui.dart';
import 'tasks_provider.dart';

/// Liste de toutes les tâches (admin / manager) via `GET /tasks`.
class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Task>> tasks = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toutes les tâches'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allTasksProvider.future),
        child: tasks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => ErrorStateWidget(
            message: ErrorStateWidget.humanMessage(error),
            onRetry: () => ref.invalidate(allTasksProvider),
          ),
          data: (List<Task> items) {
            if (items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 48),
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucune tâche.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Task task = items[index];
                final String assignee =
                    task.employeeUsername ?? task.employeeId ?? 'Non assignée';
                return ListTile(
                  leading: Icon(
                    Icons.task_alt,
                    color: taskStatusColor(task.status),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    '$assignee · ${taskStatusLabel(task.status)} · '
                    '${taskPriorityLabel(task.priority)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/admin/tasks/${task.id}', extra: task),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
