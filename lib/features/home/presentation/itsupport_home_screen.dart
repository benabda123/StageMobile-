import 'package:flutter/material.dart';

import 'module_menu.dart';

/// Accueil Support IT : module Tickets développé.
class ItSupportHomeScreen extends StatelessWidget {
  const ItSupportHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeScaffold(
      title: 'Support IT',
      items: <ModuleMenuItem>[
        ModuleMenuItem(
          label: 'Tickets',
          icon: Icons.support_agent,
          path: '/itsupport/tickets',
        ),
      ],
    );
  }
}
