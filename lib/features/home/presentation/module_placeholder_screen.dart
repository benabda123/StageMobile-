import 'package:flutter/material.dart';

import '../domain/module_catalog.dart';

/// Écran provisoire pour un module non encore développé en Flutter.
///
/// [embedded] : rendu sans `Scaffold`/`AppBar`, pour être intégré dans un
/// corps d'écran parent (ex. onglet de la bottom navigation employé).
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.moduleId,
    this.embedded = false,
  });

  final String moduleId;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final Module? module = ModuleCatalog.byId(moduleId);
    final Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            module?.icon ?? Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            module?.label ?? 'Module',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Module en cours de développement',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: Text(module?.label ?? 'Module')),
      body: content,
    );
  }
}
