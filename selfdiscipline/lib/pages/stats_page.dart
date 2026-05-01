import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';

import '../models/daily_stats.dart';
import '../services/stats_service.dart';
import '../dao/daily_task_dao.dart';
import '../utils/date_utils.dart';
import '../const/Type.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final StatsService _statsService = StatsService();
  final DailyTaskDao _taskDao = DailyTaskDao();

  DateTime currentMonth = DateTime.now();
  DateTime? rangeStart;
  DateTime? rangeEnd;

  List<DailyStats> rangeData = [];
  List<DailyStats> monthData = []; // ⭐ 新增：月数据（修复关键）

  @override
  void initState() {
    super.initState();
    loadMonthData();
    loadWeekData();
  }

  // =========================
  // 📊 月数据（修复日历完成率）
  // =========================
  Future<void> loadMonthData() async {
    final start = DateTime(currentMonth.year, currentMonth.month, 1);

    final end = DateTime(
      currentMonth.year,
      currentMonth.month,
      DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month),
    );

    final data = await _statsService.getRangeStats(
      DateUtilsHelper.format(start),
      DateUtilsHelper.format(end),
    );

    setState(() {
      monthData = data; // ⭐ 关键：用于日历
    });
  }

  // =========================
  // 📊 默认7天图表
  // =========================
  Future<void> loadWeekData() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));

    final data = await _statsService.getRangeStats(
      DateUtilsHelper.format(start),
      DateUtilsHelper.format(end),
    );

    setState(() {
      rangeData = data;
      rangeStart = start;
      rangeEnd = end;
    });
  }

  // =========================
  // 📌 点击日历
  // =========================
  Future<void> showDayDetail(DateTime date) async {
    final key = DateUtilsHelper.format(date);
    final tasks = await _taskDao.getByDate(key);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("$key 任务情况"),
          content: tasks.isEmpty
              ? const Text("空空如也 😴")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    itemBuilder: (_, index) {
                      final t = tasks[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.taskName),
                        trailing: Text(
                          DoType.toText(t.status),
                          style: TextStyle(
                            color: DoType.color(t.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("关闭"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // 📅 月选择
  // =========================
  Future<void> pickMonth() async {
    int tempYear = currentMonth.year;
    int tempMonth = currentMonth.month;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text("取消"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text("确定"),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          currentMonth = DateTime(tempYear, tempMonth);
                        });
                        loadMonthData(); // ⭐ 关键修复
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => tempYear = 2020 + i,
                        children: List.generate(
                          50,
                          (i) => Center(child: Text("${2020 + i}年")),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => tempMonth = i + 1,
                        children: List.generate(
                          12,
                          (i) => Center(child: Text("${i + 1}月")),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // 📆 范围选择（修复）
  // =========================
  Future<void> pickRange() async {
    final result = await showDateRangePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      final data = await _statsService.getRangeStats(
        DateUtilsHelper.format(result.start),
        DateUtilsHelper.format(result.end),
      );

      setState(() {
        rangeStart = result.start;
        rangeEnd = result.end;
        rangeData = data;
      });
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(
      currentMonth.year,
      currentMonth.month,
    );

    final maxValue = rangeData.isEmpty
        ? 1.0
        : rangeData.map((e) => e.completionRate).reduce(max);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("统计"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // =========================
          // 月份
          // =========================
          Center(
            child: GestureDetector(
              onTap: pickMonth,
              child: Text(
                "${currentMonth.year}年${currentMonth.month}月",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // =========================
          // 日历（修复：完成率恢复）
          // =========================
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (_, index) {
              final day = index + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final key = DateUtilsHelper.format(date);

              final item = monthData.firstWhere(
                (e) => e.date == key,
                orElse: () => DailyStats(
                  date: key,
                  total: 0,
                  finished: 0,
                  skipped: 0,
                  completionRate: 0,
                ),
              );

              return GestureDetector(
                onTap: () => showDayDetail(date),
                child: buildDayCell(day, item.completionRate),
              );
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // 范围选择（修复）
          // =========================
          GestureDetector(
            onTap: pickRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rangeStart == null
                    ? "选择范围"
                    : "${DateUtilsHelper.format(rangeStart!)} ~ ${DateUtilsHelper.format(rangeEnd!)}",
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // 图表（保留 + 自动）
          // =========================
          Container(
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: rangeData.isEmpty
                ? const Center(child: Text("暂无数据"))
                : (rangeData.length > 14
                      ? buildLineChart(rangeData)
                      : buildBarChart(rangeData)),
          ),
        ],
      ),
    );
  }

  // =========================
  // 📊 柱状图
  // =========================
  Widget buildBarChart(List<DailyStats> data) {
    final maxValue = data.map((e) => e.completionRate).fold(0.0, max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: maxValue == 0
                    ? 0
                    : (item.completionRate / maxValue) * 150,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.date.split("-").last,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // 📈 折线图
  // =========================
  Widget buildLineChart(List<DailyStats> data) {
    final maxValue = data.map((e) => e.completionRate).fold(0.0, max);

    return CustomPaint(
      painter: _LinePainter(data, maxValue),
      child: Container(),
    );
  }

  // =========================
  // 📅 日历格子
  // =========================
  Widget buildDayCell(int day, double value) {
    final percent = (value * 100).toInt();

    Color color;
    if (value > 0.7) {
      color = Colors.green;
    } else if (value > 0.3) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$day"),
          Text("$percent%", style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

// =========================
// 📈 折线 painter
// =========================
class _LinePainter extends CustomPainter {
  final List<DailyStats> data;
  final double maxValue;

  _LinePainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()..color = Colors.blue;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height -
          (data[i].completionRate / (maxValue == 0 ? 1 : maxValue)) *
              size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
