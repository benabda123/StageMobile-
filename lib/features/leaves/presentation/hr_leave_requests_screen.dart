import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../ai_assistant/data/ai_assistant_repository.dart';
import '../../ai_assistant/domain/leave_analysis_model.dart';
import '../data/leave_repository.dart';
import '../domain/leave_model.dart';
import 'leave_ui.dart';
import 'leaves_provider.dart';

/// Toutes les demandes de congé (`GET /leaves`), filtrables par statut, avec
/// validation (Accepter / Refuser) — réservé admin / hr.
class HrLeaveRequestsScreen extends ConsumerWidget {
  const HrLeaveRequestsScreen({super.key});

  static const List<String?> _statusFilters = <String?>[
    null,
    LeaveStatus.pending,
    LeaveStatus.approved,
    LeaveStatus.rejected,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Leave>> leaves = ref.watch(allLeavesProvider);
    final String? selectedStatus = ref.watch(_leaveFilterProvider);

    final List<Leave> filtered = leaves.valueOrNull == null
        ? const <Leave>[]
        : (leaves.valueOrNull!
            .where((Leave l) => selectedStatus == null || l.status == selectedStatus)
            .toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de congé'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
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
                        status == null ? 'Tous' : leaveStatusLabel(status),
                      ),
                      selected: selectedStatus == status,
                      onSelected: (_) =>
                          ref.read(_leaveFilterProvider.notifier).state = status,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: leaves.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => ListView(
                children: <Widget>[
                  const SizedBox(height: 48),
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Impossible de charger les demandes.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return ListView(
                    children: const <Widget>[
                      SizedBox(height: 48),
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Aucune demande.', textAlign: TextAlign.center),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(allLeavesProvider.future),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Leave leave = filtered[index];
                      final bool isPending =
                          leave.status == LeaveStatus.pending;
                      return ListTile(
                        leading: Icon(
                          leaveTypeIcon(leave.type),
                          color: leaveStatusColor(leave.status),
                        ),
                        title: Text(
                          '${leave.employeeUsername ?? '—'} · '
                          '${leaveTypeLabel(leave.type)}',
                        ),
                        subtitle: Text(
                          '${formatLeaveDate(leave.startDate)} → '
                          '${formatLeaveDate(leave.endDate)}'
                          '${leave.reason == null || leave.reason!.isEmpty ? '' : '\n${leave.reason}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isPending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.auto_awesome,
                                        color: GlassTokens.submitBlue),
                                    tooltip: 'Analyser avec l\'IA',
                                    onPressed: () => _showAiAnalysis(
                                      context,
                                      ref,
                                      leave,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    tooltip: 'Accepter',
                                    onPressed: () => _decide(
                                      ref,
                                      context,
                                      leave.id,
                                      approve: true,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                    tooltip: 'Refuser',
                                    onPressed: () => _decide(
                                      ref,
                                      context,
                                      leave.id,
                                      approve: false,
                                    ),
                                  ),
                                ],
                              )
                            : LeaveStatusBadge(status: leave.status),
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

  Future<void> _showAiAnalysis(
    BuildContext context,
    WidgetRef ref,
    Leave leave,
  ) async {
    final int? requestId = int.tryParse(leave.id);
    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de demande invalide.')),
      );
      return;
    }

    // Show loading bottom sheet while fetching analysis
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AnalysisLoadingSheet(leave: leave),
    );

    try {
      final LeaveAnalysis analysis = await ref
          .read(aiAssistantRepositoryProvider)
          .analyzeLeave(leaveRequestId: requestId);
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading sheet
        _showAnalysisResult(context, ref, leave, analysis);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading sheet
        _showAnalysisError(context, ref, leave, e.toString());
      }
    }
  }

  void _showAnalysisResult(
    BuildContext context,
    WidgetRef ref,
    Leave leave,
    LeaveAnalysis analysis,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AnalysisResultSheet(
        leave: leave,
        analysis: analysis,
        onApprove: () => _decideFromSheet(ref, context, leave.id, approve: true),
        onReject: () => _decideFromSheet(ref, context, leave.id, approve: false),
      ),
    );
  }

