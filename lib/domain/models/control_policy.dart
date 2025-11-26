class ControlPolicy {
  ControlPolicy({
    required this.id,
    required this.type,
    required this.value,
    required this.remindHr,
    required this.valueCategory,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String type;
  final double value;
  final double remindHr;
  final String valueCategory;
  final String? createdAt;
  final String? updatedAt;

  ControlPolicy copyWith({double? value, double? remindHr}) {
    return ControlPolicy(
      id: id,
      type: type,
      value: value ?? this.value,
      remindHr: remindHr ?? this.remindHr,
      valueCategory: valueCategory,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ControlPolicy.fromMap(Map<String, dynamic> map) {
    return ControlPolicy(
      id: map['id'] as int?,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      remindHr: (map['remind_hr'] as num).toDouble(),
      valueCategory: map['value_category'] as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'remind_hr': remindHr,
      'value_category': valueCategory,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
