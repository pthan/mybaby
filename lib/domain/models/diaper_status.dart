class DiaperStatus {
  DiaperStatus({
    required this.active,
    this.activeStartTime,
    this.nextChangeAt,
    this.changeAt,
    this.createdAt,
    this.updatedAt,
  });

  final bool active;
  final String? activeStartTime;
  final String? nextChangeAt;
  final String? changeAt;
  final String? createdAt;
  final String? updatedAt;

  DiaperStatus copyWith({
    bool? active,
    String? activeStartTime,
    String? nextChangeAt,
    String? changeAt,
    String? updatedAt,
  }) {
    return DiaperStatus(
      active: active ?? this.active,
      activeStartTime: activeStartTime ?? this.activeStartTime,
      nextChangeAt: nextChangeAt ?? this.nextChangeAt,
      changeAt: changeAt ?? this.changeAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DiaperStatus.fromMap(Map<String, dynamic> map) {
    return DiaperStatus(
      active: (map['active'] as int) == 1,
      activeStartTime: map['active_start_time'] as String?,
      nextChangeAt: map['next_change_at'] as String?,
      changeAt: map['change_at'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'active': active ? 1 : 0,
      'active_start_time': activeStartTime,
      'next_change_at': nextChangeAt,
      'change_at': changeAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
