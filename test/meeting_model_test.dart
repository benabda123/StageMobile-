import 'package:flutter_test/flutter_test.dart';
import 'package:keystone_mobile/features/meetings/domain/meeting_model.dart';
import 'package:keystone_mobile/features/meetings/domain/room_model.dart';
import 'package:keystone_mobile/features/meetings/presentation/meeting_ui.dart';

void main() {
  group('Meeting.fromJson', () {
    test('parse les champs snake_case du backend', () {
      final Meeting meeting = Meeting.fromJson(const <String, dynamic>{
        'id': 12,
        'title': 'Point hebdo',
        'description': 'Revue des tâches',
        'date': '2026-08-11T00:00:00.000Z',
        'start_time': '09:00:00',
        'end_time': '10:00:00',
        'type': 'PRESENTIEL',
        'room_id': 3,
        'meeting_link': null,
        'participants': <String>['Jean', 'Marie'],
        'created_by_id': 'uuid-1',
        'created_by_username': 'youcef',
        'status': 'CONFIRMED',
        'change_request_data': null,
        'cancellation_reason': null,
      });

      expect(meeting.id, '12');
      expect(meeting.title, 'Point hebdo');
      expect(meeting.date, '2026-08-11T00:00:00.000Z');
      expect(meeting.startTime, '09:00:00');
      expect(meeting.endTime, '10:00:00');
      expect(meeting.type, MeetingType.presentiel);
      expect(meeting.roomId, '3');
      expect(meeting.participants, <String>['Jean', 'Marie']);
      expect(meeting.createdByUsername, 'youcef');
      expect(meeting.status, MeetingStatus.confirmed);
      expect(meeting.changeRequestData, isNull);
    });

    test('parse change_request_data', () {
      final Meeting meeting = Meeting.fromJson(const <String, dynamic>{
        'id': 1,
        'status': 'CHANGE_REQUEST_PENDING',
        'change_request_data': <String, dynamic>{
          'proposed_date': '2026-09-01T00:00:00.000Z',
          'proposed_start_time': '14:00:00',
          'proposed_end_time': '15:00:00',
          'reason': 'Conflit d\'emploi du temps',
        },
      });

      expect(meeting.status, MeetingStatus.changeRequestPending);
      final MeetingChangeRequest? change = meeting.changeRequestData;
      expect(change, isNotNull);
      expect(change!.proposedDate, '2026-09-01T00:00:00.000Z');
      expect(change.proposedStartTime, '14:00:00');
      expect(change.proposedEndTime, '15:00:00');
      expect(change.reason, 'Conflit d\'emploi du temps');
    });

    test('participants par défaut vides', () {
      final Meeting meeting = Meeting.fromJson(const <String, dynamic>{
        'id': 1,
      });
      expect(meeting.participants, isEmpty);
      expect(meeting.status, MeetingStatus.pending);
    });
  });

  group('meetingDateOnly', () {
    test('normalise une date ISO', () {
      expect(meetingDateOnly('2026-08-11T00:00:00.000Z'), '2026-08-11');
      expect(meetingDateOnly('2026-08-11'), '2026-08-11');
      expect(meetingDateOnly(''), isNull);
      expect(meetingDateOnly(null), isNull);
    });
  });

  group('meetingTimeOnly', () {
    test('extrait HH:MM de HH:MM:SS', () {
      expect(meetingTimeOnly('09:00:00'), '09:00');
      expect(meetingTimeOnly('09:00'), '09:00');
      expect(meetingTimeOnly(''), isNull);
      expect(meetingTimeOnly(null), isNull);
    });
  });

  group('compareMeetingsByDate', () {
    Meeting m(String date, String start) {
      return Meeting(id: '1', date: date, startTime: start);
    }

    test('trie par date puis heure de début', () {
      final List<Meeting> list = <Meeting>[
        m('2026-08-12', '10:00:00'),
        m('2026-08-10', '09:00:00'),
        m('2026-08-10', '08:00:00'),
      ];
      list.sort(compareMeetingsByDate);
      expect(
        list.map((Meeting m) => '${m.date} ${m.startTime}').toList(),
        <String>[
          '2026-08-10 08:00:00',
          '2026-08-10 09:00:00',
          '2026-08-12 10:00:00',
        ],
      );
    });
  });

  group('meetingLocation', () {
    Meeting m(String type, {String? roomId}) {
      return Meeting(id: '1', type: type, roomId: roomId);
    }

    test('réunion en ligne', () {
      expect(
        meetingLocation(m(MeetingType.online), const <String, MeetingRoom>{}),
        'En ligne',
      );
    });

    test('salle résolue par id', () {
      final Map<String, MeetingRoom> rooms = <String, MeetingRoom>{
        '3': const MeetingRoom(id: '3', name: 'Conference Room A', capacity: 10),
      };
      expect(meetingLocation(m(MeetingType.presentiel, roomId: '3'), rooms),
          'Conference Room A');
    });

    test('salle supprimée ou introuvable', () {
      expect(
        meetingLocation(m(MeetingType.presentiel), const <String, MeetingRoom>{}),
        'Salle supprimée',
      );
      expect(
        meetingLocation(
            m(MeetingType.presentiel, roomId: '99'), const <String, MeetingRoom>{}),
        'Salle 99',
      );
    });
  });

  group('MeetingRoom.fromJson', () {
    test('parse capacité et équipements', () {
      final MeetingRoom room = MeetingRoom.fromJson(const <String, dynamic>{
        'id': 3,
        'name': 'Salle A',
        'capacity': 10,
        'equipment': <String>['Projecteur', 'TV'],
      });
      expect(room.id, '3');
      expect(room.name, 'Salle A');
      expect(room.capacity, 10);
      expect(room.equipment, <String>['Projecteur', 'TV']);
    });

    test('capacité tolérante (chaîne) et équipements par défaut', () {
      final MeetingRoom room = MeetingRoom.fromJson(const <String, dynamic>{
        'id': 4,
        'name': 'Salle B',
        'capacity': '8',
      });
      expect(room.capacity, 8);
      expect(room.equipment, isEmpty);
    });
  });
}
