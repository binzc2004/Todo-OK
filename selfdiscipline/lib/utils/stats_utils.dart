class StatsUtils {
  static double rate(int total, int finished) {
    if (total == 0) return 0;
    return finished / total;
  }
}
