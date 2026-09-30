import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/profile_model.dart';
import 'profile_provider.dart';

/// Édition complète du profil : photo (upload immédiat), liens GitHub et
/// LinkedIn (enregistrés ensemble).
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _initialized = false;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  /// Preremplit les champs une seule fois, quand le profil arrive. On ne
  /// réinitialise jamais ensuite (l'utilisateur peut être en train de saisir).
  void _initControllers(Profile? profile) {
    if (_initialized || profile == null) {
      return;
    }
    _initialized = true;
    _githubController.text = profile.githubUrl ?? '';
    _linkedinController.text = profile.linkedinUrl ?? '';
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Caméra'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    setState(() => _uploading = true);
    try {
      await ref.read(profileProvider.notifier).uploadAvatar(picked);
      if (mounted) {
        _showSnack('Photo de profil mise à jour.');
      }
    } catch (e) {
      // Le backend renvoie un message clair (2 Mo max, jpeg/png/webp).
      if (mounted) {
        _showSnack(apiErrorMessage(e), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String? _validateUrl(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    final bool isHttp = uri?.isScheme('http') ?? false;
    final bool isHttps = uri?.isScheme('https') ?? false;
    if (uri == null || (!isHttp && !isHttps) || uri.host.isEmpty) {
      return 'URL invalide (doit commencer par http:// ou https://)';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).saveLinks(
            githubUrl: _githubController.text.trim(),
            linkedinUrl: _linkedinController.text.trim(),
          );
      if (mounted) {
        _showSnack('Profil enregistré.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(apiErrorMessage(e), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Profile> profileAsync = ref.watch(profileProvider);
    final Profile? profile = profileAsync.valueOrNull;
    _initControllers(profile);

    final String? username = ref.watch(currentUsernameProvider);
    final String initials =
        profile?.initials ?? _usernameInitial(username);
    final String? avatarUrl =
        (profile?.hasAvatar ?? false) ? profile!.avatarUrl : null;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Mon profil',
          style: TextStyle(color: GlassTokens.textPrimary, fontSize: 18),
        ),
        showLogo: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: _BigAvatar(
              url: avatarUrl,
              initials: initials,
              radius: 50,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _displayName(profile, username),
              style: const TextStyle(
                color: GlassTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (profile?.email != null && profile!.email!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  profile.email!,
                  style: const TextStyle(color: GlassTokens.textSecondary),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAvatar,
              style: OutlinedButton.styleFrom(
                foregroundColor: GlassTokens.textPrimary,
                side: const BorderSide(color: GlassTokens.glassBorderStrong),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GlassTokens.textPrimary,
                      ),
                    )
                  : const Icon(Icons.photo_camera_outlined, size: 20),
              label: Text(_uploading ? 'Upload en cours…' : 'Changer la photo'),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'JPG, PNG ou WEBP — 2 Mo maximum',
              style: TextStyle(color: GlassTokens.textHint, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GlassTextField(
                  controller: _githubController,
                  label: 'Lien GitHub',
                  hint: 'https://github.com/votre-nom',
                  keyboardType: TextInputType.url,
                  validator: _validateUrl,
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _linkedinController,
                  label: 'Lien LinkedIn',
                  hint: 'https://linkedin.com/in/votre-nom',
                  keyboardType: TextInputType.url,
                  validator: _validateUrl,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GlassPrimaryButton(
            label: 'Enregistrer',
            loading: _saving,
            icon: Icons.save_outlined,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  static String _displayName(Profile? profile, String? username) {
    final String? firstName = profile?.firstName;
    final String? lastName = profile?.lastName;
    if (firstName != null && firstName.isNotEmpty) {
      final String last = lastName ?? '';
      return last.isNotEmpty ? '$firstName $last' : firstName;
    }
    final String? trimmed = username?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : 'Mon profil';
  }

  static String _usernameInitial(String? username) {
    final String? trimmed = username?.trim();
    return (trimmed != null && trimmed.isNotEmpty)
        ? trimmed[0].toUpperCase()
        : '?';
  }
}

/// Aperçu de l'avatar (photo ou initiales) pour l'écran de réglages.
class _BigAvatar extends StatelessWidget {
  const _BigAvatar({
    required this.url,
    required this.initials,
    required this.radius,
  });

  final String? url;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget inner;
    if (url != null) {
      inner = ClipOval(
        child: Image.network(
          url!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? progress) {
            return progress == null
                ? child
                : _InitialsContent(initials: initials);
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? _) {
            return _InitialsContent(initials: initials);
          },
        ),
      );
    } else {
      inner = _InitialsContent(initials: initials);
    }

    return GlassBlur(
      borderRadius: BorderRadius.circular(radius),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: GlassTokens.activeFill,
        child: inner,
      ),
    );
  }
}

class _InitialsContent extends StatelessWidget {
  const _InitialsContent({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: GlassTokens.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
    );
  }
}
