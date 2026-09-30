import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/meeting_repository.dart';
import '../domain/meeting_model.dart';
import '../domain/room_model.dart';
import 'meeting_ui.dart';
import 'meetings_provider.dart';

/// Création d'une réunion (`POST /meetings`). En cas d'erreur 400 du backend
/// (ex. conflit horaire sur une salle), le message exact est affiché dans une
/// SnackBar rouge — pas une erreur générique.
class NewMeetingScreen extends ConsumerStatefulWidget {
  const NewMeetingScreen({
    super.key,
    this.presetTitle,
    this.presetDescription,
    this.presetParticipants,
    this.presetDurationMinutes,
  });

  final String? presetTitle;
  final String? presetDescription;
  final String? presetParticipants;
  final int? presetDurationMinutes;

  @override
  ConsumerState<NewMeetingScreen> createState() => _NewMeetingScreenState();
}

class _NewMeetingScreenState extends ConsumerState<NewMeetingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();

  String _type = MeetingType.presentiel;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _roomId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.presetTitle != null) {
      _titleController.text = widget.presetTitle!;
    }
    if (widget.presetDescription != null) {
      _descriptionController.text = widget.presetDescription!;
    }
    if (widget.presetParticipants != null) {
      _participantsController.text = widget.presetParticipants!;
    }
    if (widget.presetDurationMinutes != null && widget.presetDurationMinutes! > 0) {
      _date = DateTime.now();
      _start = const TimeOfDay(hour: 9, minute: 0);
      final int totalMin = 9 * 60 + widget.presetDurationMinutes!;
      _end = TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  Future<void> _pickEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _end ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _end = picked);
    }
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

  List<String> _parseParticipants(String raw) {
    return raw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final DateTime? date = _date;
    final TimeOfDay? start = _start;
    final TimeOfDay? end = _end;
    if (date == null || start == null || end == null) {
      _showSnack('Renseignez la date et les horaires.');
      return;
    }
    final int startMin = start.hour * 60 + start.minute;
    final int endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) {
      _showSnack('L\'heure de fin doit être après l\'heure de début.');
      return;
    }
    if (_type == MeetingType.presentiel &&
        (_roomId == null || _roomId!.isEmpty)) {
      _showSnack('Sélectionnez une salle.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(meetingRepositoryProvider).createMeeting(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            date: _toApiDate(date),
            startTime: _toApiTime(start),
            endTime: _toApiTime(end),
            type: _type,
            roomId: _type == MeetingType.presentiel ? _roomId : null,
            meetingLink: _type == MeetingType.online
                ? _linkController.text.trim()
                : null,
            participants: _parseParticipants(_participantsController.text),
          );
      ref.invalidate(myMeetingsProvider);
      ref.invalidate(allMeetingsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        _showSnack(apiErrorMessage(e), error: true);
      }
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MeetingRoom>> rooms = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réunion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Objet de la réunion',
              ),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Le titre est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: MeetingType.online,
                  label: Text('En ligne'),
                  icon: Icon(Icons.videocam_outlined),
                ),
                ButtonSegment<String>(
                  value: MeetingType.presentiel,
                  label: Text('Présentielle'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: <String>{_type},
              onSelectionChanged: (Set<String> selection) => setState(() {
                _type = selection.first;
                _roomId = null;
              }),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      _date == null ? 'Sélectionner' : formatMeetingDate(_toApiDate(_date!)),
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDate,
                  ),
                  ListTile(
                    title: const Text('Heure de début'),
                    subtitle: Text(
                      _start == null ? 'Sélectionner' : formatMeetingTime(_toApiTime(_start!)),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickStart,
                  ),
                  ListTile(
                    title: const Text('Heure de fin'),
                    subtitle: Text(
                      _end == null ? 'Sélectionner' : formatMeetingTime(_toApiTime(_end!)),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickEnd,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_type == MeetingType.online)
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Lien meeting',
                  hintText: 'https://…',
                ),
                validator: (String? v) {
                  final String value = v?.trim() ?? '';
                  if (value.isEmpty) {
                    return 'Le lien meeting est requis pour une réunion en ligne';
                  }
                  final RegExp url =
                      RegExp(r'^https?://', caseSensitive: false);
                  if (!url.hasMatch(value)) {
                    return 'Le lien doit commencer par http:// ou https://';
                  }
                  return null;
                },
              )
            else
              _roomSelector(rooms),
            const SizedBox(height: 16),
            TextFormField(
              controller: _participantsController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Participants (optionnel)',
                hintText: 'Noms séparés par des virgules',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer la réunion'),
          ),
        ),
      ),
    );
  }

  Widget _roomSelector(AsyncValue<List<MeetingRoom>> rooms) {
    if (rooms.isLoading) {
      return const ListTile(
        leading: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Chargement des salles…'),
      );
    }
    if (rooms.hasError) {
      return Text(
        'Impossible de charger les salles.\n${rooms.error}',
        style: const TextStyle(color: Colors.redAccent),
      );
    }
    final List<MeetingRoom> list = rooms.valueOrNull ?? const <MeetingRoom>[];
    if (list.isEmpty) {
      return const Text(
        'Aucune salle disponible. Contactez votre manager.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _roomId,
      decoration: const InputDecoration(
        labelText: 'Salle',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Sélectionner une salle'),
      items: <DropdownMenuItem<String>>[
        for (final MeetingRoom room in list)
          DropdownMenuItem<String>(
            value: room.id,
            child: Text('${room.name} (${room.capacity} pl.)'),
          ),
      ],
      onChanged: (String? v) => setState(() => _roomId = v),
    );
  }
}
