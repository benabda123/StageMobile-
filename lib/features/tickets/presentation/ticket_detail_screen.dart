import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/user_role.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';
import 'ticket_ui.dart';
import 'tickets_provider.dart';

/// Détail d'un ticket + commentaires. Actions selon le rôle :
///   - employee créateur : commenter, fermer si RESOLVED ;
///   - itsupport / admin : commenter, s'assigner, changer le statut.
class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(ticketDetailsProvider(widget.ticketId));
    ref.invalidate(myTicketsProvider);
    ref.invalidate(allTicketsProvider);
  }

  Future<void> _run(Future<Object?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _refreshAll();
    } catch (e) {
      setState(() => _error = 'Échec de l\'opération.\n$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendComment() async {
    final String message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }
    _commentController.clear();
    await _run(
      () => ref
          .read(ticketRepositoryProvider)
          .addComment(widget.ticketId, message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TicketDetails> details =
        ref.watch(ticketDetailsProvider(widget.ticketId));
    final Widget? actionsArea = details.valueOrNull == null
        ? null
        : _actionArea(details.valueOrNull!.ticket);

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => ListView(
          children: <Widget>[
            const SizedBox(height: 48),
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Impossible de charger le ticket.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        data: (TicketDetails details) {
          final Ticket ticket = details.ticket;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                ticket.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    label: Text(ticketStatusLabel(ticket.status)),
                    backgroundColor:
                        ticketStatusColor(ticket.status).withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: ticketStatusColor(ticket.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(ticketCategoryLabel(ticket.category)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label:
                        Text('Priorité ${ticketPriorityLabel(ticket.priority)}'),
                    backgroundColor:
                        ticketPriorityColor(ticket.priority).withValues(alpha: 0.15),
                    labelStyle:
                        TextStyle(color: ticketPriorityColor(ticket.priority)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              _Section(
                icon: Icons.description_outlined,
                label: 'Description',
                value: (ticket.description == null ||
                        ticket.description!.isEmpty)
                    ? '—'
                    : ticket.description!,
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.person_outline,
                label: 'Créé par',
                value: ticket.employeeUsername ?? '—',
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.support_agent,
                label: 'Assigné à',
                value: ticket.assignedToUsername ?? 'Non assigné',
              ),
              const SizedBox(height: 12),
              _Section(
                icon: Icons.schedule,
                label: 'Créé le',
                value: _formatDate(ticket.createdAt),
              ),
              const SizedBox(height: 24),
              Text(
                'Commentaires (${details.comments.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (details.comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucun commentaire.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                for (final TicketComment comment in details.comments)
                  _CommentTile(comment: comment),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (actionsArea != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: actionsArea,
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _sendComment,
                    icon: const Icon(Icons.send),
                    tooltip: 'Envoyer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zone d'actions selon le rôle et l'état du ticket (ou null).
  Widget? _actionArea(Ticket ticket) {
    final UserRole role = ref.watch(userRoleProvider) ?? UserRole.employee;
    final String? me = ref.watch(currentUsernameProvider);
    final bool isSupport =
        role == UserRole.itsupport || role == UserRole.admin;
    final bool isCreator = me != null && me == ticket.employeeUsername;

    final List<Widget> actions = <Widget>[];

    if (isSupport) {
      if (!ticket.isAssigned && ticket.status != TicketStatus.closed) {
        actions.add(
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => ref
                            .read(ticketRepositoryProvider)
                            .assignTicket(ticket.id),
                      ),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('S\'assigner'),
            ),
          ),
        );
        actions.add(const SizedBox(width: 8));
      }
      if (ticket.status != TicketStatus.closed) {
        actions.add(
          Expanded(
            child: _StatusDropdown(
              value: ticket.status,
              enabled: !_busy,
              onChanged: (String status) => _run(
                () => ref
                    .read(ticketRepositoryProvider)
                    .updateTicketStatus(ticket.id, status),
              ),
            ),
          ),
        );
      }
    }

    if (isCreator && ticket.status == TicketStatus.resolved) {
      actions.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref
                          .read(ticketRepositoryProvider)
                          .closeTicket(ticket.id),
                    ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmer la résolution'),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return null;
    }
    return Row(children: actions);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final DateTime local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: <DropdownMenuItem<String>>[
        for (final String status in TicketStatus.values)
          DropdownMenuItem<String>(
            value: status,
            child: Text(ticketStatusLabel(status)),
          ),
      ],
      onChanged: enabled
          ? (String? v) {
              if (v != null && v != value) {
                onChanged(v);
              }
            }
          : null,
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final TicketComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            child: Text(
              (comment.authorUsername ?? '?')
                  .isEmpty
                  ? '?'
                  : comment.authorUsername!.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        comment.authorUsername ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _formatCommentDate(comment.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.message ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final DateTime local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
