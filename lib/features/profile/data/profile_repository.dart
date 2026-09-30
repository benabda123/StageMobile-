import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/dio_client.dart';
import '../domain/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  /// Profil de l'utilisateur connecté (`GET /auth/profile/me`).
  Future<Profile> getMyProfile() async {
    final Response<dynamic> response = await _dio.get('/auth/profile/me');
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return Profile.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  /// Met à jour les liens GitHub / LinkedIn (`PUT /auth/profile/me`).
  Future<Profile> updateLinks({
    required String githubUrl,
    required String linkedinUrl,
  }) async {
    final Response<dynamic> response = await _dio.put(
      '/auth/profile/me',
      data: <String, dynamic>{
        'githubUrl': githubUrl.trim(),
        'linkedinUrl': linkedinUrl.trim(),
      },
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return Profile.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  /// Upload d'une photo de profil (`POST /auth/profile/me/avatar`,
  /// multipart, champ `avatar`). Retourne la nouvelle `avatarUrl`.
  Future<String> uploadAvatar(XFile file) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'avatar': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: _mediaTypeFor(file),
      ),
    });
    final Response<dynamic> response =
        await _dio.post('/auth/profile/me/avatar', data: formData);
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      final String? avatarUrl = data['avatarUrl']?.toString();
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        return avatarUrl.trim();
      }
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  /// Détermine le content-type du fichier : MIME annoncé par l'image_picker,
  /// sinon déduit de l'extension. Le backend n'accepte que jpeg/png/webp.
  static MediaType _mediaTypeFor(XFile file) {
    final String? mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) {
      return MediaType.parse(mime);
    }
    final String name = file.name.toLowerCase();
    if (name.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (name.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
