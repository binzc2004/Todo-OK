class DateUtilsHelper {
  static String format(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  static DateTime? parse(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  static String today() {
    return format(DateTime.now());
  }
}
