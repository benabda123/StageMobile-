import 'package:flutter_test/flutter_test.dart';
import 'package:keystone_mobile/features/profile/domain/profile_model.dart';

void main() {
  group('Profile.fromJson', () {
    test('parse les champs camelCase du backend', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{
        'id': 'e011445c-87aa-45f6-83b0-0022110ef52b',
        'username': 'youcef',
        'email': 'youcef@keystone.com',
        'firstName': 'Youcef',
        'lastName': 'Ben Abda',
        'avatarUrl': 'http://localhost:8000/auth/profile/uploads/a.png',
        'githubUrl': 'https://github.com/youcef',
        'linkedinUrl': 'https://linkedin.com/in/youcef',
      });

      expect(profile.username, 'youcef');
      expect(profile.email, 'youcef@keystone.com');
      expect(profile.firstName, 'Youcef');
      expect(profile.lastName, 'Ben Abda');
      expect(profile.avatarUrl, 'http://localhost:8000/auth/profile/uploads/a.png');
      expect(profile.githubUrl, 'https://github.com/youcef');
      expect(profile.linkedinUrl, 'https://linkedin.com/in/youcef');
      expect(profile.hasAvatar, isTrue);
    });

    test('normalise les URLs vides en null', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{
        'username': 'youcef',
        'avatarUrl': '',
        'githubUrl': '',
        'linkedinUrl': '',
      });

      expect(profile.avatarUrl, isNull);
      expect(profile.githubUrl, isNull);
      expect(profile.linkedinUrl, isNull);
      expect(profile.hasAvatar, isFalse);
    });
  });

  group('Profile.initials', () {
    test('prénom + nom', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{
        'username': 'youcef',
        'firstName': 'Youcef',
        'lastName': 'Ben Abda',
      });

      expect(profile.initials, 'YB');
    });

    test('fallback sur le username sans prénom/nom', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{
        'username': 'admin',
      });

      expect(profile.initials, 'A');
    });

    test('fallback sur U quand tout est vide', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{});

      expect(profile.initials, 'U');
    });
  });

  group('Profile.copyWith', () {
    test('remplace les liens et garde les autres champs', () {
      final Profile profile = Profile.fromJson(const <String, dynamic>{
        'username': 'youcef',
        'firstName': 'Youcef',
        'lastName': 'Ben Abda',
        'avatarUrl': 'http://localhost:8000/auth/profile/uploads/a.png',
      });

      final Profile updated = profile.copyWith(
        githubUrl: 'https://github.com/youcef',
        linkedinUrl: 'https://linkedin.com/in/youcef',
      );

      expect(updated.username, 'youcef');
      expect(updated.avatarUrl, profile.avatarUrl);
      expect(updated.githubUrl, 'https://github.com/youcef');
      expect(updated.linkedinUrl, 'https://linkedin.com/in/youcef');
    });
  });
}
