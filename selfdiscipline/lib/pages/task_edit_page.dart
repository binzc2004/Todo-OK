import 'package:flutter/material.dart';
import '../models/task.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../const/Type.dart';
class TaskEditPage extends StatefulWidget {
  final Task? task;

  const TaskEditPage({super.key, this.task});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final intervalController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? startDate;
  TimeOfDay? timeOfDay;

  /// ✅ 默认规则
  int ruleType = RuleType.weekly;

  List<int> weekdays = [];
  int oddEven = 1;
  int intervalDays = 1;

  @override
  void initState() {
    super.initState();

    final t = widget.task;
    if (t == null) return;

    nameController.text = t.name;
    intervalController.text = (t.intervalMinutes ?? 30).toString();
    descriptionController.text = t.description ?? "";

    startDate = _parseDate(t.startDate);

    /// ⏰ 解析 time_of_day
    if (t.timeOfDay != null) {
      final parts = t.timeOfDay!.split(":");
      timeOfDay = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    /// ✅ 规则类型
    ruleType = t.ruleType;

    /// ✅ 解析 ruleConfig
    if (t.ruleConfig != null && t.ruleConfig!.isNotEmpty) {
      final json = jsonDecode(t.ruleConfig!);

      if (ruleType == RuleType.weekly) {
        weekdays = List<int>.from(json['weekdays'] ?? []);
      } else if (ruleType == RuleType.oddEven) {
        oddEven = json['oddEven'] ?? 1;
      } else if (ruleType == RuleType.interval) {
        intervalDays = json['intervalDays'] ?? 1;
      }
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// ✅ 构建规则配置
  String buildRuleConfig() {
    Map<String, dynamic> config;

    if (ruleType == RuleType.weekly) {
      config = {"weekdays": weekdays};
    } else if (ruleType == RuleType.oddEven) {
      config = {"oddEven": oddEven};
    } else {
      config = {"intervalDays": intervalDays};
    }

    return jsonEncode(config);
  }

  void save() {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id,
      name: nameController.text.trim(),
      startDate: startDate == null ? null : _fmt(startDate!),

      /// ⏰ 写入 time_of_day
      timeOfDay: timeOfDay == null
          ? null
          : "${timeOfDay!.hour.toString().padLeft(2, '0')}:${timeOfDay!.minute.toString().padLeft(2, '0')}",

      intervalMinutes: int.tryParse(intervalController.text),

      ruleType: ruleType,
      ruleConfig: buildRuleConfig(),

      description: descriptionController.text.trim(),
    );

    Navigator.pop(context, task);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: startDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: timeOfDay ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => timeOfDay = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "编辑任务" : "新增任务")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// 任务名称
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "任务名称"),
              validator: (v) => (v == null || v.isEmpty) ? "请输入任务名称" : null,
            ),

            const SizedBox(height: 12),

            /// 描述
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "详细描述",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 间隔分钟
            TextFormField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "间隔分钟"),
            ),

            const SizedBox(height: 12),

            /// 📅 开始日期
            TextButton(
              onPressed: pickDate,
              child: Text(startDate == null ? "选择开始日期" : _fmt(startDate!)),
            ),

            /// ⏰ 时间
            TextButton(
              onPressed: pickTime,
              child: Text(
                timeOfDay == null ? "选择触发时间" : timeOfDay!.format(context),
              ),
            ),

            const Divider(),

            const Text("规则"),

            /// 🟦 周规则
            RadioListTile(
              value: RuleType.weekly,
              groupValue: ruleType,
              onChanged: (v) => setState(() => ruleType = v!),
              title: const Text("按周"),
            ),

            if (ruleType == RuleType.weekly)
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  return FilterChip(
                    label: Text("周$day"),
                    selected: weekdays.contains(day),
                    onSelected: (s) {
                      setState(() {
                        s ? weekdays.add(day) : weekdays.remove(day);
                      });
                    },
                  );
                }),
              ),

            /// 🟨 单双日
            RadioListTile(
              value: RuleType.oddEven,
              groupValue: ruleType,
              onChanged: (v) => setState(() => ruleType = v!),
              title: const Text("单双日"),
            ),

            if (ruleType == RuleType.oddEven)
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("奇"),
                    selected: oddEven == 1,
                    onSelected: (_) => setState(() => oddEven = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("偶"),
                    selected: oddEven == 2,
                    onSelected: (_) => setState(() => oddEven = 2),
                  ),
                ],
              ),

            /// 🟩 每N天
            RadioListTile(
              value: RuleType.interval,
              groupValue: ruleType,
              onChanged: (v) => setState(() => ruleType = v!),
              title: const Text("每N天"),
            ),

            if (ruleType == RuleType.interval)
              Row(
                children: [
                  const Text("间隔："),
                  const SizedBox(width: 8),

                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: intervalDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        intervalDays = int.tryParse(v) ?? 1;
                      },
                    ),
                  ),

                  const SizedBox(width: 8),
                  const Text("天"),
                ],
              ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: save, child: const Text("保存")),
          ],
        ),
      ),
    );
  }
}