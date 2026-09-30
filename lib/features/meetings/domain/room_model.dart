/// Salle de réunion (`GET /rooms`, `POST /rooms`…).
class MeetingRoom {
  const MeetingRoom({
    required this.id,
    this.name = '',
    this.capacity = 0,
    this.equipment = const <String>[],
  });

  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    final int? capacity = json['capacity'] is int
        ? json['capacity'] as int
        : int.tryParse(json['capacity']?.toString() ?? '');
    final dynamic raw = json['equipment'];
    return MeetingRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      capacity: capacity ?? 0,
      equipment: raw is List
          ? raw
                .map((dynamic e) => e?.toString() ?? '')
                .where((String s) => s.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  final String id;
  final String name;
  final int capacity;
  final List<String> equipment;
}
