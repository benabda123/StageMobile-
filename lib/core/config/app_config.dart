// ============================================================================
// Configuration des services backend (Keycloak + API via Kong).
// ----------------------------------------------------------------------------
// La valeur "_host" désigne la machine qui héberge les services.
//
// IMPORTANT — Développement sur émulateur Android :
//   On garde ici "localhost" pour que Keycloak continue de générer des URLs
//   http://localhost:8085 (issuer, endpoints, page de login HTML). Ces URLs
//   sont compatibles avec la validation JWT de Kong (issuer configuré sur
//   http://localhost:8085/realms/keystone) et avec le frontend web existant.
//   Le port 8085 étant le "localhost" de l'appareil, il faut y tunneliser les
//   ports de la machine hôte AVANT de lancer l'app sur un émulateur :
//
//     adb reverse tcp:8085 tcp:8085
//     adb reverse tcp:8000 tcp:8000
//
//   (ou exécuter le script scripts/setup_emulator.ps1 qui fait les deux puis
//   lance `flutter run`). Le tunnel ne survit ni au redémarrage de
//   l'émulateur, ni au redémarrage du serveur adb : à relancer à chaque fois.
//   Pour vérifier qu'il est actif : `adb reverse --list`.
//
//   Téléphone physique : remplacer "_host" par l'IP LAN du PC
//   (ex. 10.100.1.139, même Wi-Fi que le téléphone).
//   Production         : <URL réelle du serveur> (https).
// ============================================================================
const String _host = 'localhost'; // <-- changer ici selon l'environnement de test

class AppConfig {
  AppConfig._();

  // Keycloak : client public pour le Direct Access Grant (grant_type=password).
  static const String keycloakUrl = 'http://$_host:8085';
  static const String keycloakRealm = 'keystone';
  static const String keycloakClientId = 'keystone-mobile';

  static const List<String> keycloakScopes = <String>[
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  // API backend derrière Kong Gateway.
  static const String apiBaseUrl = 'http://$_host:8000';
}
