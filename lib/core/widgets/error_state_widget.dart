import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';
import 'glass_widgets.dart';

/// Widget d'erreur réutilisable : message utilisateur propre + bouton Réessayer.
/// Garanti sans overflow (contenu centré dans un espace minuscule).
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.onRetry,
    this.message = 'Impossible de charger les données.',
    this.icon = Icons.error_outline,
  });

  final VoidCallback onRetry;
  final String message;
  final IconData icon;

  /// Interprète une erreur brute en message utilisateur propre.
  static String humanMessage(Object error) {
    final String raw = error.toString();
    if (raw.contains('401') || raw.contains('Unauthorized')) {
      return 'Session expirée. Réessayez.';
    }
    if (raw.contains('500') || raw.contains('Internal Server')) {
      return 'Erreur serveur. Réessayez plus tard.';
    }
    if (raw.contains('timeout') ||
        raw.contains('connection') ||
        raw.contains('SocketException')) {
      return 'Serveur injoignable. Vérifiez votre connexion.';
    }
    return 'Impossible de charger les données. Vérifiez votre connexion et réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassBlur(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: GlassTokens.errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GlassTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: GlassTokens.submitBlue,
                foregroundColor: GlassTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
