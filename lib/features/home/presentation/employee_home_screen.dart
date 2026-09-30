import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../notifications/presentation/notification_bell_widget.dart';
import '../../leaves/presentation/leave_tab_screen.dart';
import '../../learning/presentation/learning_screen.dart';
import '../../meetings/presentation/my_meetings_screen.dart';
import '../../profile/presentation/profile_avatar_widget.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../tickets/presentation/my_tickets_screen.dart';

/// Shell employé : header glass + bottom nav (Congés, Tâches, Réunions,
/// Learning, Support) sur fond WAVES animé.
class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  int _index = 0;

  static const List<GlassNavItem> _navItems = <GlassNavItem>[
    GlassNavItem(icon: Icons.calendar_month_outlined, label: 'Congés'),
    GlassNavItem(icon: Icons.task_alt_outlined, label: 'Tâches'),
    GlassNavItem(icon: Icons.videocam_outlined, label: 'Réunions'),
    GlassNavItem(icon: Icons.school_outlined, label: 'Learning'),
    GlassNavItem(icon: Icons.confirmation_num_outlined, label: 'Support'),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const LeaveTabScreen(),
      const TasksScreen(appBarEnabled: false),
      const MyMeetingsScreen(embedded: true),
      const LearningScreen(embedded: true),
      const MyTicketsScreen(embedded: true),
    ];

    return GlassScaffold(
      appBar: GlassAppBar(
        actions: <Widget>[
          const NotificationBellWidget(),
          const ProfileAvatar(),
          IconButton(
            icon: const Icon(Icons.logout, color: GlassTokens.textSecondary),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: (int i) => setState(() => _index = i),
        items: _navItems,
      ),
    );
  }
}
