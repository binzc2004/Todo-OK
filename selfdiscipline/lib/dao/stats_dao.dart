import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../db/db_safe.dart';
import '../models/daily_stats.dart';

class StatsDao {
  final dbProvider = AppDatabase.instance;

  /// ➕ 插入或更新统计（核心）
  Future<void> upsertStats(DailyStats stats) async {
    return await DbSafe.write(() async {
      final db = await dbProvider.database;

      await db.insert(
        'daily_stats',
        stats.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// 📅 查询某天统计（读，不用锁）
  Future<DailyStats?> getByDate(String date) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (result.isNotEmpty) {
      return DailyStats.fromMap(result.first);
    }
    return null;
  }

  /// 📊 查询范围统计（读，不用锁）
  Future<List<DailyStats>> getRange(String start, String end) async {
    final db = await dbProvider.database;

    final result = await db.query(
      'daily_stats',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
    );

    return result.map((e) => DailyStats.fromMap(e)).toList();
  }
}
