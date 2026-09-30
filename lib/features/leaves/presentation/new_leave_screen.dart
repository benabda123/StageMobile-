import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../data/leave_repository.dart';
import '../domain/leave_model.dart';
import 'leave_ui.dart';
import 'leaves_provider.dart';

/// Création d'une demande de congé (`POST /leaves`). Retour à la liste avec
/// rafraîchissement au succès.
class NewLeaveScreen extends ConsumerStatefulWidget {
  const NewLeaveScreen({super.key});

  @override
  ConsumerState<NewLeaveScreen> createState() => _NewLeaveScreenState();
}

class _NewLeaveScreenState extends ConsumerState<NewLeaveScreen> {
  String _type = LeaveType.annual;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _toApiDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _submit() async {
    final DateTime? start = _startDate;
    final DateTime? end = _endDate;
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une date de début et de fin.')),
      );
      return;
    }
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être postérieure ou égale à la date de début.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(leaveRepositoryProvider).createLeave(
            type: _type,
            startDate: _toApiDate(start),
            endDate: _toApiDate(end),
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );
      ref.invalidate(myLeavesProvider);
      ref.invalidate(allLeavesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création de la demande.\n$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Nouvelle demande',
          style: TextStyle(color: GlassTokens.textPrimary, fontSize: 18),
        ),
        showLogo: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Type de congé',
            style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final String type in LeaveType.values)
            GlassSelectableTile(
              label: leaveTypeLabel(type),
              icon: leaveTypeIcon(type),
              selected: _type == type,
              onTap: () => setState(() => _type = type),
            ),
          const SizedBox(height: 16),
          const Text(
            'Dates',
            style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          GlassSelectableTile(
            label: _startDate == null
                ? 'Date de début — Sélectionner'
                : 'Début : ${formatLeaveDate(_toApiDate(_startDate!))}',
            icon: Icons.calendar_today_outlined,
            selected: _startDate != null,
            onTap: () => _pickDate(start: true),
          ),
          GlassSelectableTile(
            label: _endDate == null
                ? 'Date de fin — Sélectionner'
                : 'Fin : ${formatLeaveDate(_toApiDate(_endDate!))}',
            icon: Icons.event_outlined,
            selected: _endDate != null,
            onTap: () => _pickDate(start: false),
          ),
          const SizedBox(height: 16),
          const Text(
            'Motif (optionnel)',
            style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          GlassBlur(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: GlassTokens.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Raison de la demande…',
                hintStyle: TextStyle(color: GlassTokens.textHint),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GlassPrimaryButton(
            label: 'Envoyer la demande',
            loading: _submitting,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
