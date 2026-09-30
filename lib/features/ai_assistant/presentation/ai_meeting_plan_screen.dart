import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../domain/meeting_plan_model.dart';

class AiMeetingPlanScreen extends StatelessWidget {
  const AiMeetingPlanScreen({super.key, required this.plan});

  final MeetingPlan plan;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const WavesBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text('Plan de réunion'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: <Widget>[
              GlassBlur(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plan.title,
                      style: const TextStyle(
                        color: GlassTokens.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.objective,
                      style: const TextStyle(
                        color: GlassTokens.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: GlassTokens.activeFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GlassTokens.activeBorder),
                      ),
                      child: Text(
                        '${plan.durationMinutes} minutes — ${plan.durationReason}',
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.participants.isNotEmpty) ...<Widget>[
                const _SectionTitle(title: 'Participants recommandés'),
                GlassBlur(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: plan.participants.map((MeetingPlanParticipant p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.person_outline,
                              color: GlassTokens.accentBorder,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    p.username,
                                    style: const TextStyle(
                                      color: GlassTokens.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    p.reason,
                                    style: const TextStyle(
                                      color: GlassTokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (plan.agenda.isNotEmpty) ...<Widget>[
                const _SectionTitle(title: 'Agenda proposé'),
                GlassBlur(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: plan.agenda.asMap().entries.map((
                      MapEntry<int, MeetingPlanAgendaItem> entry,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: GlassTokens.activeFill,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: GlassTokens.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    entry.value.topic,
                                    style: const TextStyle(
                                      color: GlassTokens.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.minutes} min',
                                    style: const TextStyle(
                                      color: GlassTokens.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (plan.suggestedQuestions.isNotEmpty) ...<Widget>[
                const _SectionTitle(title: 'Questions suggérées'),
                ...plan.suggestedQuestions.entries.map((
                  MapEntry<String, List<String>> entry,
                ) {
                  return GlassBlur(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      iconColor: GlassTokens.textSecondary,
                      collapsedIconColor: GlassTokens.textSecondary,
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          color: GlassTokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: entry.value.map((String question) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: GlassTokens.accentBorder,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  question,
                                  style: const TextStyle(
                                    color: GlassTokens.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GlassPrimaryButton(
                label: 'Créer cette réunion',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  final String participants = plan.participants
                      .map((MeetingPlanParticipant p) => p.username)
                      .join(', ');
                  context.push('/meetings/new', extra: <String, dynamic>{
                    'title': plan.title,
                    'description': plan.objective,
                    'participants': participants,
                    'durationMinutes': plan.durationMinutes,
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: GlassTokens.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
