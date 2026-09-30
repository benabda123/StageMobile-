import 'package:flutter/material.dart';

import 'module_menu.dart';

/// Accueil manager : Tâches (développé, toutes les tâches) + placeholders
/// Réunions et Salles.
class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScaffold(
      title: 'Manager',
      items: <ModuleMenuItem>[
        ModuleMenuItem(
          label: 'Tâches',
          icon: Icons.task_alt,
          path: '/admin/tasks',
        ),
        ModuleMenuItem(
          label: 'Réunions',
          icon: Icons.event_outlined,
          path: '/admin/meetings',
        ),
        ModuleMenuItem(
          label: 'Salles',
          icon: Icons.meeting_room_outlined,
          path: '/admin/rooms',
        ),
        ModuleMenuItem(
          label: 'Assistant IA',
          icon: Icons.auto_awesome,
          path: '/ai/meeting-plan',
        ),
      ],
    );
  }
}
