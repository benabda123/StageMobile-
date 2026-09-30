import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/network/api_error.dart';
import '../data/department_repository.dart';
import '../domain/department_model.dart';
import 'departments_provider.dart';

/// Liste des départements (`GET /departments`) — réservé admin. Le bouton
/// « + » et les actions Modifier / Supprimer ne sont affichés que pour le
/// rôle admin.
class DepartmentListScreen extends ConsumerWidget {
  const DepartmentListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Department department,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Supprimer le département'),
        content: Text(
          'Supprimer « ${department.name} » ? Cette action est irréversible.',
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
      await ref.read(departmentRepositoryProvider).deleteDepartment(department.id);
      ref.invalidate(departmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Département supprimé.')),
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
    final bool isAdmin = ref.watch(userRoleProvider) == UserRole.admin;
    final AsyncValue<List<Department>> departments =
        ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Départements'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/departments/form'),
              tooltip: 'Nouveau département',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(departmentsProvider.future),
        child: departments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => ListView(
            children: <Widget>[
              const SizedBox(height: 48),
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Impossible de charger les départements.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          data: (List<Department> items) {
            if (items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 48),
                  Icon(Icons.apartment_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucun département pour le moment',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Touchez + pour créer un département.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final Department department = items[index];
                return ListTile(
                  leading: const Icon(Icons.apartment_outlined),
                  title: Text(department.name),
                  subtitle: Text(
                    department.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Modifier',
                              onPressed: () => context.push(
                                '/admin/departments/form',
                                extra: department,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Supprimer',
                              onPressed: () =>
                                  _confirmDelete(context, ref, department),
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
