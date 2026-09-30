import 'package:flutter/material.dart';

import 'module_menu.dart';

/// Accueil admin : accès à tous les modules. Seul « Tâches » est développé
/// (toutes les tâches) ; les autres modules sont des placeholders.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScaffold(
      title: 'Administration',
      items: <ModuleMenuItem>[
        ModuleMenuItem(
          label: 'Employés',
          icon: Icons.people_outline,
          path: '/hr/employees',
        ),
        ModuleMenuItem(
          label: 'Départements',
          icon: Icons.apartment_outlined,
          path: '/admin/departments',
        ),
        ModuleMenuItem(
          label: 'Tâches',
          icon: Icons.task_alt,
          path: '/admin/tasks',
        ),
        ModuleMenuItem(
          label: 'Congés',
          icon: Icons.beach_access_outlined,
          path: '/hr/leaves',
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
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          path: '/notifications',
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
