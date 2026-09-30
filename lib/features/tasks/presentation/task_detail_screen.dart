import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/task.dart';
import 'task_ui.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.initialTask});

  final Task initialTask;

  @override
  Widget build(BuildContext context) {
    final Task current = initialTask;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la tâche')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            current.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                label: Text(taskStatusLabel(current.status)),
                backgroundColor: taskStatusColor(current.status).withValues(alpha: 0.15),
                labelStyle: TextStyle(color: taskStatusColor(current.status)),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('Priorité ${taskPriorityLabel(current.priority)}'),
                backgroundColor: taskPriorityColor(current.priority).withValues(alpha: 0.15),
                labelStyle: TextStyle(color: taskPriorityColor(current.priority)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailSection(
            icon: Icons.description_outlined,
            label: 'Description',
            value: current.description == null || current.description!.isEmpty
                ? '—'
                : current.description!,
          ),
          const SizedBox(height: 16),
          _DetailSection(
            icon: Icons.event,
            label: 'Échéance',
            value: _formatDate(current.dueDate),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            icon: Icons.person_outline,
            label: 'Assignée à',
            value: current.employeeUsername ?? '—',
          ),
          const SizedBox(height: 16),
          _DetailSection(
            icon: Icons.event_note,
            label: 'Créée le',
            value: _formatDate(current.createdAt),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => context.push('status', extra: current),
            icon: const Icon(Icons.update),
            label: const Text('Changer le statut'),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final DateTime local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
