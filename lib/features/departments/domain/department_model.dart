/// Département de l'entreprise (`GET /departments`).
class Department {
  const Department({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'];
    return Department(
      id: idValue is int ? idValue : int.tryParse('$idValue') ?? 0,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? createdAt;
}
