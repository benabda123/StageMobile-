import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/ticket_model.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(dioProvider));
});

class TicketRepository {
  TicketRepository(this._dio);

  final Dio _dio;

  /// Mes tickets (`GET /tickets/mine`).
  Future<List<Ticket>> getMyTickets() async {
    final Response<dynamic> response = await _dio.get('/tickets/mine');
    return _parseList(response.data);
  }

  /// Tous les tickets, filtrable côté serveur par statut
  /// (`GET /tickets?status=...`), réservé admin / itsupport.
  Future<List<Ticket>> getAllTickets({String? status}) async {
    final Response<dynamic> response = await _dio.get(
      '/tickets',
      queryParameters: status == null ? null : <String, dynamic>{'status': status},
    );
    return _parseList(response.data);
  }

  /// Détails d'un ticket + commentaires (`GET /tickets/:id`).
  Future<TicketDetails> getTicketDetails(String ticketId) async {
    final Response<dynamic> response = await _dio.get('/tickets/$ticketId');
    final dynamic data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Réponse inattendue du serveur.');
    }
    final List<TicketComment> comments = <TicketComment>[];
    final dynamic rawComments = data['comments'];
    if (rawComments is List) {
      comments.addAll(
        rawComments
            .whereType<Map<String, dynamic>>()
            .map(TicketComment.fromJson),
      );
    }
    return TicketDetails(
      ticket: Ticket.fromJson(data),
      comments: comments,
    );
  }

  /// Crée un ticket (`POST /tickets`).
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
  }) async {
    final Response<dynamic> response = await _dio.post(
      '/tickets',
      data: <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
      },
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return Ticket.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  /// S'assigne un ticket (`PUT /tickets/:id/assign`), admin / itsupport.
  Future<Ticket> assignTicket(String ticketId) async {
    final Response<dynamic> response =
        await _dio.put('/tickets/$ticketId/assign');
    return _parseTicket(response.data);
  }

  /// Change le statut (`PUT /tickets/:id/status`), admin / itsupport.
  Future<Ticket> updateTicketStatus(String ticketId, String status) async {
    final Response<dynamic> response = await _dio.put(
      '/tickets/$ticketId/status',
      data: <String, dynamic>{'status': status},
    );
    return _parseTicket(response.data);
  }

  /// Ferme le ticket (`PUT /tickets/:id/close`), créateur si RESOLVED.
  Future<Ticket> closeTicket(String ticketId) async {
    final Response<dynamic> response = await _dio.put('/tickets/$ticketId/close');
    return _parseTicket(response.data);
  }

  /// Ajoute un commentaire (`POST /tickets/:id/comments`).
  Future<TicketComment> addComment(String ticketId, String message) async {
    final Response<dynamic> response = await _dio.post(
      '/tickets/$ticketId/comments',
      data: <String, dynamic>{'message': message},
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      return TicketComment.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  Ticket _parseTicket(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Ticket.fromJson(data);
    }
    throw StateError('Réponse inattendue du serveur.');
  }

  List<Ticket> _parseList(dynamic data) {
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['tickets'] is List) {
      list = data['tickets'] as List;
    } else {
      return const <Ticket>[];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Ticket.fromJson)
        .toList();
  }
}
