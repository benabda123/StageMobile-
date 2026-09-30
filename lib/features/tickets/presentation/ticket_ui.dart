import 'package:flutter/material.dart';

Color ticketStatusColor(String status) {
  switch (status) {
    case 'OPEN':
      return Colors.grey;
    case 'ASSIGNED':
      return Colors.blue;
    case 'IN_PROGRESS':
      return Colors.orange;
    case 'RESOLVED':
      return Colors.green;
    case 'CLOSED':
      return Colors.blueGrey;
    default:
      return Colors.grey;
  }
}

String ticketStatusLabel(String status) {
  switch (status) {
    case 'OPEN':
      return 'Ouvert';
    case 'ASSIGNED':
      return 'Assigné';
    case 'IN_PROGRESS':
      return 'En cours';
    case 'RESOLVED':
      return 'Résolu';
    case 'CLOSED':
      return 'Fermé';
    default:
      return status;
  }
}

Color ticketPriorityColor(String priority) {
  switch (priority) {
    case 'LOW':
      return Colors.green;
    case 'MEDIUM':
      return Colors.orange;
    case 'HIGH':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

String ticketPriorityLabel(String priority) {
  switch (priority) {
    case 'LOW':
      return 'Basse';
    case 'MEDIUM':
      return 'Moyenne';
    case 'HIGH':
      return 'Haute';
    default:
      return priority;
  }
}

String ticketCategoryLabel(String category) {
  switch (category) {
    case 'HARDWARE':
      return 'Matériel';
    case 'SOFTWARE':
      return 'Logiciel';
    case 'NETWORK':
      return 'Réseau';
    case 'ACCESS_REQUEST':
      return 'Accès';
    case 'SECURITY':
      return 'Sécurité';
    default:
      return category;
  }
}
