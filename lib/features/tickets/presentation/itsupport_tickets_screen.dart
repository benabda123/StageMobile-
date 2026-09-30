import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../domain/ticket_model.dart';
import 'ticket_ui.dart';
import 'tickets_provider.dart';

/// Tous les tickets (`GET /tickets`), filtrables par statut — accessible
/// depuis l'accueil Support IT (et admin).
class ItSupportTicketsScreen extends ConsumerWidget {
  const ItSupportTicketsScreen({super.key});

  static const List<String?> _statusFilters = <String?>[
    null,
    TicketStatus.open,
    TicketStatus.assigned,
    TicketStatus.inProgress,
    TicketStatus.resolved,
    TicketStatus.closed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Ticket>> tickets = ref.watch(allTicketsProvider);
    final String? selectedStatus = ref.watch(_statusFilterProvider);

    final List<Ticket> filtered = tickets.valueOrNull == null
        ? const <Ticket>[]
        : (tickets.valueOrNull!
            .where((Ticket t) =>
                selectedStatus == null || t.status == selectedStatus)
            .toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                for (final String? status in _statusFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status == null ? 'Tous' : ticketStatusLabel(status)),
                      selected: selectedStatus == status,
                      onSelected: (_) =>
                          ref.read(_statusFilterProvider.notifier).state = status,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tickets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => ListView(
                children: <Widget>[
                  const SizedBox(height: 48),
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Impossible de charger les tickets.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return ListView(
                    children: const <Widget>[
                      SizedBox(height: 48),
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Aucun ticket.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(allTicketsProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Ticket ticket = filtered[index];
                      return ListTile(
                        leading: Icon(
                          Icons.confirmation_num_outlined,
                          color: ticketStatusColor(ticket.status),
                        ),
                        title: Text(ticket.title),
                        subtitle: Text(
                          '${ticket.employeeUsername ?? '—'} · '
                          '${ticketStatusLabel(ticket.status)} · '
                          '${ticketPriorityLabel(ticket.priority)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/tickets/${ticket.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtre de statut sélectionné dans la liste Support IT.
final _statusFilterProvider =
    StateProvider<String?>((_) => null);
