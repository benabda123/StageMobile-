import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';

/// Mes tickets (`GET /tickets/mine`).
final myTicketsProvider = FutureProvider<List<Ticket>>((ref) {
  return ref.watch(ticketRepositoryProvider).getMyTickets();
});

/// Tous les tickets (`GET /tickets`), réservé admin / itsupport.
final allTicketsProvider = FutureProvider<List<Ticket>>((ref) {
  return ref.watch(ticketRepositoryProvider).getAllTickets();
});

/// Détails d'un ticket + commentaires (`GET /tickets/:id`).
final ticketDetailsProvider =
    FutureProvider.family<TicketDetails, String>((ref, ticketId) {
  return ref.watch(ticketRepositoryProvider).getTicketDetails(ticketId);
});
