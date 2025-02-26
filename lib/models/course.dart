class Course {
  final int? id;
  final String name;
  final String teacher;
  final String classroom;
  final int weekday;
  final int startTime;
  final int endTime;
  final int startWeek;
  final int endWeek;

  Course({
    this.id,
    required this.name,
    required this.teacher,
    required this.classroom,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.startWeek,
    required this.endWeek,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'startTime': startTime,
      'endTime': endTime,
      'startWeek': startWeek,
      'endWeek': endWeek,
    };
  }

  static Course fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      teacher: map['teacher'],
      classroom: map['classroom'],
      weekday: map['weekday'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      startWeek: map['startWeek'],
      endWeek: map['endWeek'],
    );
  }
}