import 'dart:convert';

class RuleEngine {
  /// =========================
  /// 🚀 入口：统一解析 config
  /// =========================
  static bool shouldRunToday(Map task, DateTime now) {
    final ruleType = task['rule_type'];

    final config = _parseConfig(task['rule_config']);

    switch (ruleType) {
      case 0:
        return _checkWeekdays(config, now);
      case 1:
        return _checkOddEven(config, now);
      case 2:
        return _checkInterval(task, config, now);
      default:
        return true;
    }
  }

  /// =========================
  /// 🧠 统一解析 JSON/String
  /// =========================
  static Map _parseConfig(dynamic config) {
    if (config == null) return {};
    if (config is Map) return config;
    return jsonDecode(config);
  }

  /// =========================
  /// 📅 周几规则
  /// =========================
  static bool _checkWeekdays(Map config, DateTime now) {
    final weekdays = config['weekdays'] ?? [];
    return weekdays.contains(now.weekday);
  }

  /// =========================
  /// 🔢 奇偶日规则
  /// =========================
  static bool _checkOddEven(Map config, DateTime now) {
    final oddEven = config['oddEven'] ?? 1;
    final day = now.day;

    return oddEven == 1 ? day % 2 == 1 : day % 2 == 0;
  }

  /// =========================
  /// ⏱ 间隔天规则
  /// =========================
  static bool _checkInterval(
    Map task,
    Map config,
    DateTime now,
  ) {
    final intervalDays = config['intervalDays'] ?? 1;
    final start = task['start_date'];

    if (start == null) return true;

    final startDate = DateTime.tryParse(start);
    if (startDate == null) return true;

    final diff = now.difference(startDate).inDays;
    return diff % intervalDays == 0;
  }
}