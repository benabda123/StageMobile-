import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/meeting_model.dart';
import '../domain/room_model.dart';
import 'meeting_ui.dart';
import 'meetings_provider.dart';

/// Mes réunions — cartes glass en mode embedded.
class MyMeetingsScreen extends ConsumerWidget {
  const MyMeetingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Meeting>> meetings = ref.watch(myMeetingsProvider);
    final AsyncValue<List<MeetingRoom>> rooms = ref.watch(roomsProvider);

    final Widget body = RefreshIndicator(
      color: GlassTokens.accentBorder,
      onRefresh: () => ref.refresh(myMeetingsProvider.future),
      child: meetings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) => ErrorStateWidget(
          message: ErrorStateWidget.humanMessage(error),
          onRetry: () => ref.invalidate(myMeetingsProvider),
        ),
        data: (List<Meeting> items) {
          final Map<String, MeetingRoom> roomsById = <String, MeetingRoom>{
            for (final MeetingRoom room in rooms.valueOrNull ?? const <MeetingRoom>[])
              room.id: room,
          };
          final List<Meeting> sorted = <Meeting>[...items]
            ..sort(compareMeetingsByDate);

          if (sorted.isEmpty) {
            return const GlassEmptyState(
              message: 'Aucune réunion',
              subtitle: 'Planifiez votre prochaine réunion',
              icon: Icons.event_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: <Widget>[
              const Text(
                'Mes réunions',
                style: TextStyle(
                  color: GlassTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...sorted.map((Meeting meeting) {
                final String location = meetingLocation(meeting, roomsById);
                return GlassListCard(
                  icon: meetingTypeIcon(meeting.type),
                  title: meeting.title,
                  subtitle:
                      '${formatMeetingDate(meeting.date)} · '
                      '${formatMeetingTime(meeting.startTime)}–'
                      '${formatMeetingTime(meeting.endTime)}\n$location',
                  badge: MeetingStatusBadge(status: meeting.status),
                  onTap: () =>
                      context.push('/meetings/${meeting.id}', extra: meeting),
                );
              }),
            ],
          );
        },
      ),
    );

    if (embedded) {
      return Stack(
        children: <Widget>[
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: GlassTokens.submitBlue,
              onPressed: () => context.push('/meetings/new'),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text(
          'Mes réunions',
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
        onPressed: () => context.push('/meetings/new'),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
