import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tasks_repository.dart';
import '../domain/task.dart';
import 'task_ui.dart';
import 'tasks_provider.dart';

class UpdateTaskStatusScreen extends ConsumerStatefulWidget {
  const UpdateTaskStatusScreen({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<UpdateTaskStatusScreen> createState() =>
      _UpdateTaskStatusScreenState();
}

class _UpdateTaskStatusScreenState extends ConsumerState<UpdateTaskStatusScreen> {
  static const List<String> _statuses = <String>['TODO', 'IN_PROGRESS', 'DONE'];

  String? _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.task.status;
  }

  Future<void> _save() async {
    final String target = _selected ?? widget.task.status;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(tasksRepositoryProvider)
          .updateTaskStatus(widget.task.id, target);
      ref.invalidate(tasksProvider);
      ref.invalidate(allTasksProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Échec de la mise à jour du statut.\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changer le statut')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          for (final String status in _statuses)
            ListTile(
              leading: Icon(
                _selected == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _selected == status
                    ? taskStatusColor(status)
                    : Colors.grey,
              ),
              title: Text(taskStatusLabel(status)),
              subtitle: Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: taskStatusColor(status),
                    ),
              ),
              onTap: () => setState(() => _selected = status),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ),
      ),
    );
  }
}
