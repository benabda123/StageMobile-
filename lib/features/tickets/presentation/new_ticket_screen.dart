import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';
import 'ticket_ui.dart';
import 'tickets_provider.dart';

/// Création d'un ticket — formulaire glass touch-friendly.
class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _category = TicketCategory.software;
  String _priority = TicketPriority.medium;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(ticketRepositoryProvider).createTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            priority: _priority,
          );
      ref.invalidate(myTicketsProvider);
      ref.invalidate(allTicketsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la création du ticket.\n$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Nouveau ticket',
          style: TextStyle(color: GlassTokens.textPrimary, fontSize: 18),
        ),
        showLogo: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            GlassTextField(
              controller: _titleController,
              label: 'Titre',
              hint: 'Résumé du problème',
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Le titre est requis' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Catégorie',
              style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (final String category in TicketCategory.values)
              GlassSelectableTile(
                label: ticketCategoryLabel(category),
                selected: _category == category,
                onTap: () => setState(() => _category = category),
              ),
            const SizedBox(height: 16),
            const Text(
              'Priorité',
              style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (final String priority in TicketPriority.values)
              GlassSelectableTile(
                label: ticketPriorityLabel(priority),
                selected: _priority == priority,
                onTap: () => setState(() => _priority = priority),
              ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Décrivez le problème en détail',
              maxLines: 5,
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? 'La description est requise'
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GlassPrimaryButton(
            label: 'Créer le ticket',
            loading: _submitting,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
