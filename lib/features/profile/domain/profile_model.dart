/// Profil de l'utilisateur connecté (`GET /auth/profile/me`).
///
/// Les champs arrivent en camelCase du backend ; les URLs vides sont
/// normalisées en `null` pour un traitement UI plus simple.
class Profile {
  const Profile({
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.githubUrl,
    this.linkedinUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      avatarUrl: _nonEmpty(json['avatarUrl']),
      githubUrl: _nonEmpty(json['githubUrl']),
      linkedinUrl: _nonEmpty(json['linkedinUrl']),
    );
  }

  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? githubUrl;
  final String? linkedinUrl;

  /// Vrai si un avatar a été défini.
  bool get hasAvatar =>
      avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  /// Initiales pour le fallback avatar (même règle que le frontend web :
  /// prénom + nom, sinon la première lettre du username).
  String get initials {
    final String first = (firstName ?? '').trim();
    final String last = (lastName ?? '').trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '${_firstLetter(first)}${_firstLetter(last)}'.toUpperCase();
    }
    final String usernameTrimmed = username.trim();
    return usernameTrimmed.isNotEmpty
        ? usernameTrimmed[0].toUpperCase()
        : 'U';
  }

  Profile copyWith({
    String? avatarUrl,
    String? githubUrl,
    String? linkedinUrl,
  }) {
    return Profile(
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    );
  }

  static String? _nonEmpty(dynamic value) {
    final String? text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return text.trim();
  }

  static String _firstLetter(String text) {
    return text.isNotEmpty ? text.substring(0, 1) : '';
  }
}
