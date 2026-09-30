import 'package:dio/dio.dart';

/// Retourne le message d'erreur exact renvoyé par le backend quand la réponse
/// contient un corps `{ "error": "..." }` ou `{ "message": "..." }` — ex.
/// « Room unavailable for this time slot » pour un conflit horaire 400 —
/// sinon un message générique.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final dynamic data = error.response?.data;
    if (data is Map) {
      final dynamic msg = data['error'] ?? data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
  }
  return 'Erreur réseau. Vérifiez votre connexion.';
}
