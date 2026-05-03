import '../../dao/task_dao.dart';
import '../../dao/daily_task_dao.dart';
import '../../utils/date_utils.dart';
import '../../services/rule_engine.dart';
import '../../models/daily_task.dart';
import '../notification/notification_service.dart';
import '../../workers/work_manager.dart';
import '../../utils/log.dart';
import 'reminder_engine.dart';
import '../../config/app_config.dart';
import '../../const/Type.dart';

class TaskGenerator {
  static final taskDao = TaskDao();
  static final dailyDao = DailyTaskDao();
  static Future<void> refreshDailyTasks() async {
    final today = DateUtilsHelper.format(DateTime.now());
    final exists = await dailyDao.getByDate(today);
    final tasks = await taskDao.getAllTasks();
    for (final task in tasks) {
      final shouldRun = RuleEngine.shouldRunToday(task.toMap(), DateTime.now());
      if (!shouldRun) continue;
      final already = exists.any((e) => e.taskId == task.id);
      if (already) continue;
      final daily = DailyTask(
        taskId: task.id!,
        taskName: task.name,
        date: today,
        status: 0,
      );
      await dailyDao.insert(daily);
    }
  }

  static Future<void> generateDailyTasks({bool force = false}) async {
    await refreshDailyTasks();
    await startTodayTasks();
    await _scheduleNext8AM();
  }

  /// =========================
  /// 🚀 启动今日任务调度（核心新增）
  /// =========================
  static Future<void> startTodayTasks() async {
    Log.d("🚀 启动今日任务调度");
    final today = DateUtilsHelper.today();

    /// 1️⃣ 获取今日任务
    final dailyTasks = await dailyDao.getByDate(today);
    if (dailyTasks.isEmpty) {
      Log.d("⚠️ 今日无任务");
      return;
    }
    final tasks = await taskDao.getAllTasks();
    final taskMap = {for (var t in tasks) t.id!: t};

    /// 3️⃣ 启动 reminder_engine
    for (final daily in dailyTasks) {
      if (daily.status == DoType.todo) {
        final task = taskMap[daily.taskId];
        if (task == null) continue;
        ReminderEngine.start(task);
      }
    }
  }

  /// =========================
  /// ▶️ 启动入口（App启动调用）
  /// =========================
  static Future<void> start() async {
    Log.d("8点定时任务启动！！！");
    final delay = AppConfig.devMode
        ? const Duration(seconds: 1)
        : _calcNext8AM();
    await startTodayTasks();
    await NotificationService.show(
      title: "8点定时任务",
      body: "启动，下次提醒时间${delay.inMinutes} min"
    );
    await WorkManagerService.registerOneOff(
      uniqueName: "daily_task_8am",
      taskName: "generate_daily_task",
      delay: delay,
    );
  }

  /// =========================
  /// 🔁 注册下一次（防重复）
  /// =========================
  static Future<void> _scheduleNext8AM() async {
    await WorkManagerService.registerOneOff(
      uniqueName: "daily_task_8am",
      taskName: "generate_daily_task",
      delay: _calcNext8AM(),
    );
  }

  /// =========================
  /// ⏰ 下一个8点
  /// =========================
  static Duration _calcNext8AM() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, 8);

    if (now.isAfter(next)) {
      return next.add(const Duration(days: 1)).difference(now);
    } else {
      return next.difference(now);
    }
  }

  /// =========================
  /// ⛔ 停止（可选）
  /// =========================
  static Future<void> stop() async {
    await WorkManagerService.cancel("daily_task_8am");
  }
}
