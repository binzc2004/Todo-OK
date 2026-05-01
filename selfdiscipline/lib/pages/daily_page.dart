import 'package:demo/services/task_service.dart';
import 'package:flutter/material.dart';

import '../utils/log.dart';
import '../models/daily_task.dart';
import '../services/daily_task_service.dart';
import '../utils/date_utils.dart';
import '../services/scheduler/task_generator.dart';
import '../const/Type.dart';
import '../services/scheduler/test.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  final DailyTaskService _service = DailyTaskService();
  final TaskService _taskService = TaskService();
  final TaskGenerator _generator = TaskGenerator();

  List<DailyTask> tasks = [];

  String get today => DateUtilsHelper.format(DateTime.now());

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  // =========================
  // 🔄 全量刷新
  // =========================
  Future<void> refreshData() async {
    _generator.refreshDailyTasks();

    final data = await _service.getByDate(today);

    Log.d("全局刷新今日任务");

    if (!mounted) return;

    setState(() {
      tasks = data;
    });
  }

  // =========================
  // ⚡ 状态更新（稳定版）
  // =========================
  Future<void> updateTaskStatus(int id, int status) async {
    await _service.updateStatus(id, status);

    if (!mounted) return;

    setState(() {
      tasks = tasks.map((t) {
        if (t.id == id) {
          return DailyTask(
            id: t.id,
            taskId: t.taskId,
            taskName: t.taskName,
            date: t.date,
            status: status,
          );
        }
        return t;
      }).toList();
    });
  }

  // =========================
  // 🧠 过滤
  // =========================
  List<DailyTask> get unCompleted =>
      tasks.where((t) => t.status == DoType.todo).toList();

  List<DailyTask> get completed =>
      tasks.where((t) => t.status != DoType.todo).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: GestureDetector(
          onLongPress: () async {
            await TestTask.start();
          },
          onDoubleTap: () async {
            await TestTask.stop();
          },
          child: const Text("任务管理"),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,

        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text(
              "未完成",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (unCompleted.isEmpty) const Text("暂无未完成任务"),

            ...unCompleted.map(buildTaskItem),

            const SizedBox(height: 20),

            const Text(
              "已完成",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (completed.isEmpty) const Text("暂无已完成任务"),

            ...completed.map(buildTaskItem),
          ],
        ),
      ),
    );
  }

  // =========================
  // 📌 单个任务卡片（关键：加 key）
  // =========================
  Widget buildTaskItem(DailyTask task) {
    return Card(
      key: ValueKey(task.id), // ⭐⭐⭐⭐⭐ 核心修复点

      margin: const EdgeInsets.symmetric(vertical: 6),

      child: ListTile(
        onTap: () => showTaskDetail(task),

        title: Text(
          task.taskName,
          style: TextStyle(
            decoration: task.status == DoType.todo
                ? null
                : TextDecoration.lineThrough,
          ),
        ),

        subtitle: Text(
          DoType.toText(task.status),
          style: TextStyle(color: DoType.color(task.status)),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => updateTaskStatus(task.id!, DoType.done),
            ),

            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => updateTaskStatus(task.id!, DoType.todo),
            ),

            IconButton(
              icon: const Icon(Icons.free_breakfast, color: Colors.orange),
              onPressed: () => updateTaskStatus(task.id!, DoType.skipped),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 📌 详情弹窗
  // =========================
  Future<void> showTaskDetail(DailyTask task) async {
    final detail = await _taskService.getTaskById(task.taskId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(task.taskName),

          content: detail == null
              ? const Text("暂无任务详细信息")
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📌 描述：${detail.description ?? '无'}"),
                    const SizedBox(height: 8),
                    Text("⏰ 时间：${detail.timeOfDay}"),
                    const SizedBox(height: 8),
                    Text("🔁 间隔：${detail.intervalMinutes} 分钟"),
                  ],
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
}
