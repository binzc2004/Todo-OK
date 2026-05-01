import '../notification/notification_service.dart';
import '../../workers/work_manager.dart';
import '../../utils/log.dart';

class TestTask {
  /// =========================
  /// 🚀 启动（按钮调用）
  /// =========================
  static Future<void> start() async {
    Log.d("🟢 TEST TASK START");

    await WorkManagerService.registerOneOff(
      uniqueName: _key(),
      taskName: "test_task",
      inputData: {
        "count": 0,
      },
      delay: const Duration(seconds: 1), // 立即开始
    );
  }

  /// =========================
  /// ⛔ 停止（按钮调用）
  /// =========================
  static Future<void> stop() async {
    Log.d("🔴 TEST TASK STOP");
    await WorkManagerService.cancel(_key());
  }

  /// =========================
  /// 🔁 Worker入口（核心）
  /// =========================
  Future<void> handle(Map<String, dynamic>? data) async {
    if (data == null) return;

    int count = data["count"] ?? 0;

    Log.d("🔁 TEST RUN count=$count");

    /// ❌ 停止条件（防无限循环）
    if (!_shouldContinue(count)) {
      Log.d("⛔ TEST STOP");
      return;
    }

    /// 🎯 执行
    await _execute(count);

    count++;

    /// 🔁 self-loop
    await WorkManagerService.registerOneOff(
      uniqueName: _key(),
      taskName: "test_task",
      inputData: {
        "count": count,
      },
      delay: const Duration(seconds: 10), // 每10秒
    );
  }

  /// =========================
  /// 🎯 执行逻辑
  /// =========================
  Future<void> _execute(int count) async {
    await NotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "TEST TASK",
      body: "第 ${count + 1} 次提醒 ⏱",
    );
  }

  /// =========================
  /// ⛔ 停止条件
  /// =========================
  bool _shouldContinue(int count) {
    // 👉 防止无限跑（你可以改成别的逻辑）
    if (count >= 50) return false;

    return true;
  }

  /// =========================
  /// 🔑 key
  /// =========================
  static String _key() => "test_task_unique";
}