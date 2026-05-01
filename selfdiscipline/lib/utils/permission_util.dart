import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<void> requestAll() async {
    // 1. 通知权限（Android 13+）
    await Permission.notification.request();

    // 2. 忽略电池优化（非常关键🔥）
    await Permission.ignoreBatteryOptimizations.request();

    // 3. 精确闹钟（定时提醒用）
    await Permission.scheduleExactAlarm.request();

    print("权限申请完成");
  }
}
