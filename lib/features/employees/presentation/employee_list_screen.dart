import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../data/employee_repository.dart';
import '../domain/employee_model.dart';
import 'employees_provider.dart';

/// Liste des employés (`GET /auth/employees`) — admin / hr.
class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'employé'),
        content: Text(
          'Supprimer « ${employee.fullName} » (${employee.username}) ? '
          'Cette action est irréversible.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(employeeRepositoryProvider).deleteEmployee(employee.id);
      ref.invalidate(employeesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employé supprimé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Employee>> employees = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employés'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/hr/employees/form'),
        tooltip: 'Nouvel employé',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(employeesProvider.future),
        child: employees.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => ListView(
            children: <Widget>[
              const SizedBox(height: 48),
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Impossible de charger les employés.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          data: (List<Employee> items) {
            if (items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 48),
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucun employé pour le moment',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Touchez + pour créer un employé.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final Employee employee = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      child: Text(
                        employee.fullName.isNotEmpty
                            ? employee.fullName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(employee.fullName),
                    subtitle: Text(
                      '@${employee.username} · ${employee.email}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _DetailRow(
                              label: 'Statut',
                              value: employee.enabled ? 'Actif' : 'Désactivé',
                            ),
                            if (employee.attributes.position != null)
                              _DetailRow(
                                label: 'Poste',
                                value: employee.attributes.position!,
                              ),
                            if (employee.attributes.phone != null)
                              _DetailRow(
                                label: 'Téléphone',
                                value: employee.attributes.phone!,
                              ),
                            if (employee.attributes.departmentId != null)
                              _DetailRow(
                                label: 'Département',
                                value: employee.attributes.departmentId!,
                              ),
                            if (employee.realmRoleNames.isNotEmpty)
                              _DetailRow(
                                label: 'Rôles',
                                value: employee.realmRoleNames.join(', '),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                label: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, ref, employee),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
