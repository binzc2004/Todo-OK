import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_database.dart';
import '../utils/log.dart';
import 'dart:typed_data';

class JsonBackup {
  static Future<String?> exportJson() async {
    final db = await AppDatabase.instance.database;

    final user = await db.query('user');
    final task = await db.query('task');
    final dailyTask = await db.query('daily_task');
    final stats = await db.query('daily_stats');

    final data = {
      "user": user.isNotEmpty ? user.first : null,
      "task": task,
      "daily_task": dailyTask,
      "daily_stats": stats,
    };

    final jsonStr = const JsonEncoder.withIndent("  ").convert(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    final path = await FilePicker.saveFile(
      dialogTitle: "保存备份文件",
      fileName: "backup.json",
      bytes: bytes, // ⭐必须
    );

    if (path == null) return null;

    return path;
  }

  static Future<void> importJson(PlatformFile platformFile) async {
    final filePath = platformFile.path;
    if (filePath == null) {
      throw Exception("文件路径为空");
    }

    final content = await File(filePath).readAsString();
    final data = jsonDecode(content);

    // 🔥 1. 重建数据库
    await AppDatabase.instance.reset();
    final db = await AppDatabase.instance.database;

    // =========================
    // 👤 user
    // =========================
    if (data['user'] != null) {
      final userMap = Map<String, dynamic>.from(data['user']);
      userMap.remove('id'); // ⭐关键修复
      await db.insert('user', userMap);
    }

    // =========================
    // 📦 task
    // =========================
    for (final item in (data['task'] ?? [])) {
      final map = Map<String, dynamic>.from(item);
      map.remove('id'); // ⭐关键修复
      await db.insert('task', map);
    }

    // =========================
    // 📅 daily_task
    // =========================
    for (final item in (data['daily_task'] ?? [])) {
      final map = Map<String, dynamic>.from(item);
      map.remove('id'); // ⭐关键修复
      await db.insert('daily_task', map);
    }

    // =========================
    // 📊 stats
    // =========================
    for (final item in (data['daily_stats'] ?? [])) {
      final map = Map<String, dynamic>.from(item);
      map.remove('id'); // ⭐关键修复
      await db.insert('daily_stats', map);
    }

    // =========================
    // 🔐 自动登录
    // =========================
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("login", true);

    final user = data['user'];
    if (user != null) {
      await prefs.setString("username", user['username']);
    }

    Log.d("导入成功 + 数据恢复完成");
  }
}
