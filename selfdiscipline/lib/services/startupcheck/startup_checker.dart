import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../db/app_database.dart';
import '../../utils/date_utils.dart';
import '../notification/sound_service.dart';

class StartupChecker {
  static Future<void> check(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final db = await AppDatabase.instance.database;

    final today = DateUtilsHelper.today();

    // =========================
    // KV：鼓励是否今日屏蔽
    // =========================
    final ignoreEncourage = prefs.getString("ignore_encourage_date");

    // =========================
    // DB：最近2天完成率
    // =========================
    final list = await db.query('daily_stats', orderBy: 'date DESC', limit: 2);

    bool last2Low = false;

    if (list.length == 2) {
      final r1 = (list[0]['completion_rate'] as num?)?.toDouble() ?? 0;
      final r2 = (list[1]['completion_rate'] as num?)?.toDouble() ?? 0;
      last2Low = (r1 < 0.5 && r2 < 0.5);
    }

    // =========================
    // 😈 嘲讽（永远优先 + 永远弹）
    // =========================
    if (last2Low) {
      _showMock(context);
      return; // 直接结束
    }

    // =========================
    // 🎉 鼓励（可屏蔽）
    // =========================
    final streak = prefs.getInt("streak_days") ?? 0;

    if (streak >= 3) {
      if (ignoreEncourage == today) return;

      _showEncourage(context, prefs, today, streak);
    }
  }

  // =========================
  // 😈 嘲讽弹窗（无法屏蔽）
  // =========================
  static void _showMock(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("系统提示"),
          content: const Text("连续两天完成率低于50%，能不能自律一点？？？"),
          actions: [
            TextButton(
              onPressed: () async{
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("你想的美,你个废物东西")));
                await SoundService.playOnce();
              },
              child: const Text("今日不再弹出"),
            ),
            TextButton(
              onPressed: () async {
                await SoundService.stop();
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("关闭"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // 🎉 鼓励弹窗（可屏蔽）
  // =========================
  static void _showEncourage(
    BuildContext context,
    SharedPreferences prefs,
    String today,
    int streak,
  ) {
    bool dontShow = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("坚持打卡"),
              content: Text("你已经坚持 $streak 天了！"),
              actions: [
                Row(
                  children: [
                    Checkbox(
                      value: dontShow,
                      onChanged: (v) => setState(() => dontShow = v!),
                    ),
                    const Text("今日不再弹出"),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    if (dontShow) {
                      await prefs.setString("ignore_encourage_date", today);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
