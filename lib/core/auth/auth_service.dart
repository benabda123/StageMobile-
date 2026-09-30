import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String idToken;
  final DateTime expiresAt;
}

/// Authentification native : appelle directement le token endpoint Keycloak
/// (grant_type=password / refresh_token), sans navigateur externe.
class AuthService {
  AuthService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.keycloakUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ),
        _storage = storage ?? const FlutterSecureStorage();

  /// Dio dédié (SANS interceptor JWT) pour les appels au token endpoint.
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _idTokenKey = 'auth.id_token';
  static const String _expiresAtKey = 'auth.expires_at';

  static const Duration _expirySafetyMargin = Duration(seconds: 30);

  /// Refresh en cours — les appels concurrents à [getValidToken] attendent
  /// le même Future au lieu de lancer plusieurs refresh Keycloak en parallèle.
  Future<String>? _refreshInFlight;

  String get _tokenPath =>
      '/realms/${AppConfig.keycloakRealm}/protocol/openid-connect/token';

  Future<AuthSession?> getSession() async {
    final String? accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final String? refreshToken = await _storage.read(key: _refreshTokenKey);
    final String? idToken = await _storage.read(key: _idTokenKey);
    final String? expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final DateTime expiresAt =
        expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      idToken: idToken ?? '',
      expiresAt: expiresAt,
    );
  }

  Future<bool> isAuthenticated() async {
    return (await getSession()) != null;
  }

  /// Connexion username/password via le Direct Access Grant Keycloak.
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _tokenPath,
        data: <String, dynamic>{
          'grant_type': 'password',
          'client_id': AppConfig.keycloakClientId,
          'username': username,
          'password': password,
          'scope': AppConfig.keycloakScopes.join(' '),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final AuthSession session = _sessionFromTokenJson(
        response.data as Map<String, dynamic>,
      );
      await _persist(session);
      return session;
    } on DioException catch (error) {
      throw _dioErrorToAuth(error, login: true);
    }
  }

  /// Retourne un access token utilisable. Attend un refresh déjà en cours
  /// plutôt que d'en lancer un second en parallèle.
  ///
  /// [forceRefresh] : ignore la marge d'expiration locale et force un
  /// refresh Keycloak (utilisé par le retry automatique sur 401).
  Future<String> getValidToken({bool forceRefresh = false}) async {
    final AuthSession? session = await getSession();
    if (session == null) {
      _logTokenState('null', session: null, forceRefresh: forceRefresh);
      throw const AuthException('Utilisateur non authentifié.');
    }

    final Duration timeToExpiry = session.expiresAt.difference(DateTime.now());
    final bool needsRefresh =
        forceRefresh || timeToExpiry <= _expirySafetyMargin;

    if (!needsRefresh) {
      _logTokenState('valid', session: session, forceRefresh: forceRefresh);
      return session.accessToken;
    }

    _logTokenState(
      forceRefresh ? 'force-refresh' : 'expired',
      session: session,
      forceRefresh: forceRefresh,
    );

    if (_refreshInFlight != null) {
      _logTokenState(
        'awaiting-in-flight-refresh',
        session: session,
        forceRefresh: forceRefresh,
      );
      return _refreshInFlight!;
    }

    _refreshInFlight = _performRefresh(session, forceRefresh: forceRefresh);
    try {
      return await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<String> _performRefresh(
    AuthSession session, {
    required bool forceRefresh,
  }) async {
    try {
      if (!forceRefresh) {
        // Un autre appelant a peut-être déjà terminé le refresh entre-temps.
        final AuthSession? current = await getSession();
        if (current != null &&
            current.expiresAt.difference(DateTime.now()) >
                _expirySafetyMargin) {
          _logTokenState('already-refreshed', session: current);
          return current.accessToken;
        }
        session = current ?? session;
      }

      _logTokenState('refresh-start', session: session);
      final AuthSession refreshed = await _refresh(session);
      _logTokenState('refresh-ok', session: refreshed);
      return refreshed.accessToken;
    } on AuthException {
      _logTokenState('refresh-failed', session: session);
      await clearSession();
      rethrow;
    }
  }

  /// Log temporaire de diagnostic (visible dans `flutter run`).
  void _logTokenState(
    String state, {
    AuthSession? session,
    bool forceRefresh = false,
  }) {
    if (!kDebugMode) {
      return;
    }
    final String now = DateTime.now().toIso8601String();
    if (session == null) {
      debugPrint('[AuthService] $now token=$state forceRefresh=$forceRefresh');
      return;
    }
    final Duration ttl = session.expiresAt.difference(DateTime.now());
    debugPrint(
      '[AuthService] $now token=$state '
      'ttl=${ttl.inSeconds}s forceRefresh=$forceRefresh',
    );
  }

  Future<void> logout() async {
    // La déconnexion est locale : plus de navigateur SSO, les tokens stockés
    // sont simplement supprimés (le refresh token expire côté Keycloak).
    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  Future<AuthSession> _refresh(AuthSession session) async {
    if (session.refreshToken.isEmpty) {
      throw const AuthException('Aucun refresh token disponible.');
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _tokenPath,
        data: <String, dynamic>{
          'grant_type': 'refresh_token',
          'client_id': AppConfig.keycloakClientId,
          'refresh_token': session.refreshToken,
          'scope': AppConfig.keycloakScopes.join(' '),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final AuthSession refreshed = _sessionFromTokenJson(
        response.data as Map<String, dynamic>,
        previous: session,
      );
      await _persist(refreshed);
      return refreshed;
    } on DioException catch (error) {
      throw _dioErrorToAuth(error, login: false);
    }
  }

  /// Traduit une erreur HTTP Keycloak en [AuthException] lisible.
  AuthException _dioErrorToAuth(DioException error, {required bool login}) {
    final int? status = error.response?.statusCode;
    final dynamic body = error.response?.data;
    final String errorCode = body is Map
        ? (body['error'] as String?) ?? ''
        : '';

    if (status == 400 || status == 401) {
      if (errorCode == 'invalid_grant' || errorCode == 'invalid_client') {
        return login
            ? const AuthException('Identifiants incorrects.')
            : const AuthException(
                'Session expirée. Veuillez vous reconnecter.',
              );
      }
      if (errorCode == 'invalid_request') {
        return const AuthException('Requête invalide. Réessayez.');
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const AuthException(
        'Serveur injoignable. Vérifiez la connexion et réessayez.',
      );
    }

    return login
        ? const AuthException('Échec de la connexion. Veuillez réessayer.')
        : const AuthException('Échec du renouvellement de session.');
  }

  AuthSession _sessionFromTokenJson(
    Map<String, dynamic> json, {
    AuthSession? previous,
  }) {
    final String? accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('Aucun token reçu du serveur.');
    }

    final int expiresIn = (json['expires_in'] as num?)?.toInt() ?? 300;
    return AuthSession(
      accessToken: accessToken,
      refreshToken: (json['refresh_token'] as String?) ??
          previous?.refreshToken ??
          '',
      idToken: (json['id_token'] as String?) ?? previous?.idToken ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _idTokenKey, value: session.idToken);
    await _storage.write(
      key: _expiresAtKey,
      value: session.expiresAt.toIso8601String(),
    );
  }
}
