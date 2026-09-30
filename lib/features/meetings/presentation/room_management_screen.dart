import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';
import 'meetings_provider.dart';

/// Gestion des salles de réunion (`GET /rooms` + CRUD) — réservé
/// admin / manager.
class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  Future<void> _openRoomDialog({MeetingRoom? room}) async {
    final TextEditingController nameController =
        TextEditingController(text: room?.name ?? '');
    final TextEditingController capacityController =
        TextEditingController(text: room == null ? '' : '${room.capacity}');
    final TextEditingController equipmentController = TextEditingController(
      text: (room?.equipment ?? const <String>[]).join(', '),
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(room == null ? 'Nouvelle salle' : 'Modifier la salle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (String? v) => (v == null || v.trim().isEmpty)
                      ? 'Le nom est requis'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacité'),
                  validator: (String? v) {
                    final int? capacity = int.tryParse(v ?? '');
                    if (capacity == null || capacity <= 0) {
                      return 'Capacité invalide (> 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: equipmentController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Équipements (optionnel)',
                    hintText: 'Séparés par des virgules',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (saved != true) {
      nameController.dispose();
      capacityController.dispose();
      equipmentController.dispose();
      return;
    }

    final String name = nameController.text.trim();
    final List<String> equipment = equipmentController.text
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    final int capacity = int.tryParse(capacityController.text.trim()) ?? 0;

    nameController.dispose();
    capacityController.dispose();
    equipmentController.dispose();

    try {
      if (room == null) {
        await ref.read(roomRepositoryProvider).createRoom(
              name: name,
              capacity: capacity,
              equipment: equipment,
            );
      } else {
        await ref.read(roomRepositoryProvider).updateRoom(
              room.id,
              name: name,
              capacity: capacity,
              equipment: equipment,
            );
      }
      ref.invalidate(roomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(room == null ? 'Salle créée.' : 'Salle modifiée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _confirmDelete(MeetingRoom room) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Supprimer la salle'),
        content: Text(
          'Supprimer « ${room.name} » ? Les réunions associées perdront '
          'leur salle.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(roomRepositoryProvider).deleteRoom(room.id);
      ref.invalidate(roomsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salle supprimée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MeetingRoom>> rooms = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salles de réunion'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openRoomDialog(),
        tooltip: 'Nouvelle salle',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(roomsProvider.future),
        child: rooms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => ListView(
            children: <Widget>[
              const SizedBox(height: 48),
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Impossible de charger les salles.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          data: (List<MeetingRoom> items) {
            if (items.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 48),
                  Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucune salle.', textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(
                    'Touchez + pour créer une salle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final MeetingRoom room = items[index];
                return ListTile(
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(room.name),
                  subtitle: Text(
                    'Capacité : ${room.capacity}'
                    '${room.equipment.isEmpty ? '' : ' · ${room.equipment.join(', ')}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Modifier',
                        onPressed: () => _openRoomDialog(room: room),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDelete(room),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
