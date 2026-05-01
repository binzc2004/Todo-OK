import '../dao/user_dao.dart';
import '../models/user.dart';
import '../utils/log.dart';

class UserService {
  final UserDao _userDao = UserDao();

  /// =========================
  /// 🔐 登录（不存在则自动注册）
  /// =========================
  Future<bool> login(String username, String password) async {
    final hash = _hash(password);
    // 1️⃣ 先查用户
    var user = await _userDao.login(username, hash);
    // 2️⃣ 不存在 → 自动创建
    if (user == null) {
      final newUser = User(username: username, passwordHash: hash);
      await _userDao.insertUser(newUser);
      user = newUser;
      Log.d("创建用户成功: $user");
    }
    return true;
  }

  /// =========================
  /// 🚪 退出登录
  /// =========================
  Future<void> logout() async {}

  /// =========================
  /// 🧠 简单 hash（本地用）
  /// =========================
  String _hash(String input) {
    return input.hashCode.toString();
  }
}
