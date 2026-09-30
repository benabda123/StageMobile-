import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/profile_model.dart';
import 'profile_provider.dart';

/// Avatar de l'utilisateur connecté pour le header des écrans d'accueil.
///
/// Affiche la photo de profil si elle existe, sinon les initiales (même
/// fallback que le frontend web). Un tap ouvre [ProfileSettingsScreen].
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Profile? profile = ref.watch(profileProvider).valueOrNull;
    final String? username = ref.watch(currentUsernameProvider);
    final String initials = profile?.initials ?? _usernameInitial(username);

    final Widget inner = (profile?.hasAvatar ?? false)
        ? _AvatarImage(url: profile!.avatarUrl!, fallback: initials)
        : _InitialsCircle(text: initials);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Mon profil',
        child: InkWell(
          onTap: () => context.push('/profile/settings'),
          borderRadius: BorderRadius.circular(20),
          child: GlassBlur(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: GlassTokens.activeFill,
              child: inner,
            ),
          ),
        ),
      ),
    );
  }

  static String _usernameInitial(String? username) {
    final String? trimmed = username?.trim();
    return (trimmed != null && trimmed.isNotEmpty)
        ? trimmed[0].toUpperCase()
        : '?';
  }
}

/// Photo de profil ronde avec repli sur les initiales en cas d'échec réseau.
class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, required this.fallback});

  final String url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? progress) {
          return progress == null ? child : _InitialsCircle(text: fallback);
        },
        errorBuilder: (BuildContext context, Object error, StackTrace? _) {
          return _InitialsCircle(text: fallback);
        },
      ),
    );
  }
}

/// Cercle d'initiales dans la taille de l'avatar du header.
class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: GlassTokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
