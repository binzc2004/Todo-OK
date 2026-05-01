import 'package:flutter/material.dart';
class RuleType {
  static const weekly = 0; // 周几
  static const oddEven = 1; // 单双日
  static const interval = 2; // 每N天
}

class DoType {
  static const int todo = 0; // 未完成
  static const int done = 1; // 已完成
  static const int skipped = 2; // 跳过（偷懒😏）

  /// 👉 转中文（强烈建议统一走这里）
  static String toText(int type) {
    switch (type) {
      case done:
        return "完成";
      case skipped:
        return "偷懒";
      case todo:
      default:
        return "未完成";
    }
  }

  /// 👉 转颜色（UI统一）
  static Color color(int type) {
    switch (type) {
      case done:
        return Colors.green;
      case skipped:
        return Colors.orange;
      case todo:
      default:
        return Colors.red;
    }
  }
}
