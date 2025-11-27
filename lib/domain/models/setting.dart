class Setting {
  Setting({
    required this.id,
    required this.settingname,
    required this.displayName,
    required this.enable,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String settingname;
  final String displayName;
  final bool enable;
  final String? createdAt;
  final String? updatedAt;

  Setting copyWith({bool? enable}) {
    return Setting(
      id: id,
      settingname: settingname,
      displayName: displayName,
      enable: enable ?? this.enable,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      id: map['settingid'] as int?,
      settingname: map['settingname'] as String,
      displayName: map['display_name'] as String,
      enable: (map['enable'] as int) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settingid': id,
      'settingname': settingname,
      'display_name': displayName,
      'enable': enable ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
