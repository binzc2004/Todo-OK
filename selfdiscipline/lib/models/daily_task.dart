class DailyTask {
  int? id;
  int taskId;
  String taskName;
  String date;
  int status;

  DailyTask({
    this.id,
    required this.taskId,
    required this.taskName,
    required this.date,
    required this.status,
  });

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      taskId: map['task_id'],
      taskName: map['task_name'],
      date: map['date'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'task_name': taskName,
      'date': date,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'DailyTask(id: $id, taskId: $taskId, taskName: $taskName, date: $date, status: $status)';
  }
}
