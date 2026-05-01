import '../dao/stats_dao.dart';
import '../models/daily_stats.dart';
import '../utils/date_utils.dart';
import '../utils/stats_utils.dart';

class StatsService {
  final StatsDao _dao = StatsDao();

  /// =========================
  /// 📊 获取某一天统计（保证不为 null）
  /// =========================
  Future<DailyStats> getDayStats(String date) async {
    final res = await _dao.getByDate(date);

    if (res != null) return res;

    /// 🔥 没有数据返回默认值（避免 UI null 判断）
    return DailyStats(
      date: date,
      total: 0,
      finished: 0,
      skipped: 0,
      completionRate: 0,
    );
  }

  /// =========================
  /// 📅 获取区间统计（图表用）
  /// =========================
  Future<List<DailyStats>> getRangeStats(String start, String end) async {
    final raw = await _dao.getRange(start, end);

    /// 🔥 map 加速查找
    final Map<String, DailyStats> map = {for (final e in raw) e.date: e};

    List<DailyStats> result = [];

    DateTime s = DateTime.parse(start);
    DateTime e = DateTime.parse(end);

    while (!s.isAfter(e)) {
      final key = DateUtilsHelper.format(s);

      result.add(
        map[key] ??
            DailyStats(
              date: key,
              total: 0,
              finished: 0,
              skipped: 0,
              completionRate: 0,
            ),
      );

      s = s.add(const Duration(days: 1));
    }

    return result;
  }

  /// =========================
  /// 📌 更新统计（核心入口）
  /// =========================
  Future<void> updateStats({
    required String date,
    required int total,
    required int finished,
    required int skipped,
  }) async {
    final rate = StatsUtils.rate(total, finished);

    final stats = DailyStats(
      date: date,
      total: total,
      finished: finished,
      skipped: skipped,
      completionRate: rate,
    );

    await _dao.upsertStats(stats);
  }

  /// =========================
  /// 📌 增加完成任务（常用）
  /// =========================
  Future<void> addFinished(String date) async {
    final old = await getDayStats(date);

    await updateStats(
      date: date,
      total: old.total + 1,
      finished: old.finished + 1,
      skipped: old.skipped,
    );
  }

  /// =========================
  /// 📌 增加未完成/跳过任务
  /// =========================
  Future<void> addSkipped(String date) async {
    final old = await getDayStats(date);

    await updateStats(
      date: date,
      total: old.total + 1,
      finished: old.finished,
      skipped: old.skipped + 1,
    );
  }
}
