import 'package:flutter/material.dart';

/// Module métier de l'application : identifiant de route, libellé et icône.
class Module {
  const Module({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Registre des modules applicatifs. Un module encore non développé en
/// Flutter est affiché via `ModulePlaceholderScreen` (« Bientôt disponible »).
class ModuleCatalog {
  ModuleCatalog._();

  static const Map<String, Module> modules = <String, Module>{
    'employees':
        Module(id: 'employees', label: 'Employés', icon: Icons.people_outline),
    'departments': Module(
        id: 'departments', label: 'Départements', icon: Icons.apartment_outlined),
    'tasks': Module(id: 'tasks', label: 'Tâches', icon: Icons.task_alt),
    'leaves': Module(
        id: 'leaves', label: 'Congés', icon: Icons.beach_access_outlined),
    'meetings': Module(
        id: 'meetings', label: 'Réunions', icon: Icons.event_outlined),
    'rooms': Module(
        id: 'rooms', label: 'Salles', icon: Icons.meeting_room_outlined),
    'notifications': Module(
        id: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_outlined),
    'announcements': Module(
        id: 'announcements', label: 'Annonces', icon: Icons.campaign_outlined),
    'tickets': Module(id: 'tickets', label: 'Tickets', icon: Icons.support_agent),
    'learning': Module(
        id: 'learning', label: 'Learning', icon: Icons.school_outlined),
    'profile':
        Module(id: 'profile', label: 'Profil', icon: Icons.person_outline),
  };

  static Module? byId(String id) => modules[id];
}
