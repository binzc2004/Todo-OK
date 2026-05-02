import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'db/app_database.dart';
import 'workers/work_manager.dart';
import 'services/notification/notification_service.dart';
import 'utils/permission_util.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_config.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// dev模式清理
  if (AppConfig.devMode) {
    // final sp = await SharedPreferences.getInstance();
    // await sp.clear();
    // await AppDatabase.instance.reset();
    // await AppDatabase.instance.seedFakeData();
  }

  /// DB
  await AppDatabase.instance.database;

  /// 权限
  await PermissionUtil.requestAll();

  /// 通知
  await NotificationService.init();

  /// worker（只初始化，不启动任务）
  await WorkManagerService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',

      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),

      home: const HomePage(),
    );
  }
}
