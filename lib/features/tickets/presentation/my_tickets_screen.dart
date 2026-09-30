import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/ticket_model.dart';
import 'ticket_ui.dart';
import 'tickets_provider.dart';

/// Mes tickets — liste en cartes glass.
class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Ticket>> tickets = ref.watch(myTicketsProvider);
    final Widget body = _buildBody(context, ref, tickets);

    if (embedded) {
      return Stack(
        children: <Widget>[
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: GlassTokens.submitBlue,
              onPressed: () => context.push('/tickets/new'),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Support',
          style: TextStyle(color: GlassTokens.textPrimary, fontSize: 18),
        ),
        showLogo: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: GlassTokens.textSecondary),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GlassTokens.submitBlue,
        onPressed: () => context.push('/tickets/new'),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Ticket>> tickets,
  ) {
    return RefreshIndicator(
      color: GlassTokens.accentBorder,
      onRefresh: () => ref.refresh(myTicketsProvider.future),
      child: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => ListView(
          children: <Widget>[
            GlassEmptyState(
              message: 'Impossible de charger vos tickets',
              subtitle: '$error',
              icon: Icons.error_outline,
            ),
          ],
        ),
        data: (List<Ticket> items) {
          if (items.isEmpty) {
            return ListView(
              children: const <Widget>[
                SizedBox(height: 48),
                GlassEmptyState(
                  message: 'Aucun ticket',
                  subtitle: 'Créez un ticket support',
                  icon: Icons.confirmation_num_outlined,
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: <Widget>[
              const Text(
                'Mes tickets',
                style: TextStyle(
                  color: GlassTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (Ticket ticket) => GlassListCard(
                  icon: Icons.confirmation_num_outlined,
                  title: ticket.title,
                  subtitle:
                      '${ticketCategoryLabel(ticket.category)} · '
                      '${ticketPriorityLabel(ticket.priority)}',
                  badge: GlassStatusBadge(
                    label: ticketStatusLabel(ticket.status),
                    color: ticketStatusColor(ticket.status),
                  ),
                  footer: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/tickets/${ticket.id}'),
                      child: const Text('Détails'),
                    ),
                  ),
                  onTap: () => context.push('/tickets/${ticket.id}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
