import 'package:shared_preferences/shared_preferences.dart';
import '../user_service.dart';
import '../../utils/log.dart';

class AuthManager {
  static const _keyLogin = "login";
  static const _keyUsername = "username";

  /// =========================
  /// 🔐 登录（只负责认证）
  /// =========================
  static Future<bool> login(String username, String password) async {
    final user = await UserService().login(username, password);

    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyLogin, true);
    await sp.setString(_keyUsername, username);

    Log.d("✅ 登录成功");

    return true; // ❗只返回状态，不做副作用
  }

  /// =========================
  /// 🚪 登出（只清状态）
  /// =========================
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyLogin, false);
    await sp.remove(_keyUsername);

    Log.d("🚪 登出完成");
  }

  static Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_keyLogin) ?? false;
  }

  static Future<String?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_keyUsername);
  }
}
