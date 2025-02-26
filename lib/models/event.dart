class Event {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final String location;

  Event({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'description': description,
      'location': location,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      description: map['description'],
      location: map['location'],
    );
  }
}
