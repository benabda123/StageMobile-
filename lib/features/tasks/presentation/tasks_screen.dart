import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/task.dart';
import 'task_ui.dart';
import 'tasks_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.appBarEnabled = true});

  final bool appBarEnabled;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _statuses = <String>['TODO', 'IN_PROGRESS', 'DONE'];
  static const List<String> _labels = <String>['À faire', 'En cours', 'Terminée'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody(context, ref);
    if (!widget.appBarEnabled) {
      return body;
    }
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Mes tâches',
          style: TextStyle(color: GlassTokens.textPrimary, fontSize: 18),
        ),
        showLogo: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: GlassTokens.textSecondary),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Task>> tasks = ref.watch(tasksProvider);

    return tasks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => ErrorStateWidget(
        message: ErrorStateWidget.humanMessage(error),
        onRetry: () => ref.invalidate(tasksProvider),
      ),
      data: (List<Task> items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: const Text(
                'Mes tâches',
                style: TextStyle(
                  color: GlassTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassBlur(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: GlassTokens.activeFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTokens.activeBorder),
                    boxShadow: GlassTokens.activeGlowShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: GlassTokens.textPrimary,
                  unselectedLabelColor: GlassTokens.textSecondary,
                  tabs: List<Tab>.generate(3, (int i) {
                    final int count =
                        items.where((Task t) => t.status == _statuses[i]).length;
                    return Tab(text: '${_labels[i]} ($count)');
                  }),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List<Widget>.generate(3, (int i) {
                  final List<Task> filtered = items
                      .where((Task t) => t.status == _statuses[i])
                      .toList();
                  if (filtered.isEmpty) {
                    return const GlassEmptyState(
                      message: 'Aucune tâche',
                      icon: Icons.task_alt_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: GlassTokens.accentBorder,
                    onRefresh: () => ref.refresh(tasksProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: filtered
                          .map(
                            (Task task) => GlassListCard(
                              icon: Icons.task_alt,
                              title: task.title,
                              subtitle:
                                  '${taskPriorityLabel(task.priority)}'
                                  '${task.dueDate != null ? ' · ${task.dueDate}' : ''}',
                              badge: GlassStatusBadge(
                                label: taskStatusLabel(task.status),
                                color: taskStatusColor(task.status),
                              ),
                              footer: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push(
                                    '/tasks/${task.id}',
                                    extra: task,
                                  ),
                                  child: const Text('Détails'),
                                ),
                              ),
                              onTap: () => context.push(
                                '/tasks/${task.id}',
                                extra: task,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
