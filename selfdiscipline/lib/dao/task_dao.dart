import '../db/app_database.dart';
import '../db/db_safe.dart';
import '../models/task.dart';

class TaskDao {
  final dbProvider = AppDatabase.instance;

  /// ➕ 新增任务（写操作加保护）
  Future<int> insertTask(Task task) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;
      return await db.insert('task', task.toMap());
    });
  }

  /// 📄 查询所有任务（读，不需要锁）
  Future<List<Task>> getAllTasks() async {
    final db = await dbProvider.database;

    final result = await db.query('task');
    return result.map((e) => Task.fromMap(e)).toList();
  }

  /// 🔍 按 ID 查询（读）
  Future<Task?> getTaskById(int id) async {
    final db = await dbProvider.database;

    final result = await db.query('task', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return Task.fromMap(result.first);
    }
    return null;
  }

  /// ✏️ 更新任务（写操作加保护）
  Future<int> updateTask(Task task) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;

      return await db.update(
        'task',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    });
  }

  /// ❌ 删除任务（写操作加保护）
  Future<int> deleteTask(int id) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;

      return await db.delete('task', where: 'id = ?', whereArgs: [id]);
    });
  }
}
