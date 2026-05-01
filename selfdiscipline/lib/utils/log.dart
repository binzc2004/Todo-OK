import 'package:flutter/foundation.dart';

class Log {
  static void d(Object? msg) {
    debugPrint("APP_LOG: $msg");
  }
}
