import 'package:flutter_test/flutter_test.dart';
import 'package:keystone_mobile/features/leaves/domain/leave_model.dart';

Leave _leave(String status, {String? start, String? end}) {
  return Leave(
    id: '1',
    type: LeaveType.annual,
    startDate: start,
    endDate: end,
    status: status,
  );
}

void main() {
  group('leaveDays', () {
    test('bornes incluses', () {
      expect(leaveDays('2026-08-10', '2026-08-10'), 1);
      expect(leaveDays('2026-08-10', '2026-08-12'), 3);
      expect(leaveDays('2026-08-12', '2026-08-10'), 0);
      expect(leaveDays(null, '2026-08-10'), 0);
    });

    test('accepte les timestamps ISO du backend', () {
      expect(
        leaveDays('2026-08-10T00:00:00.000Z', '2026-08-12T00:00:00.000Z'),
        3,
      );
    });
  });

  group('LeaveStats', () {
    test('daysRemaining = 18 - jours acceptés', () {
      final List<Leave> leaves = <Leave>[
        _leave(LeaveStatus.approved, start: '2026-08-10', end: '2026-08-12'),
        _leave(LeaveStatus.pending),
        _leave(LeaveStatus.rejected),
      ];
      final LeaveStats stats = LeaveStats.fromLeaves(leaves);
      expect(stats.daysRemaining, 15);
      expect(stats.pendingCount, 1);
      expect(stats.approvedCount, 1);
      expect(stats.rejectedCount, 1);
    });

    test('jours restants plafonnés à 0', () {
      final List<Leave> leaves = <Leave>[
        for (int i = 0; i < 4; i++)
          _leave(
            LeaveStatus.approved,
            start: '2026-08-10',
            end: '2026-08-14',
          ),
      ];
      expect(LeaveStats.fromLeaves(leaves).daysRemaining, 0);
    });

    test('aucune demande -> quota complet', () {
      final LeaveStats stats = LeaveStats.fromLeaves(const <Leave>[]);
      expect(stats.daysRemaining, 18);
      expect(stats.pendingCount, 0);
    });
  });

  group('leaveDateOnly', () {
    test('normalise une date ISO', () {
      expect(leaveDateOnly('2026-08-11T08:40:14.173Z'), '2026-08-11');
      expect(leaveDateOnly('2026-08-11'), '2026-08-11');
      expect(leaveDateOnly(''), isNull);
      expect(leaveDateOnly(null), isNull);
    });
  });
}
