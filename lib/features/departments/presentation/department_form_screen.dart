import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/department_repository.dart';
import '../domain/department_model.dart';
import 'departments_provider.dart';

/// Formulaire département — écran unique pour la création (`POST
/// /departments`) et la modification (`PUT /departments/:id`). S'il est
/// passé, [department] pré-remplit le formulaire (mode édition) ; sinon mode
/// création. Retour à la liste avec rafraîchissement après succès.
class DepartmentFormScreen extends ConsumerStatefulWidget {
  const DepartmentFormScreen({super.key, this.department});

  /// Département à modifier (`null` → création).
  final Department? department;

  @override
  ConsumerState<DepartmentFormScreen> createState() =>
      _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends ConsumerState<DepartmentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.department?.name ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.department?.description ?? '');
  bool _submitting = false;

  bool get _isEditing => widget.department != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String name = _nameController.text.trim();
    final String? description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    setState(() => _submitting = true);
    try {
      final DepartmentRepository repository =
          ref.read(departmentRepositoryProvider);
      if (_isEditing) {
        await repository.updateDepartment(
          widget.department!.id,
          name: name,
          description: description,
        );
      } else {
        await repository.createDepartment(
          name: name,
          description: description,
        );
      }
      ref.invalidate(departmentsProvider);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le département' : 'Nouveau département'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Nom du département',
              ),
              validator: (String? v) {
                final String value = v?.trim() ?? '';
                if (value.isEmpty) {
                  return 'Le nom est requis';
                }
                if (value.length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                alignLabelWithHint: true,
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
                : Text(_isEditing ? 'Enregistrer' : 'Créer le département'),
          ),
        ),
      ),
    );
  }
}
