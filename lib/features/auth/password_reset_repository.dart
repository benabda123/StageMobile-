import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';

final Provider<PasswordResetRepository> passwordResetRepositoryProvider =
    Provider<PasswordResetRepository>(
  (Ref<PasswordResetRepository> ref) => PasswordResetRepository(),
);

/// Repository pour les routes publiques de réinitialisation du mot de passe.
///
/// Utilise un [Dio] dédié **sans intercepteur JWT** : ces deux endpoints
/// sont accessibles avant login et ne nécessitent aucun token.
class PasswordResetRepository {
  PasswordResetRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: <String, dynamic>{'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  /// Demande l'envoi d'un code de réinitialisation par email.
  ///
  /// Le backend utilise un flux en 2 étapes :
  ///   1. `confirm: false` → vérifie si l'email existe
  ///   2. `confirm: true`  → génère et envoie le code
  ///
  /// Le message retourné est **toujours le même** que l'email existe ou non
  /// (sécurité : ne pas révéler si un compte existe).
  Future<String> forgotPassword({required String email}) async {
    const String genericMessage =
        'Un code de réinitialisation vous a été envoyé par email.';

    try {
      // Étape 1 : vérification de l'existence du compte
      final Response<dynamic> checkResponse = await _dio.post<dynamic>(
        '/auth/forgot-password',
        data: <String, dynamic>{'email': email, 'confirm': false},
      );
      final dynamic checkBody = checkResponse.data;
      final bool found = checkBody is Map<String, dynamic> &&
          checkBody['found'] == true;

      if (!found) {
        // Email inconnu → on affiche le message générique quand même (sécurité).
        return genericMessage;
      }

      // Étape 2 : demande la génération et l'envoi du code
      final Response<dynamic> sendResponse = await _dio.post<dynamic>(
        '/auth/forgot-password',
        data: <String, dynamic>{'email': email, 'confirm': true},
      );
      final dynamic sendBody = sendResponse.data;
      if (sendBody is Map<String, dynamic>) {
        return (sendBody['message'] as String?) ?? genericMessage;
      }
      return genericMessage;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Réinitialise le mot de passe avec le code reçu par email.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/reset-password',
        data: <String, dynamic>{
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  String _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Serveur injoignable. Vérifiez la connexion et réessayez.';
    }
    final int? status = error.response?.statusCode;
    final dynamic body = error.response?.data;
    // Log de diagnostic pour le débogage
    // ignore: avoid_print
    print('[PasswordReset] error $status type=${error.type} body=$body');
    if (body is Map<String, dynamic>) {
      if (body.containsKey('errors') && body['errors'] is List) {
        final List<dynamic> errors = body['errors'] as List<dynamic>;
        if (errors.isNotEmpty) {
          final dynamic first = errors.first;
          if (first is Map<String, dynamic>) {
            return (first['msg'] as String?) ?? 'Requête invalide.';
          }
        }
      }
      return (body['error'] as String?) ??
          (body['message'] as String?) ??
          'Erreur serveur ($status).';
    }
    return 'Erreur inattendue. Réessayez.';
  }
}