  void _showAnalysisError(
    BuildContext context,
    WidgetRef ref,
    Leave leave,
    String error,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AnalysisErrorSheet(
        leave: leave,
        errorMessage: error,
        onApprove: () => _decideFromSheet(ref, context, leave.id, approve: true),
        onReject: () => _decideFromSheet(ref, context, leave.id, approve: false),
      ),
    );
  }

  Future<void> _decideFromSheet(
    WidgetRef ref,
    BuildContext context,
    String leaveId, {
    required bool approve,
  }) async {
    try {
      if (approve) {
        await ref.read(leaveRepositoryProvider).approveLeave(leaveId);
      } else {
        await ref.read(leaveRepositoryProvider).rejectLeave(leaveId);
      }
      ref.invalidate(allLeavesProvider);
      if (context.mounted) {
        Navigator.of(context).pop(); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Demande approuvée.' : 'Demande refusée.'),
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

  Future<void> _decide(
    WidgetRef ref,
    BuildContext context,
    String leaveId, {
    required bool approve,
  }) async {
    try {
      if (approve) {
        await ref.read(leaveRepositoryProvider).approveLeave(leaveId);
      } else {
        await ref.read(leaveRepositoryProvider).rejectLeave(leaveId);
      }
      ref.invalidate(allLeavesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Demande approuvée.' : 'Demande refusée.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'action.\n$e')),
        );
      }
    }
  }
}

/// Filtre de statut sélectionné dans la liste RH.
final _leaveFilterProvider = StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// Bottom sheets
// ---------------------------------------------------------------------------

/// Loading sheet displayed while the AI analysis is being generated.
class _AnalysisLoadingSheet extends StatelessWidget {
  const _AnalysisLoadingSheet({required this.leave});

  final Leave leave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Analyse IA de la demande de ${leave.employeeUsername ?? "—"}...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'IA analyse les données d\'équipe, les congés existants\net les échéances critiques.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlassTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Full analysis result displayed in a bottom sheet.
class _AnalysisResultSheet extends StatelessWidget {
  const _AnalysisResultSheet({
    required this.leave,
    required this.analysis,
    required this.onApprove,
    required this.onReject,
  });

  final Leave leave;
  final LeaveAnalysis analysis;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _availabilityColor(int percent) {
    if (percent > 70) return GlassTokens.successGreen;
    if (percent >= 40) return GlassTokens.warningOrange;
    return GlassTokens.errorRed;
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
        return GlassTokens.errorRed;
      case 'MEDIUM':
        return GlassTokens.warningOrange;
      default:
        return GlassTokens.successGreen;
    }
  }

  String _riskLabel(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':
        return 'Élevé';
      case 'MEDIUM':
        return 'Moyen';
      default:
        return 'Faible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color availColor = _availabilityColor(analysis.teamAvailabilityPercent);
    final Color riskColor = _riskColor(analysis.riskLevel);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext ctx, ScrollController scroll) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GlassTokens.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const <Widget>[
                  Icon(Icons.auto_awesome, color: GlassTokens.submitBlue, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Analyse IA',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${leave.employeeUsername ?? "—"} · ${leaveTypeLabel(leave.type)}',
                style: const TextStyle(color: GlassTokens.textSecondary),
              ),
              const SizedBox(height: 20),

              // --- Team availability ---
              const Text(
                'Disponibilité équipe',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: analysis.teamAvailabilityPercent / 100,
                        minHeight: 10,
                        backgroundColor: GlassTokens.glassBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(availColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${analysis.teamAvailabilityPercent}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: availColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Active tasks ---
              _InfoRow(
                icon: Icons.task_alt,
                label: 'Tâches actives',
                value: '${analysis.activeTasks}',
              ),
              const SizedBox(height: 12),

              // --- Risk level ---
              Row(
                children: <Widget>[
                  const Icon(Icons.shield_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Niveau de risque : ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _riskLabel(analysis.riskLevel),
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (analysis.riskReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    analysis.riskReason,
                    style: const TextStyle(
                      color: GlassTokens.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // --- Critical deadline warning ---
              if (analysis.criticalDeadlineWarning != null &&
                  analysis.criticalDeadlineWarning!.isNotEmpty) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GlassTokens.warningOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: GlassTokens.warningOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: GlassTokens.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.criticalDeadlineWarning!,
                          style: const TextStyle(
                            color: GlassTokens.warningOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- Recommendation ---
              const Text(
                'Recommandation',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GlassTokens.activeFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlassTokens.activeBorder),
                ),
                child: Text(
                  analysis.recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Approve / Reject buttons ---
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accepter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Error sheet when AI analysis fails — still allows approve/reject.
class _AnalysisErrorSheet extends StatelessWidget {
  const _AnalysisErrorSheet({
    required this.leave,
    required this.errorMessage,
    required this.onApprove,
    required this.onReject,
  });

  final Leave leave;
  final String errorMessage;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, size: 40, color: GlassTokens.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Analyse indisponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'analyse IA n\'est pas disponible pour le moment.\nVous pouvez tout de même traiter cette demande.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GlassTokens.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accepter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable row for an icon + label + value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
      children: <Widget>[
        Icon(icon, size: 18, color: GlassTokens.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
