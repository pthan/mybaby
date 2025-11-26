class DailyWater {
  DailyWater({
    required this.id,
    required this.date,
    required this.totalMl,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String date;
  final int totalMl;
  final String? createdAt;
  final String? updatedAt;

  DailyWater copyWith({int? totalMl, String? updatedAt}) {
    return DailyWater(
      id: id,
      date: date,
      totalMl: totalMl ?? this.totalMl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DailyWater.fromMap(Map<String, dynamic> map) {
    return DailyWater(
      id: map['id'] as int?,
      date: map['date'] as String,
      totalMl: map['total_ml'] as int,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_ml': totalMl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
