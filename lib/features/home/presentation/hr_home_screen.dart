import 'package:flutter/material.dart';

import 'module_menu.dart';

/// Accueil RH : placeholders Employés et Congés.
class HrHomeScreen extends StatelessWidget {
  const HrHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScaffold(
      title: 'Ressources Humaines',
      items: <ModuleMenuItem>[
        ModuleMenuItem(
          label: 'Employés',
          icon: Icons.people_outline,
          path: '/hr/employees',
        ),
        ModuleMenuItem(
          label: 'Congés',
          icon: Icons.beach_access_outlined,
          path: '/hr/leaves',
        ),
      ],
    );
  }
}
