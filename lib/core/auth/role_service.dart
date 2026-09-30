import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'auth_service.dart';
import 'user_role.dart';

/// Extrait le rôle de l'utilisateur depuis le token d'accès Keycloak.
///
/// Structure attendue dans le JWT (identique au frontend web) :
///   realm_access.roles: ["offline_access", "admin", "uma_authorization", ...]
class RoleService {
  /// Décode [session.accessToken] et retourne le rôle prioritaire.
  /// Retourne [UserRole.employee] par défaut si le token est absent/invalide
  /// ou ne contient aucun rôle connu (même comportement que le web).
  UserRole getUserRole(AuthSession? session) {
    if (session == null) {
      return UserRole.employee;
    }
    final Map<String, dynamic>? claims =
        JwtDecoder.tryDecode(session.accessToken);
    if (claims == null) {
      return UserRole.employee;
    }

    final List<String> roles = <String>[];
    final dynamic realmAccess = claims['realm_access'];
    if (realmAccess is Map) {
      final dynamic realmRoles = realmAccess['roles'];
      if (realmRoles is List) {
        roles.addAll(realmRoles.whereType<String>());
      }
    }

    return highestPriorityRole(roles);
  }

  /// Nom d'utilisateur (`preferred_username`) contenu dans le token, ou null.
  String? getUsername(AuthSession? session) {
    if (session == null) {
      return null;
    }
    final Map<String, dynamic>? claims =
        JwtDecoder.tryDecode(session.accessToken);
    if (claims == null) {
      return null;
    }
    final dynamic username = claims['preferred_username'];
    return username is String ? username : null;
  }
}

final roleServiceProvider = Provider<RoleService>((ref) => RoleService());
