import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../data/ai_assistant_repository.dart';

class AiMeetingInputScreen extends ConsumerStatefulWidget {
  const AiMeetingInputScreen({super.key});

  @override
  ConsumerState<AiMeetingInputScreen> createState() =>
      _AiMeetingInputScreenState();
}

class _AiMeetingInputScreenState extends ConsumerState<AiMeetingInputScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _objectiveController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dynamic plan = await ref
          .read(aiAssistantRepositoryProvider)
          .generateMeetingPlan(
            objective: _objectiveController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.push('/ai/meeting-plan/result', extra: plan);
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
            title: const Text('Assistant IA'),
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
                        Icons.auto_awesome,
                        size: 56,
                        color: GlassTokens.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Planification de réunion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Décrivez l\'objectif de votre réunion et\nl\'IA générera un plan détaillé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTokens.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _objectiveController,
                        enabled: !_loading,
                        maxLines: 5,
                        minLines: 3,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Objectif de la réunion',
                          hintText:
                              'Ex: Réunion avec l\'équipe de développement pour faire le point sur les tâches en retard et planifier le sprint suivant',
                          alignLabelWithHint: true,
                          labelStyle: const TextStyle(
                            color: GlassTokens.textSecondary,
                          ),
                          hintStyle: const TextStyle(
                            color: GlassTokens.textHint,
                            fontSize: 13,
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
                          if ((value ?? '').trim().isEmpty) {
                            return 'Veuillez décrire l\'objectif de la réunion.';
                          }
                          if (value!.trim().length < 10) {
                            return 'Veuillez fournir plus de détails (10 caractères min).';
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
                          onPressed: _loading ? null : _generate,
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
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const <Widget>[
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'L\'IA analyse vos données...',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const <Widget>[
                                    Icon(Icons.auto_awesome, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Générer le plan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
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
