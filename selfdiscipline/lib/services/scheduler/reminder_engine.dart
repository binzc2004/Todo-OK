import 'dart:convert';

import '../../models/task.dart';
import '../../services/notification/notification_service.dart';
import '../../workers/work_manager.dart';
import '../../utils/log.dart';
import '../daily_task_service.dart';
import '../../config/app_config.dart';
import 'dart:math';
class ReminderEngine {
  final DailyTaskService _dailyTaskService = DailyTaskService();

  /// =========================
  /// 🚀 启动任务（8点调用 or 手动调用）
  /// =========================
  static Future<void> start(Task task) async {
    final delay = AppConfig.devMode
        ? const Duration(seconds: 10)
        : _calcInitialDelay(task.timeOfDay);
    Log.d(
      "🟢 RuleEngine START task=${task.id} delay=${delay.inMinutes}min taskName=${task.name}",
    );
    await NotificationService.show(
      title: task.name,
      body: "启动，下次提醒时间${delay.inMinutes} min",
    );

    await WorkManagerService.registerOneOff(
      uniqueName: _key(task.id!),
      taskName: "reminder_task",
      inputData: {"task": jsonEncode(task.toMap()), "count": 0},
      delay: delay,
    );
  }

  /// =========================
  /// ⛔ 停止任务
  /// =========================
  static Future<void> stop(int taskId) async {
    Log.d("🔴 RuleEngine STOP task=$taskId");
    await WorkManagerService.cancel(_key(taskId));
  }

  Future<void> handle(Map<String, dynamic>? data) async {
    if (data == null) return;

    final taskStr = data["task"];
    final taskMap = jsonDecode(taskStr);

    final Task task = Task.fromMap(taskMap);

    int count = data["count"] ?? 0;

    Log.d("🔁 RUN task=${task.id} count=$count");

    if (!(await _shouldContinue(task, count))) {
      Log.d("⛔ STOP task=${task.id}");
      await NotificationService.show(
        title: task.name,
        body: "${task.name}已完成，干的不错哦，再接再厉吧",
      );
      return;
    }

    await _execute(task, count);

    count++;

    await WorkManagerService.registerOneOff(
      uniqueName: _key(task.id!),
      taskName: "reminder_task",
      inputData: {
        "task": jsonEncode(task.toMap()), // ✅ 继续传字符串
        "count": count,
      },
      delay: _nextDelay(task),
    );
  }

  /// =========================
  /// 🎯 执行逻辑
  /// =========================
  Future<void> _execute(Task task, int count) async {
    await NotificationService.show(
      title: task.name,
      body: "第 ${count + 1} 次提醒 🚀",
    );
  }

  /// =========================
  /// ⛔ 停止条件
  /// =========================
  Future<bool> _shouldContinue(Task task, int count) async {
    final taskId = task.id!;
    if (count >= 10) {
      return false;
    }
    if (await _dailyTaskService.isTodayTaskFinished(taskId)) {
      return false;
    }
    if (_isEndOfDay()) {
      return false;
    }
    return true;
  }

  /// =========================
  /// ⏱ 下一次执行间隔
  /// =========================
  Duration _nextDelay(Task task) {
    int interval = task.intervalMinutes ?? 1;

    if (interval <= 0) interval = 60;

    return Duration(minutes: interval);
  }

  /// =========================
  /// 🕐 首次启动时间
  /// =========================
  static Duration _calcInitialDelay(String? timeOfDay) {
    final now = DateTime.now();

    // 立即执行
    if (timeOfDay == null || timeOfDay.isEmpty || timeOfDay == "0") {
      return const Duration(seconds: 1);
    }

    final parts = timeOfDay.split(":");
    if (parts.length != 2) {
      return const Duration(seconds: 1);
    }

    final target = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // 如果目标时间已经过去，直接返回1秒
    if (target.isBefore(now)) {
      final randomSeconds = Random().nextInt(20) + 1; // 1~20
      return Duration(seconds: randomSeconds);
    }

    return target.difference(now);
  }

  /// =========================
  /// 🌙 是否到24点
  /// =========================
  bool _isEndOfDay() {
    final now = DateTime.now();

    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return now.isAfter(endOfDay);
  }

  /// =========================
  /// 🔑 key
  /// =========================
  static String _key(int taskId) => "rule_$taskId";
}
