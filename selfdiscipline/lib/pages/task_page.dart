import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'task_edit_page.dart';
import '../const/Type.dart';
import 'dart:convert';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TaskService _service = TaskService();

  List<Task> tasks = [];
  int? openIndex;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final data = await _service.getAllTasks();
    setState(() {
      tasks = data;
    });
  }

  Future<void> goEditPage({Task? task}) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskEditPage(task: task)),
    );

    if (result == null) return;

    if (task == null) {
      await _service.addTask(result);
    } else {
      await _service.updateTask(result);
    }

    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _service.deleteTask(id);
    await loadTasks();
  }

  /// ✅ 规则转中文
  String getRuleText(Task task) {
    try {
      final config = task.ruleConfig != null
          ? jsonDecode(task.ruleConfig!)
          : {};

      switch (task.ruleType) {
        case RuleType.weekly:
          List list = config['weekdays'] ?? [];
          if (list.isEmpty) return "未设置";
          const names = ["一", "二", "三", "四", "五", "六", "日"];
          return list.map((e) => "周${names[e - 1]}").join(" ");

        case RuleType.oddEven:
          return config['oddEven'] == 1 ? "单日" : "双日";

        case RuleType.interval:
          return "每${config['intervalDays'] ?? 1}天";

        default:
          return "未知";
      }
    } catch (e) {
      return "错误";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text("任务管理"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          return SlideItem(
            key: ValueKey(task.id),
            task: task,
            ruleText: getRuleText(task),
            isOpen: openIndex == index,
            onOpen: () => setState(() => openIndex = index),
            onClose: () => setState(() => openIndex = null),
            onDelete: () => deleteTask(task.id!),
            onEdit: () => goEditPage(task: task),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => goEditPage(),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SlideItem extends StatefulWidget {
  final Task task;
  final String ruleText;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const SlideItem({
    super.key,
    required this.task,
    required this.ruleText,
    required this.isOpen,
    required this.onOpen,
    required this.onClose,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<SlideItem> {
  double offsetX = 0;

  @override
  void didUpdateWidget(covariant SlideItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen) offsetX = 0;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: 72,
      child: Stack(
        children: [
          /// ✅ 背景按钮（固定宽度，核心修复）
          Positioned.fill(
            child: Row(
              children: [
                Container(
                  width: 100,
                  alignment: Alignment.center,
                  color: Colors.red.withOpacity(0.1),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
                ),

                const Spacer(),

                Container(
                  width: 100,
                  alignment: Alignment.center,
                  color: Colors.blue.withOpacity(0.1),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: widget.onEdit,
                  ),
                ),
              ],
            ),
          ),

          /// ✅ 前景卡片
          GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                offsetX += d.delta.dx;
                offsetX = offsetX.clamp(-100, 100);
              });
            },
            onHorizontalDragEnd: (_) {
              offsetX.abs() > 50 ? widget.onOpen() : widget.onClose();
            },
            onTap: () {
              if (widget.isOpen) widget.onClose();
            },

            /// ✅ 长按详情恢复
            onLongPress: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(task.name),
                  content: buildDetail(task),
                ),
              );
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(
                widget.isOpen ? (offsetX > 0 ? 100 : -100) : offsetX,
                0,
                0,
              ),

              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),

                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [
                    /// 左侧
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            widget.ruleText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 右侧
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          task.startDate ?? "",
                          style: const TextStyle(fontSize: 12),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          task.timeOfDay ?? "--:--",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 长按详情
  Widget buildDetail(Task task) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("📌 任务名称: ${task.name}"),
        const SizedBox(height: 8),

        Text("🔁 执行规则: ${widget.ruleText}"),
        const SizedBox(height: 8),

        Text("📅 开始日期: ${task.startDate ?? '--'}"),
        const SizedBox(height: 6),

        Text("⏰ 触发时间: ${task.timeOfDay ?? '--'}"),
        const SizedBox(height: 6),

        Text("⏱ 间隔提醒: ${task.intervalMinutes ?? '--'} 分钟"),
        const SizedBox(height: 8),

        Text("📝 详细描述:"),
        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.description?.isNotEmpty == true ? task.description! : "无",
          ),
        ),
      ],
    );
  }
}
