import 'package:shared_preferences/shared_preferences.dart';

class DevModeService {
  static const _key = "dev_mode";

  /// 🧪 是否开启开发者模式
  static Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_key) ?? false;
  }

  /// 🔁 切换模式
  static Future<bool> toggle() async {
    final sp = await SharedPreferences.getInstance();
    final current = sp.getBool(_key) ?? false;
    final next = !current;
    await sp.setBool(_key, next);
    return next;
  }

  /// 🔧 强制设置
  static Future<void> set(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_key, value);
  }
}
