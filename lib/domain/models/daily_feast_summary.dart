class DailyFeastSummary {
  DailyFeastSummary({
    required this.id,
    required this.date,
    required this.totalFeastTimeSec,
    required this.totalMilkSessions,
    required this.totalPee,
    required this.totalPooh,
    required this.alarmEnable,
    this.reminderAt,
    this.lastFeedingTime,
    this.lastFeastEndTime,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String date;
  final int totalFeastTimeSec;
  final int totalMilkSessions;
  final int totalPee;
  final int totalPooh;
  final bool alarmEnable;
  final String? reminderAt;
  final String? lastFeedingTime;
  final String? lastFeastEndTime;
  final String? createdAt;
  final String? updatedAt;

  DailyFeastSummary copyWith({
    int? totalFeastTimeSec,
    int? totalMilkSessions,
    int? totalPee,
    int? totalPooh,
    bool? alarmEnable,
    String? reminderAt,
    String? lastFeedingTime,
    String? lastFeastEndTime,
    String? updatedAt,
  }) {
    return DailyFeastSummary(
      id: id,
      date: date,
      totalFeastTimeSec: totalFeastTimeSec ?? this.totalFeastTimeSec,
      totalMilkSessions: totalMilkSessions ?? this.totalMilkSessions,
      totalPee: totalPee ?? this.totalPee,
      totalPooh: totalPooh ?? this.totalPooh,
      alarmEnable: alarmEnable ?? this.alarmEnable,
      reminderAt: reminderAt ?? this.reminderAt,
      lastFeedingTime: lastFeedingTime ?? this.lastFeedingTime,
      lastFeastEndTime: lastFeastEndTime ?? this.lastFeastEndTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DailyFeastSummary.fromMap(Map<String, dynamic> map) {
    return DailyFeastSummary(
      id: map['id'] as int?,
      date: map['date'] as String,
      totalFeastTimeSec: map['total_feast_time_sec'] as int,
      totalMilkSessions: (map['total_milk_sessions'] as int?) ?? 0,
      totalPee: map['total_pee'] as int,
      totalPooh: map['total_pooh'] as int,
      alarmEnable: ((map['alarm_enable'] ?? 1) as int) == 1,
      reminderAt: map['reminder_at'] as String?,
      lastFeedingTime: map['last_feeding_time'] as String?,
      lastFeastEndTime: map['last_feast_end_time'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_feast_time_sec': totalFeastTimeSec,
      'total_milk_sessions': totalMilkSessions,
      'total_pee': totalPee,
      'total_pooh': totalPooh,
      'alarm_enable': alarmEnable ? 1 : 0,
      'reminder_at': reminderAt,
      'last_feeding_time': lastFeedingTime,
      'last_feast_end_time': lastFeastEndTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
