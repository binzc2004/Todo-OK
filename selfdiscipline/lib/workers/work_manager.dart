import 'package:workmanager/workmanager.dart';
import '../utils/log.dart';

import '../services/scheduler/task_generator.dart';
import '../services/scheduler/daily_summarizer.dart';
import '../services/scheduler/reminder_engine.dart';
import '../services/scheduler/test.dart';
/// ===============================
/// 🚀 Worker入口（只做分发）
/// ===============================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    Log.d("🔥 WORKER进入: $task");

    try {
      if (task == "generate_daily_task") {
        await TaskGenerator.generateDailyTasks();
      } else if (task == "daily_summarizer") {
        await DailySummarizer().summarizeToday(inputData);
      } else if (task == "reminder_task") {
        await ReminderEngine().handle(inputData);
      } else if (task == "test_task") {
        await TestTask().handle(inputData);
      } else {
        print("⚠️ 未知任务: $task");
      }

      return true;
    } catch (e) {
      print("❌ Worker异常: $e");
      return false;
    }
  });
}

/// ===============================
/// 🚀 WorkManager工具层（纯净）
/// ===============================
class WorkManagerService {
  /// 初始化
  static Future<void> init() async {
    Log.d("🟢 WorkManager init");

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

    Log.d("🟢 WorkManager ready");
  }

  /// ▶️ 注册一次任务
  static Future<void> registerOneOff({
    required String uniqueName,
    required String taskName,
    Map<String, dynamic>? inputData,
    Duration? delay,
  }) async {
    await Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      inputData: inputData,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// ⛔ 取消单个
  static Future<void> cancel(String uniqueName) async {
    await Workmanager().cancelByUniqueName(uniqueName);
  }

  /// ⛔ 全部取消
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
