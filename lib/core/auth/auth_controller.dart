import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'role_service.dart';
import 'user_role.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({required this.status, this.role, this.username});

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        role = null,
        username = null;
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        role = null,
        username = null;
  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        role = null,
        username = null;
  const AuthState.authenticated({this.role, this.username})
      : status = AuthStatus.authenticated;

  final AuthStatus status;

  /// Rôle décodé depuis le token au moment du login / restore.
  final UserRole? role;

  /// Nom d'utilisateur (`preferred_username`) décodé depuis le token.
  final String? username;
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Rôle de l'utilisateur courant, recalculé à chaque changement d'état
/// d'authentification (login, restore de session, logout).
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authControllerProvider).role;
});

/// Nom d'utilisateur courant, recalculé à chaque login / restore.
final currentUsernameProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).username;
});

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState.unknown();
  }

  Future<void> _restoreSession() async {
    final AuthService auth = ref.read(authServiceProvider);
    final AuthSession? session = await auth.getSession();
    if (session != null) {
      final RoleService roleService = ref.read(roleServiceProvider);
      final UserRole role = roleService.getUserRole(session);
      final String? username = roleService.getUsername(session);
      state = AuthState.authenticated(role: role, username: username);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState.authenticating();
    try {
      final AuthSession session = await ref
          .read(authServiceProvider)
          .login(username: username, password: password);
      final RoleService roleService = ref.read(roleServiceProvider);
      final UserRole role = roleService.getUserRole(session);
      final String? sessionUsername = roleService.getUsername(session);
      state =
          AuthState.authenticated(role: role, username: sessionUsername);
    } catch (_) {
      state = const AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AuthState.unauthenticated();
  }
}
