class Task {
  int? id;
  String name;

  String? startDate; // 开始日期
  String? timeOfDay; // 👉 每天触发时间 "08:00"

  int? intervalMinutes; // 间隔提醒（分钟）

  int ruleType; // 规则类型
  String? ruleConfig; // JSON配置

  String? description; // 描述

  Task({
    this.id,
    required this.name,
    this.startDate,
    this.timeOfDay,
    this.intervalMinutes,
    required this.ruleType,
    this.ruleConfig,
    this.description,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      startDate: map['start_date'],
      timeOfDay: map['time_of_day'], // ✅ 新增
      intervalMinutes: map['interval_minutes'],
      ruleType: map['rule_type'],
      ruleConfig: map['rule_config'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'time_of_day': timeOfDay, // ✅ 新增
      'interval_minutes': intervalMinutes,
      'rule_type': ruleType,
      'rule_config': ruleConfig,
      'description': description,
    };
  }
}
