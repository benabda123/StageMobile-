import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_tokens.dart';
import '../../core/widgets/glass_widgets.dart';
import 'password_reset_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
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
      final String message = await ref
          .read(passwordResetRepositoryProvider)
          .forgotPassword(email: _emailController.text.trim());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      context.go(
        '/reset-password',
        extra: _emailController.text.trim(),
      );
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
                        Icons.lock_reset,
                        size: 56,
                        color: GlassTokens.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mot de passe oublié',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Saisissez votre adresse email. Un code de\nréinitialisation vous sera envoyé.',
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_loading) {
                            _submit();
                          }
                        },
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'ex. youcef@keystone.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: GlassTokens.textSecondary,
                            size: 20,
                          ),
                          labelStyle: const TextStyle(
                            color: GlassTokens.textSecondary,
                          ),
                          hintStyle: const TextStyle(
                            color: GlassTokens.textHint,
                          ),
                          filled: true,
                          fillColor: GlassTokens.glassFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlassTokens.glassRadius,
                            ),
                            borderSide: const BorderSide(
                              color: GlassTokens.glassBorderStrong,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlassTokens.glassRadius,
                            ),
                            borderSide: const BorderSide(
                              color: GlassTokens.glassBorderStrong,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlassTokens.glassRadius,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primaryLight,
                              width: 1.5,
                            ),
                          ),
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
                                  'Envoyer le code',
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
}
