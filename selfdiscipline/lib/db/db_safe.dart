class DbSafe {
  static Future<T> write<T>(Future<T> Function() fn) async {
    for (int i = 0; i < 5; i++) {
      try {
        return await fn();
      } catch (e) {
        // 如果是锁，等一下再试
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    throw Exception("DB write failed after retries");
  }
}
