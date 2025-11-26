class DailyFeast {
  DailyFeast({
    required this.id,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSec,
  });

  final int? id;
  final String date;
  final String type;
  final String startTime;
  final String endTime;
  final int durationSec;

  factory DailyFeast.fromMap(Map<String, dynamic> map) {
    return DailyFeast(
      id: map['id'] as int?,
      date: map['date'] as String,
      type: map['type'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      durationSec: map['duration_sec'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'start_time': startTime,
      'end_time': endTime,
      'duration_sec': durationSec,
    };
  }
}
