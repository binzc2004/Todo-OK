import 'package:vibration/vibration.dart';
import '../../utils/log.dart';

class VibrationService {
  static bool _running = false;

  /// 📳 是否支持震动
  static Future<bool> hasVibrator() async {
    bool ans = await Vibration.hasVibrator() ?? false;
    if (!ans) {
      Log.d("无震动设备");
    }
    return ans;
  }

  /// 🔹 单次震动
  static Future<void> vibrate({int duration = 500}) async {
    if (await hasVibrator()) {
      await Vibration.vibrate(duration: duration);
    }
  }

  /// 🔥 持续震动（来电效果）
  static Future<void> startLoop() async {
    if (!(await hasVibrator())) return;
    _running = true;

    while (_running) {
      await Vibration.vibrate(duration: 500);
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  /// ⛔ 停止震动
  static Future<void> stop() async {
    _running = false;
    await Vibration.cancel();
  }
}
