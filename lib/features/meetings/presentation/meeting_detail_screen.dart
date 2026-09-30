import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../data/meeting_repository.dart';
import '../domain/meeting_model.dart';
import '../domain/room_model.dart';
import 'meeting_ui.dart';
import 'meetings_provider.dart';

/// Détail d'une réunion. Si l'utilisateur est le créateur et que la réunion
/// est confirmée : boutons « Demander un changement » (formulaire inline) et
/// « Annuler » (avec raison). Un changement en attente est affiché.
class MeetingDetailScreen extends ConsumerStatefulWidget {
  const MeetingDetailScreen({super.key, required this.meeting});

  /// Réunion passée via `extra` (le backend n'expose pas `GET /meetings/:id`).
  final Meeting meeting;

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  late Meeting _meeting = widget.meeting;

  bool _busy = false;
  bool _changeFormVisible = false;

  DateTime? _newDate;
  TimeOfDay? _newStart;
  TimeOfDay? _newEnd;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isCreator {
    final String? me = ref.watch(currentUsernameProvider);
    return me != null && me == _meeting.createdByUsername;
  }

  void _refreshAll() {
    ref.invalidate(myMeetingsProvider);
    ref.invalidate(allMeetingsProvider);
  }

  Future<void> _run(
    Future<Meeting> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    try {
      final Meeting updated = await action();
      if (mounted) {
        setState(() {
          _meeting = updated;
          _changeFormVisible = false;
        });
        _refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openChangeForm() {
    final String? startOnly = meetingTimeOnly(_meeting.startTime);
    final String? endOnly = meetingTimeOnly(_meeting.endTime);
    _newDate = DateTime.tryParse(meetingDateOnly(_meeting.date) ?? '');
    _newStart = startOnly == null ? null : _timeFromHm(startOnly);
    _newEnd = endOnly == null ? null : _timeFromHm(endOnly);
    _reasonController.clear();
    setState(() => _changeFormVisible = true);
  }

  TimeOfDay? _timeFromHm(String hm) {
    final List<String> parts = hm.split(':');
    if (parts.length < 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _requestChange() async {
    final DateTime? date = _newDate;
    final TimeOfDay? start = _newStart;
    final TimeOfDay? end = _newEnd;
    final String reason = _reasonController.text.trim();
    if (date == null || start == null || end == null) {
      _showSnack('Renseignez la nouvelle date et les nouveaux horaires.');
      return;
    }
    final int startMin = start.hour * 60 + start.minute;
    final int endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) {
      _showSnack('L\'heure de fin doit être après l\'heure de début.');
      return;
    }
    if (reason.isEmpty) {
      _showSnack('Précisez une raison pour le changement.');
      return;
    }
    await _run(
      () => ref.read(meetingRepositoryProvider).requestMeetingChange(
            _meeting.id,
            date: _toApiDate(date),
            startTime: _toApiTime(start),
            endTime: _toApiTime(end),
            reason: reason,
          ),
      'Demande de changement envoyée.',
    );
  }

  Future<void> _cancel() async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Annuler la réunion'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Raison',
              hintText: 'Pourquoi annuler cette réunion ?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Retour'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim(),
              ),
              child: const Text('Annuler la réunion'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) {
      return;
    }
    await _run(
      () => ref
          .read(meetingRepositoryProvider)
          .cancelMeeting(_meeting.id, reason: reason),
      'Réunion annulée.',
    );
  }

  String _toApiDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _toApiTime(TimeOfDay time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, MeetingRoom> roomsById = <String, MeetingRoom>{
      for (final MeetingRoom room
          in ref.watch(roomsProvider).valueOrNull ?? const <MeetingRoom>[])
        room.id: room,
    };
    final MeetingChangeRequest? change = _meeting.changeRequestData;

    return Scaffold(
      appBar: AppBar(title: const Text('Réunion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            _meeting.title,
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
                label: Text(meetingStatusLabel(_meeting.status)),
                backgroundColor:
                    meetingStatusColor(_meeting.status).withValues(alpha: 0.15),
                labelStyle:
                    TextStyle(color: meetingStatusColor(_meeting.status)),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(meetingTypeLabel(_meeting.type)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formatMeetingDate(_meeting.date),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.access_time,
            label: 'Horaires',
            value: '${formatMeetingTime(_meeting.startTime)}–'
                '${formatMeetingTime(_meeting.endTime)}',
          ),
          const SizedBox(height: 12),
          _Section(
            icon: meetingTypeIcon(_meeting.type),
            label: 'Lieu',
            value: _meeting.type == MeetingType.online
                ? (_meeting.meetingLink?.trim().isEmpty ?? true
                    ? 'En ligne'
                    : _meeting.meetingLink!)
                : meetingLocation(_meeting, roomsById),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.people_outline,
            label: 'Participants',
            value: _meeting.participants.isEmpty
                ? 'Aucun'
                : _meeting.participants.join(', '),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.person_outline,
            label: 'Créée par',
            value: _meeting.createdByUsername ?? '—',
          ),
          if (_meeting.description != null &&
              _meeting.description!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _Section(
              icon: Icons.description_outlined,
              label: 'Description',
              value: _meeting.description!,
            ),
          ],
          if (_meeting.cancellationReason != null &&
              _meeting.cancellationReason!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _Section(
              icon: Icons.cancel_outlined,
              label: 'Raison d\'annulation',
              value: _meeting.cancellationReason!,
            ),
          ],
          if (change != null) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Demande de changement en cours',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            _Section(
              icon: Icons.update,
              label: 'Nouvelle date / horaires',
              value: '${formatMeetingDate(change.proposedDate)} · '
                  '${formatMeetingTime(change.proposedStartTime)}–'
                  '${formatMeetingTime(change.proposedEndTime)}',
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.chat_outlined,
              label: 'Raison',
              value: change.reason ?? '—',
            ),
          ],
          if (_changeFormVisible) ...<Widget>[
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Demander un changement',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text('Nouvelle date'),
                    subtitle: Text(
                      _newDate == null ? 'Sélectionner' : formatMeetingDate(_toApiDate(_newDate!)),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _busy
                        ? null
                        : () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _newDate ?? DateTime.tryParse(meetingDateOnly(_meeting.date) ?? '') ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                  const Duration(days: 365)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setState(() => _newDate = picked);
                            }
                          },
                  ),
                  ListTile(
                    title: const Text('Nouvelle heure de début'),
                    subtitle: Text(
                      _newStart == null ? 'Sélectionner' : _toApiTime(_newStart!),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _busy
                        ? null
                        : () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _newStart ??
                                  const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _newStart = picked);
                            }
                          },
                  ),
                  ListTile(
                    title: const Text('Nouvelle heure de fin'),
                    subtitle: Text(
                      _newEnd == null ? 'Sélectionner' : _toApiTime(_newEnd!),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _busy
                        ? null
                        : () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _newEnd ??
                                  const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _newEnd = picked);
                            }
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Raison',
                        hintText: 'Pourquoi demander ce changement ?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _requestChange,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer la demande de changement'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _actionArea(),
        ),
      ),
    );
  }

  /// Actions : pour le créateur d'une réunion confirmée, demander un
  /// changement et annuler (sinon null → aucune barre d'action).
  Widget? _actionArea() {
    if (!_isCreator || _meeting.status != MeetingStatus.confirmed) {
      return null;
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : _openChangeForm,
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Demander un changement'),
          ),
        ),
      ],
    );
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
