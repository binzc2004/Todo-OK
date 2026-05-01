import 'package:sqflite/sqflite.dart';
import '../utils/log.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static Database? _db;

  /// =========================
  /// 📦 获取数据库
  /// =========================
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  /// =========================
  /// 🏗 初始化数据库
  /// =========================
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo_app.db');

    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// =========================
  /// 🧱 建表
  /// =========================
  Future<void> _createDB(Database db, int version) async {
    // 🥇 task
    await db.execute('''
      CREATE TABLE task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT,
        time_of_day TEXT, -- ✅ 新增
        interval_minutes INTEGER,
        rule_type INTEGER NOT NULL,
        rule_config TEXT,
        description TEXT
      );
    ''');

    // 🥈 daily_task
    await db.execute('''
      CREATE TABLE daily_task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        task_name TEXT,
        date TEXT,
        status INTEGER
      )
    ''');

    // 🥉 user
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        password_hash TEXT
      )
    ''');

    // 🏅 daily_stats
    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE,
        total INTEGER,
        finished INTEGER,
        skipped INTEGER,
        completion_rate REAL
      )
    ''');
  }

  Future<void> seedFakeData() async {
    final db = await database;

    Log.d("🌱 插入测试数据（精简版）");

    /// =========================
    /// 👤 user（可选）
    /// =========================
    await db.insert('user', {
      'username': 'debug_user',
      'password_hash': '123456',
    });

    /// =========================
    /// 📌 task（只有一个：健身）
    /// =========================
    await db.insert('task', {
      'name': '🏋️ 健身',
      'start_date': '2026-01-01',
      'time_of_day': '08:00',
      'interval_minutes': 1, // ✅ 1分钟提醒
      'rule_type': 0,
      'rule_config': '{"weekdays":[1,2,3,4,5,6,7]}', // 每天
      'description': '每天健身打卡',
    });

    /// =========================
    /// 📅 工具函数
    /// =========================
    String dayOffset(int offset) {
      final d = DateTime.now().add(Duration(days: offset));
      return "${d.year.toString().padLeft(4, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.day.toString().padLeft(2, '0')}";
    }

    /// =========================
    /// 📌 daily_task（过去3天，全部完成）
    /// =========================
    Log.d("📌 插入 daily_task（过去3天，100%完成）");

    for (int i = -3; i <= -1; i++) {
      final date = dayOffset(i);

      await db.insert('daily_task', {
        'task_id': 1,
        'task_name': '🏋️ 健身',
        'date': date,
        'status': 1, // ✅ 全部完成
      });
    }

    /// =========================
    /// 📊 daily_stats（过去3天 100%）
    /// =========================
    Log.d("📊 插入 daily_stats（100%完成率）");

    for (int i = -3; i <= -1; i++) {
      final date = dayOffset(i);

      await db.insert('daily_stats', {
        'date': date,
        'total': 1,
        'finished': 1,
        'skipped': 0,
        'completion_rate': 0.0, // ✅ 100%
      });
    }

    Log.d("🌱 测试数据插入完成（精简版）");
  }

  /// =========================
  /// 🧹 删除数据库（调试用）
  /// =========================
  Future<void> reset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo_app.db');
    await deleteDatabase(path);

    _db = null;
  }
}
