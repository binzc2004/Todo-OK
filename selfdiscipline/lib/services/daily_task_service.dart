import '../dao/daily_task_dao.dart';
import '../models/daily_task.dart';
import '../utils/date_utils.dart';
import '../const/Type.dart';
class DailyTaskService {
  final DailyTaskDao _dao = DailyTaskDao();

  /// =========================
  /// 📦 获取所有任务
  /// =========================
  Future<List<DailyTask>> getAll() async {
    return await _dao.getAll();
  }

  /// =========================
  /// ➕ 创建每日任务
  /// =========================
  Future<int> addDailyTask(DailyTask task) async {
    return await _dao.insert(task);
  }

  /// =========================
  /// 📦 获取某天所有任务
  /// =========================
  Future<List<DailyTask>> getByDate(String date) async {
    return await _dao.getByDate(date);
  }

  /// =========================
  /// 📦 获取某个任务的历史记录
  /// =========================
  Future<List<DailyTask>> getByTaskId(int taskId) async {
    return await _dao.getByTaskId(taskId);
  }

  /// =========================
  /// ✏️ 更新状态（完成/未完成/偷懒）
  /// =========================
  Future<void> updateStatus(int id, int status) async {
    await _dao.updateStatus(id, status);
  }

  /// =========================
  /// 🔥 批量插入（用于“自动生成每日任务”）
  /// =========================
  Future<void> batchInsert(List<DailyTask> list) async {
    for (final item in list) {
      await _dao.insert(item);
    }
  }

  /// =========================
  /// 📊 统计某天完成情况
  /// =========================
  Future<Map<String, int>> getDaySummary(String date) async {
    final list = await _dao.getByDate(date);

    int total = list.length;
    int finished = list.where((e) => e.status == 1).length;
    int skipped = list.where((e) => e.status == 2).length;

    return {"total": total, "finished": finished, "skipped": skipped};
  }

  Future<DailyTask?> getTodayTaskById(int taskId) async {
    return await _dao.getTodayTaskById(taskId, DateUtilsHelper.today());
  }

  /// =========================
  /// 📌 判断今天该任务是否已完成（done / skipped = 结束）
  /// =========================
  Future<bool> isTodayTaskFinished(int taskId) async {
    final task = await getTodayTaskById(taskId);

    if (task == null) {
      return false;
    }

    return task.status == DoType.done || task.status == DoType.skipped;
  }
}
