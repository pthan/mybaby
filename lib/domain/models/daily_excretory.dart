class DailyExcretory {
  DailyExcretory({
    required this.id,
    required this.date,
    required this.peeCount,
    required this.poopCount,
    this.lastPeeTime,
    this.lastPoopTime,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String date;
  final int peeCount;
  final int poopCount;
  final String? lastPeeTime;
  final String? lastPoopTime;
  final String? createdAt;
  final String? updatedAt;

  DailyExcretory copyWith({
    int? peeCount,
    int? poopCount,
    String? lastPeeTime,
    String? lastPoopTime,
    String? updatedAt,
  }) {
    return DailyExcretory(
      id: id,
      date: date,
      peeCount: peeCount ?? this.peeCount,
      poopCount: poopCount ?? this.poopCount,
      lastPeeTime: lastPeeTime ?? this.lastPeeTime,
      lastPoopTime: lastPoopTime ?? this.lastPoopTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DailyExcretory.fromMap(Map<String, dynamic> map) {
    return DailyExcretory(
      id: map['id'] as int?,
      date: map['date'] as String,
      peeCount: map['pee_count'] as int,
      poopCount: map['poop_count'] as int,
      lastPeeTime: map['last_pee_time'] as String?,
      lastPoopTime: map['last_poop_time'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'pee_count': peeCount,
      'poop_count': poopCount,
      'last_pee_time': lastPeeTime,
      'last_poop_time': lastPoopTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
