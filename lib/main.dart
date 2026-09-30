import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/route_guard.dart';
import 'core/auth/user_role.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_assistant/domain/meeting_plan_model.dart';
import 'features/ai_assistant/presentation/ai_meeting_input_screen.dart';
import 'features/ai_assistant/presentation/ai_meeting_plan_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/departments/domain/department_model.dart';
import 'features/departments/presentation/department_form_screen.dart';
import 'features/departments/presentation/department_list_screen.dart';
import 'features/employees/presentation/employee_form_screen.dart';
import 'features/employees/presentation/employee_list_screen.dart';
import 'features/home/presentation/home_router.dart';
import 'features/home/presentation/module_placeholder_screen.dart';
import 'features/learning/presentation/learning_results_screen.dart';
import 'features/leaves/presentation/hr_leave_requests_screen.dart';
import 'features/leaves/presentation/my_leaves_screen.dart';
import 'features/leaves/presentation/new_leave_screen.dart';
import 'features/meetings/domain/meeting_model.dart';
import 'features/meetings/presentation/manager_meeting_requests_screen.dart';
import 'features/meetings/presentation/meeting_detail_screen.dart';
import 'features/meetings/presentation/new_meeting_screen.dart';
import 'features/meetings/presentation/room_management_screen.dart';
import 'features/notifications/presentation/notification_center_screen.dart';
import 'features/profile/presentation/profile_settings_screen.dart';
import 'features/tasks/domain/task.dart';
import 'features/tasks/presentation/all_tasks_screen.dart';
import 'features/tasks/presentation/task_detail_screen.dart';
import 'features/tasks/presentation/tasks_screen.dart';
import 'features/tasks/presentation/update_task_status_screen.dart';
import 'features/tickets/presentation/itsupport_tickets_screen.dart';
import 'features/tickets/presentation/my_tickets_screen.dart';
import 'features/tickets/presentation/new_ticket_screen.dart';
import 'features/tickets/presentation/ticket_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authControllerProvider);
      final String location = state.matchedLocation;

      // Restauration de session en cours : ne pas rediriger vers /login
      // avant de savoir si un token est présent (évite une race post-démarrage).
      if (auth.status == AuthStatus.unknown) {
        return null;
      }

      final bool isLoggedIn = auth.status == AuthStatus.authenticated;
      if (!isLoggedIn) {
        final bool isPublicRoute =
            location == '/login' ||
            location == '/forgot-password' ||
            location == '/reset-password';
        return isPublicRoute ? null : '/login';
      }
      if (location == '/login') {
        return '/home';
      }

      // Protection des routes par rôle : un rôle ne peut pas accéder aux
      // segments interdits, même par URL directe.
      final UserRole role = ref.read(userRoleProvider) ?? UserRole.employee;
      if (!roleCanAccess(role, location)) {
        return '/home';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            LoginScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (BuildContext context, GoRouterState state) =>
            ResetPasswordScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeRouter(),
      ),
      GoRoute(
        path: '/module/:moduleId',
        builder: (BuildContext context, GoRouterState state) =>
            ModulePlaceholderScreen(
          moduleId: state.pathParameters['moduleId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/tasks',
        builder: (BuildContext context, GoRouterState state) =>
            const TasksScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (BuildContext context, GoRouterState state) =>
                TaskDetailScreen(
              initialTask: state.extra as Task,
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'status',
                builder: (BuildContext context, GoRouterState state) =>
                    UpdateTaskStatusScreen(task: state.extra as Task),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin/tasks',
        builder: (BuildContext context, GoRouterState state) =>
            const AllTasksScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (BuildContext context, GoRouterState state) =>
                TaskDetailScreen(
              initialTask: state.extra as Task,
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'status',
                builder: (BuildContext context, GoRouterState state) =>
                    UpdateTaskStatusScreen(task: state.extra as Task),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin/departments',
        builder: (BuildContext context, GoRouterState state) =>
            const DepartmentListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'form',
            builder: (BuildContext context, GoRouterState state) =>
                DepartmentFormScreen(
              department: state.extra as Department?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/tickets/mine',
        builder: (BuildContext context, GoRouterState state) =>
            const MyTicketsScreen(),
      ),      GoRoute(
        path: '/tickets/new',
        builder: (BuildContext context, GoRouterState state) =>
            const NewTicketScreen(),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (BuildContext context, GoRouterState state) =>
            TicketDetailScreen(
          ticketId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/itsupport/tickets',
        builder: (BuildContext context, GoRouterState state) =>
            const ItSupportTicketsScreen(),
      ),
      GoRoute(
        path: '/leaves/mine',
        builder: (BuildContext context, GoRouterState state) =>
            const MyLeavesScreen(),
      ),
      GoRoute(
        path: '/leaves/new',
        builder: (BuildContext context, GoRouterState state) =>
            const NewLeaveScreen(),
      ),
      GoRoute(
        path: '/hr/leaves',
        builder: (BuildContext context, GoRouterState state) =>
            const HrLeaveRequestsScreen(),
      ),
      GoRoute(
        path: '/hr/employees',
        builder: (BuildContext context, GoRouterState state) =>
            const EmployeeListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'form',
            builder: (BuildContext context, GoRouterState state) =>
                const EmployeeFormScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/meetings/new',
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic>? preset =
              state.extra as Map<String, dynamic>?;
          return NewMeetingScreen(
            presetTitle: preset?['title'] as String?,
            presetDescription: preset?['description'] as String?,
            presetParticipants: preset?['participants'] as String?,
            presetDurationMinutes:
                (preset?['durationMinutes'] as num?)?.toInt(),
          );
        },
      ),
      GoRoute(
        path: '/meetings/:id',
        builder: (BuildContext context, GoRouterState state) =>
            MeetingDetailScreen(meeting: state.extra as Meeting),
      ),
      GoRoute(
        path: '/admin/meetings',
        builder: (BuildContext context, GoRouterState state) =>
            const ManagerMeetingRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/rooms',
        builder: (BuildContext context, GoRouterState state) =>
            const RoomManagementScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/ai/meeting-plan',
        builder: (BuildContext context, GoRouterState state) =>
            const AiMeetingInputScreen(),
      ),
      GoRoute(
        path: '/ai/meeting-plan/result',
        builder: (BuildContext context, GoRouterState state) =>
            AiMeetingPlanScreen(plan: state.extra as MeetingPlan),
      ),
      GoRoute(
        path: '/learning/results',
        builder: (BuildContext context, GoRouterState state) {
          final String query = state.uri.queryParameters['query'] ?? '';
          return LearningResultsScreen(query: query);
        },
      ),
    ],
  );
});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KeystoneApp()));
}

class KeystoneApp extends ConsumerWidget {
  const KeystoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    ref.listen(authControllerProvider, (AuthState? previous, AuthState next) {
      if (next.status == AuthStatus.authenticated) {
        router.go('/home');
      } else if (next.status == AuthStatus.unauthenticated) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'Keystone Mobile',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
