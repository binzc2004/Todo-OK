import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../utils/log.dart';
import 'vibration_service.dart';
import 'sound_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 初始化
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (res) async {
        await SoundService.startLoop();
        await VibrationService.startLoop();
      },
    );

    Log.d("🔔 Notification 初始化完成");
  }

  /// 发送通知（✔ 正确版本）
  static Future<void> show({String? title, String? body}) async {
    const androidDetails = AndroidNotificationDetails(
      'todo_channel',
      'Todo Notifications',
      channelDescription: '任务提醒通知',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // 🔥 关键：亮屏
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _generateId(),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static int _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final rand = Random().nextInt(1000); // 0~999
    return now * 1000 + rand;
  }
}
