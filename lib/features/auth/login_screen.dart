import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_tokens.dart';
import '../../core/widgets/glass_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _inlineError = null);

    try {
      await ref.read(authControllerProvider.notifier).login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _inlineError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _inlineError = 'Échec de la connexion. Veuillez réessayer.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isBusy = authState.status == AuthStatus.authenticating;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const WavesBackground(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassBlur(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Icon(
                        Icons.work_outline,
                        size: 56,
                        color: GlassTokens.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Keystone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connectez-vous pour accéder à votre espace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !isBusy,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: GlassTokens.textPrimary),
                        decoration: _fieldDecoration(
                          label: "Nom d'utilisateur",
                          hint: 'ex. youcef',
                          icon: Icons.person_outline,
                        ),
                        validator: (String? value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Veuillez saisir votre nom d\'utilisateur.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !isBusy,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!isBusy) {
                            _login();
                          }
                        },
                        style: const TextStyle(color: GlassTokens.textPrimary),
                        decoration: _fieldDecoration(
                          label: 'Mot de passe',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: GlassTokens.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if ((value ?? '').isEmpty) {
                            return 'Veuillez saisir votre mot de passe.';
                          }
                          return null;
                        },
                      ),
                      if (_inlineError != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.error_outline,
                              color: GlassTokens.errorRed,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _inlineError!,
                                style: const TextStyle(
                                  color: GlassTokens.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: isBusy ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GlassTokens.glassRadius,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const <Widget>[
                                    Icon(Icons.login, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: isBusy
                              ? null
                              : () => context.push('/forgot-password'),
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: GlassTokens.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: GlassTokens.textSecondary, size: 20),
      labelStyle: const TextStyle(color: GlassTokens.textSecondary),
      hintStyle: const TextStyle(color: GlassTokens.textHint),
      filled: true,
      fillColor: GlassTokens.glassFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
        borderSide: const BorderSide(color: GlassTokens.glassBorderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
        borderSide: const BorderSide(color: GlassTokens.glassBorderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );
  }
}
