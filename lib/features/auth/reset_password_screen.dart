import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_tokens.dart';
import '../../core/widgets/glass_widgets.dart';
import 'password_reset_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(passwordResetRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès.'),
        ),
      );

      context.go('/login', extra: _emailController.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const WavesBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: Center(
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
                        Icons.vpn_key,
                        size: 56,
                        color: GlassTokens.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Réinitialiser le mot de passe',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Saisissez le code reçu par email et\nvotre nouveau mot de passe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (String? value) {
                          final String v = (value ?? '').trim();
                          if (v.isEmpty) {
                            return 'Veuillez saisir votre email.';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Adresse email invalide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codeController,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                          letterSpacing: 8,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        decoration: _fieldDecoration(
                          label: 'Code à 6 chiffres',
                          icon: Icons.pin,
                        ),
                        validator: (String? value) {
                          final String v = (value ?? '').trim();
                          if (v.isEmpty) {
                            return 'Veuillez saisir le code.';
                          }
                          if (v.length != 6) {
                            return 'Le code doit faire exactement 6 chiffres.';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                            return 'Le code ne doit contenir que des chiffres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Nouveau mot de passe',
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
                            return 'Veuillez saisir un mot de passe.';
                          }
                          if (value!.length < 6) {
                            return 'Le mot de passe doit faire au moins 6 caractères.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmController,
                        enabled: !_loading,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Confirmer le mot de passe',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirm
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: GlassTokens.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if ((value ?? '').isEmpty) {
                            return 'Veuillez confirmer le mot de passe.';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...<Widget>[
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
                                _error!,
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
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GlassTokens.glassRadius,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Réinitialiser',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
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
        borderSide: const BorderSide(
          color: AppColors.primaryLight,
          width: 1.5,
        ),
      ),
    );
  }
}
