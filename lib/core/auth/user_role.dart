/// Rôles métier de l'application Keystone.
///
/// Priorité décroissante (même principe que `getUserRole()` côté web) :
///   admin > manager > hr > itsupport > employee
/// Quand un compte possède plusieurs rôles, le rôle le plus élevé dans cette
/// liste gagne (ex. `itsupport1` a `employee` + `itsupport` → `itsupport`).
enum UserRole { admin, manager, hr, itsupport, employee }

extension UserRoleInfo on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.manager:
        return 'Manager';
      case UserRole.hr:
        return 'Ressources Humaines';
      case UserRole.itsupport:
        return 'Support IT';
      case UserRole.employee:
        return 'Employé';
    }
  }
}

/// Retourne le rôle prioritaire contenu dans [roles] (défaut : `employee`).
UserRole highestPriorityRole(Iterable<String> roles) {
  if (roles.contains('admin')) return UserRole.admin;
  if (roles.contains('manager')) return UserRole.manager;
  if (roles.contains('hr')) return UserRole.hr;
  if (roles.contains('itsupport')) return UserRole.itsupport;
  return UserRole.employee;
}
