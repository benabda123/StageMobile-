/// Employé Keycloak (`GET /auth/employees`).
class Employee {
  const Employee({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.enabled = true,
    this.attributes = const EmployeeAttributes(),
    this.realmRoleNames = const <String>[],
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      attributes: EmployeeAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>?,
      ),
      realmRoleNames: (json['realmRoleNames'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
    );
  }

  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final EmployeeAttributes attributes;
  final List<String> realmRoleNames;

  String get fullName {
    final String first = firstName?.trim() ?? '';
    final String last = lastName?.trim() ?? '';
    final String combined = '$first $last'.trim();
    return combined.isEmpty ? username : combined;
  }
}

/// Attributs Keycloak — chaque clé est une liste de chaînes côté API.
class EmployeeAttributes {
  const EmployeeAttributes({
    this.position,
    this.phone,
    this.departmentId,
    this.avatarUrl,
    this.githubUrl,
    this.linkedinUrl,
  });

  factory EmployeeAttributes.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmployeeAttributes();
    }
    return EmployeeAttributes(
      position: _firstString(json['position']),
      phone: _firstString(json['phone']),
      departmentId: _firstString(json['departmentId']),
      avatarUrl: _firstString(json['avatarUrl']),
      githubUrl: _firstString(json['githubUrl']),
      linkedinUrl: _firstString(json['linkedinUrl']),
    );
  }

  final String? position;
  final String? phone;
  final String? departmentId;
  final String? avatarUrl;
  final String? githubUrl;
  final String? linkedinUrl;

  Map<String, List<String>> toCreateJson() {
    final Map<String, List<String>> map = <String, List<String>>{};
    if (position != null && position!.isNotEmpty) {
      map['position'] = <String>[position!];
    }
    if (phone != null && phone!.isNotEmpty) {
      map['phone'] = <String>[phone!];
    }
    if (departmentId != null && departmentId!.isNotEmpty) {
      map['departmentId'] = <String>[departmentId!];
    }
    return map;
  }

  static String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
