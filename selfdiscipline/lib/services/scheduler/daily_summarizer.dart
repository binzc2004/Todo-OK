import '../../dao/daily_task_dao.dart';
import '../../dao/stats_dao.dart';
import '../../models/daily_stats.dart';
import '../../utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification/notification_service.dart';
import '../../workers/work_manager.dart';
import '../../utils/log.dart';
import 'reminder_engine.dart';
import '../../config/app_config.dart';
class DailySummarizer {
  final _dailyDao = DailyTaskDao();
  final _statsDao = StatsDao();

  /// =========================
  /// 🚀 主逻辑（Worker调用）
  /// =========================
  Future<void> summarizeToday([Map<String, dynamic>? data]) async {
    _stopTodayReminders();
    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "今日任务停止调度",
      body: "今天的督促结束了，你有完成多少呢？",
    );
    final today = DateUtilsHelper.format(DateTime.now());
    Log.d("🌙 开始每日总结: $today");
    final tasks = await _dailyDao.getByDate(today);
    if (tasks.isEmpty) {
      Log.d("⚠️ 今日无任务，跳过总结");

      /// 即使没有任务，也要继续调度
      await _scheduleNext2359();
      return;
    }
    final total = tasks.length;
    final finished = tasks.where((t) => t.status == 1).length;
    final skipped = tasks.where((t) => t.status == 2).length;
    final rate = total == 0 ? 0.0 : finished / total;

    /// 🔥 更新 streak（更严谨版本）
    await _updateStreak(finished == total, today);

    /// 📊 写入统计
    await _statsDao.upsertStats(
      DailyStats(
        date: today,
        total: total,
        finished: finished,
        skipped: skipped,
        completionRate: rate,
      ),
    );
    Log.d("📊 今日统计完成：$finished/$total");

    /// 🔔 通知
    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "统计完成",
      body: "今日完成率 ${(rate * 100).toStringAsFixed(0)}%",
    );

    await _stopTodayReminders();
    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "今日任务停止调度",
      body: "今天的督促结束了，你有完成多少呢？",
    );
    /// 🔁 明天23:59继续
    await _scheduleNext2359();
  }

  /// =========================
  /// 🔥 连续天数（修复版）
  /// =========================
  Future<void> _updateStreak(bool fullDone, String today) async {
    final sp = await SharedPreferences.getInstance();
    int streak = sp.getInt("streak") ?? 0;
    if (!fullDone) {
      streak = 0;
    } else {
      streak++;
    }
    await sp.setInt("streak", streak);
    Log.d("🔥 streak更新: $streak");
  }

  /// =========================
  /// ⛔ 停止今日所有 reminder 任务
  /// =========================
  Future<void> _stopTodayReminders() async {
    final today = DateUtilsHelper.today();
    Log.d("⛔ 开始停止今日所有 reminder");
    /// 1️⃣ 查今日任务
    final tasks = await _dailyDao.getByDate(today);
    if (tasks.isEmpty) {
      Log.d("⚠️ 今日无任务，无需停止");
      return;
    }
    /// 2️⃣ 去重 taskId（防止重复 stop）
    final taskIds = tasks.map((e) => e.taskId).toSet();
    /// 3️⃣ 批量停止
    for (final taskId in taskIds) {
      await ReminderEngine.stop(taskId);
    }
    Log.d("✅ 今日 reminder 已全部停止");
  }

  /// =========================
  /// ▶️ 启动入口（App启动调用）
  /// =========================
  static Future<void> start() async {
    Log.d("24点总结任务启动！！！");
    final delay = AppConfig.devMode
        ? const Duration(minutes: 5)
        : _calcNext2359();
    await WorkManagerService.registerOneOff(
      uniqueName: "daily_summary_2359",
      taskName: "daily_summarizer",
      delay: delay,
    );
  }

  /// =========================
  /// 🔁 注册下一次（核心）
  /// =========================
  Future<void> _scheduleNext2359() async {
    await WorkManagerService.registerOneOff(
      uniqueName: "daily_summary_2359",
      taskName: "daily_summarizer",
      delay: _calcNext2359(),
    );
  }

  /// =========================
  /// ⏰ 下一个23:59
  /// =========================
  static Duration _calcNext2359() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, 23, 59);

    if (now.isAfter(next)) {
      return next.add(const Duration(days: 1)).difference(now);
    } else {
      return next.difference(now);
    }
  }

  /// =========================
  /// ⛔ 停止
  /// =========================
  static Future<void> stop() async {
    await WorkManagerService.cancel("daily_summary_2359");
  }
}
