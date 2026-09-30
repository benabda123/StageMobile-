import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';

/// Profil de l'utilisateur connecté, chargé après login et gardé en mémoire.
///
/// Écoute [authControllerProvider] : le profil est rechargé à chaque nouvelle
/// session et le provider repasse en erreur proprement à la déconnexion.
final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    ref.watch(authControllerProvider);
    return ref.read(profileRepositoryProvider).getMyProfile();
  }

  /// Recharge le profil depuis le serveur (`GET /auth/profile/me`).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMyProfile(),
    );
  }

  /// Upload d'une photo de profil puis mise à jour immédiate de l'état.
  Future<void> uploadAvatar(XFile file) async {
    final String avatarUrl =
        await ref.read(profileRepositoryProvider).uploadAvatar(file);
    final Profile? current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(avatarUrl: avatarUrl));
    }
  }

  /// Enregistre les liens GitHub / LinkedIn puis met à jour l'état.
  Future<void> saveLinks({
    required String githubUrl,
    required String linkedinUrl,
  }) async {
    final Profile updated = await ref
        .read(profileRepositoryProvider)
        .updateLinks(githubUrl: githubUrl, linkedinUrl: linkedinUrl);
    state = AsyncData(updated);
  }
}
