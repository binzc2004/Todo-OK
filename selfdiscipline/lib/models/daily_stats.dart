class DailyStats {
  int? id;
  String date;
  int total;
  int finished;
  int skipped;
  double completionRate;

  DailyStats({
    this.id,
    required this.date,
    required this.total,
    required this.finished,
    required this.skipped,
    required this.completionRate,
  });

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'],
      date: map['date'],
      total: map['total'],
      finished: map['finished'],
      skipped: map['skipped'],
      completionRate: map['completion_rate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total': total,
      'finished': finished,
      'skipped': skipped,
      'completion_rate': completionRate,
    };
  }
}
