import '../db/app_database.dart';
import '../models/user.dart';

class UserDao {
  final dbProvider = AppDatabase.instance;

  /// ➕ 注册用户
  Future<int> insertUser(User user) async {
    final db = await dbProvider.database;
    return await db.insert('user', user.toMap());
  }

  /// 🔍 根据用户名查询
  Future<User?> getUserByUsername(String username) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'user',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  /// 🔐 登录验证
  Future<User?> login(String username, String passwordHash) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'user',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }
}
