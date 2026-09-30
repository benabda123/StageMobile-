import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/user_role.dart';
import 'admin_home_screen.dart';
import 'employee_home_screen.dart';
import 'hr_home_screen.dart';
import 'itsupport_home_screen.dart';
import 'manager_home_screen.dart';

/// Route `/home` : rend l'écran d'accueil correspondant au rôle courant.
class HomeRouter extends ConsumerWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserRole role = ref.watch(userRoleProvider) ?? UserRole.employee;
    switch (role) {
      case UserRole.admin:
        return const AdminHomeScreen();
      case UserRole.manager:
        return const ManagerHomeScreen();
      case UserRole.hr:
        return const HrHomeScreen();
      case UserRole.itsupport:
        return const ItSupportHomeScreen();
      case UserRole.employee:
        return const EmployeeHomeScreen();
    }
  }
}
