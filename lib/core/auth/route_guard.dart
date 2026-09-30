import 'user_role.dart';

/// Premier segment significatif d'une route : `/tasks/5/status` → `tasks`.
String _firstSegment(String location) {
  final Iterable<String> parts =
      location.split('/').where((String s) => s.isNotEmpty);
  return parts.isEmpty ? '' : parts.first;
}

/// Segments de premier niveau autorisés pour chaque rôle.
///
/// L'employé n'accède qu'à son espace (`/tasks`, `/tickets`, `/home`,
/// `/module`) ; les rôles back-office accèdent à `/home` et `/module`, seul
/// admin/manager accède à `/admin/*` (toutes les tâches) et seul admin /
/// itsupport accède à `/itsupport/*` (tous les tickets). Tout segment
/// inconnu → refus.
Set<String> _allowedFirstSegments(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return <String>{'home', 'admin', 'module', 'itsupport', 'tickets', 'hr', 'notifications', 'profile', 'learning', 'ai', 'meetings'};
    case UserRole.manager:
      return <String>{'home', 'admin', 'module', 'notifications', 'profile', 'learning', 'ai', 'meetings'};
    case UserRole.hr:
      return <String>{'home', 'module', 'hr', 'notifications', 'profile', 'learning'};
    case UserRole.itsupport:
      return <String>{'home', 'module', 'itsupport', 'tickets', 'notifications', 'profile', 'learning'};
    case UserRole.employee:
      return <String>{'home', 'tasks', 'module', 'tickets', 'leaves', 'meetings', 'notifications', 'profile', 'learning'};
  }
}

/// Vrai si [role] est autorisé à consulter [location].
bool roleCanAccess(UserRole role, String location) {
  return _allowedFirstSegments(role).contains(_firstSegment(location));
}
