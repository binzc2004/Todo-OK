import '../db/app_database.dart';
import '../db/db_safe.dart';
import '../models/daily_task.dart';
import '../utils/log.dart';

class DailyTaskDao {
  final dbProvider = AppDatabase.instance;

  /// ➕ 插入每日任务（加安全写）
  Future<int> insert(DailyTask task) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;
      return await db.insert('daily_task', task.toMap());
    });
  }

  /// 📅 查询某一天任务（不需要锁）
  Future<List<DailyTask>> getByDate(String date) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_task',
      where: 'date = ?',
      whereArgs: [date],
    );

    return result.map((e) => DailyTask.fromMap(e)).toList();
  }

  /// 🔍 按 taskId 查历史（不需要锁）
  Future<List<DailyTask>> getByTaskId(int taskId) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_task',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );

    return result.map((e) => DailyTask.fromMap(e)).toList();
  }

  /// ✏️ 更新状态（加安全写）
  Future<int> updateStatus(int id, int status) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;

      return await db.update(
        'daily_task',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 📊 范围查询（统计用，不需要锁）
  Future<List<DailyTask>> getByDateRange(String start, String end) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_task',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
    );

    return result.map((e) => DailyTask.fromMap(e)).toList();
  }

  /// 📋 查询所有任务（不需要锁）
  Future<List<DailyTask>> getAll() async {
    final db = await dbProvider.database;

    final result = await db.query('daily_task');
    Log.d("哈哈哈");
    Log.d(result);

    return result.map((e) => DailyTask.fromMap(e)).toList();
  }

  /// 📅 获取今天某个 task（单条）
  Future<DailyTask?> getTodayTaskById(int taskId, String date) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_task',
      where: 'task_id = ? AND date = ?',
      whereArgs: [taskId, date],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DailyTask.fromMap(result.first);
  }
}
