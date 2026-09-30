import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../data/meeting_repository.dart';
import '../domain/meeting_model.dart';
import '../domain/room_model.dart';
import 'meeting_ui.dart';
import 'meetings_provider.dart';

/// Toutes les réunions (`GET /meetings`), filtrables par statut, avec
/// validation : Accepter / Refuser pour les PENDING, et résolution de la
/// demande de changement (Accepter / Refuser le changement) pour les
/// CHANGE_REQUEST_PENDING — réservé admin / manager.
class ManagerMeetingRequestsScreen extends ConsumerWidget {
  const ManagerMeetingRequestsScreen({super.key});

  static const List<String?> _statusFilters = <String?>[
    null,
    MeetingStatus.pending,
    MeetingStatus.changeRequestPending,
    MeetingStatus.confirmed,
    MeetingStatus.rejected,
    MeetingStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Meeting>> meetings = ref.watch(allMeetingsProvider);
    final String? selectedStatus = ref.watch(_meetingFilterProvider);
    final Map<String, MeetingRoom> roomsById = <String, MeetingRoom>{
      for (final MeetingRoom room
          in ref.watch(roomsProvider).valueOrNull ?? const <MeetingRoom>[])
        room.id: room,
    };

    final List<Meeting> filtered = meetings.valueOrNull == null
        ? const <Meeting>[]
        : (meetings.valueOrNull!
            .where((Meeting m) =>
                selectedStatus == null || m.status == selectedStatus)
            .toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de réunion'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/meetings/new'),
        tooltip: 'Créer une réunion',
        child: const Icon(Icons.add),
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
                      label: Text(
                        status == null ? 'Tous' : meetingStatusLabel(status),
                      ),
                      selected: selectedStatus == status,
                      onSelected: (_) => ref
                          .read(_meetingFilterProvider.notifier)
                          .state = status,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: meetings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => ErrorStateWidget(
                message: ErrorStateWidget.humanMessage(error),
                onRetry: () => ref.invalidate(allMeetingsProvider),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return ListView(
                    children: const <Widget>[
                      SizedBox(height: 48),
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Aucune réunion.', textAlign: TextAlign.center),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(allMeetingsProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Meeting meeting = filtered[index];
                      return _MeetingTile(
                        meeting: meeting,
                        location: meetingLocation(meeting, roomsById),
                        onApprove: () => _decide(
                          ref,
                          context,
                          meeting.id,
                          approve: true,
                        ),
                        onReject: () => _decide(
                          ref,
                          context,
                          meeting.id,
                          approve: false,
                        ),
                        onResolveChange: (bool accept) => _resolveChange(
                          ref,
                          context,
                          meeting.id,
                          accept: accept,
                        ),
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

  Future<void> _decide(
    WidgetRef ref,
    BuildContext context,
    String meetingId, {
    required bool approve,
  }) async {
    try {
      if (approve) {
        await ref.read(meetingRepositoryProvider).approveMeeting(meetingId);
      } else {
        await ref.read(meetingRepositoryProvider).rejectMeeting(meetingId);
      }
      ref.invalidate(allMeetingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Réunion approuvée.' : 'Réunion refusée.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _resolveChange(
    WidgetRef ref,
    BuildContext context,
    String meetingId, {
    required bool accept,
  }) async {
    try {
      await ref
          .read(meetingRepositoryProvider)
          .resolveMeetingChange(meetingId, accept: accept);
      ref.invalidate(allMeetingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Changement accepté.'
                  : 'Changement refusé, horaires conservés.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }
}

/// Ligne d'une réunion avec actions selon le statut.
class _MeetingTile extends StatelessWidget {
  const _MeetingTile({
    required this.meeting,
    required this.location,
    required this.onApprove,
    required this.onReject,
    required this.onResolveChange,
  });

  final Meeting meeting;
  final String location;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<bool> onResolveChange;

  @override
  Widget build(BuildContext context) {
    final MeetingChangeRequest? change = meeting.changeRequestData;
    final bool isPending = meeting.status == MeetingStatus.pending;
    final bool isChangePending =
        meeting.status == MeetingStatus.changeRequestPending;

    final StringBuffer subtitle = StringBuffer(
      '${meeting.createdByUsername ?? '—'} · '
      '${formatMeetingDate(meeting.date)} · '
      '${formatMeetingTime(meeting.startTime)}–'
      '${formatMeetingTime(meeting.endTime)}\n$location',
    );
    if (change != null) {
      subtitle.write(
        '\nChangement demandé : '
        '${formatMeetingDate(change.proposedDate)} · '
        '${formatMeetingTime(change.proposedStartTime)}–'
        '${formatMeetingTime(change.proposedEndTime)}'
        '${change.reason == null || change.reason!.isEmpty ? '' : ' — ${change.reason}'}',
      );
    }

    return ListTile(
      leading: Icon(
        meetingTypeIcon(meeting.type),
        color: meetingStatusColor(meeting.status),
      ),
      title: Text(meeting.title),
      subtitle: Text(
        subtitle.toString(),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isPending || isChangePending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: isChangePending ? 'Accepter le changement' : 'Accepter',
                  onPressed: isChangePending
                      ? () => onResolveChange(true)
                      : onApprove,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: isChangePending ? 'Refuser le changement' : 'Refuser',
                  onPressed: isChangePending
                      ? () => onResolveChange(false)
                      : onReject,
                ),
              ],
            )
          : MeetingStatusBadge(status: meeting.status),
    );
  }
}

/// Filtre de statut sélectionné dans la liste manager.
final _meetingFilterProvider = StateProvider<String?>((_) => null);
