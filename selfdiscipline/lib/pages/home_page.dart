import 'package:flutter/material.dart';
import 'daily_page.dart';
import 'stats_page.dart';
import 'task_page.dart';
import 'profile_page.dart';

import '../services/scheduler/task_generator.dart';
import '../services/scheduler/daily_summarizer.dart';
import '../services/startupcheck/startup_checker.dart';
import '../services/startupcheck/permission_checker.dart';
import '../services/auth/auth_manager.dart';
import '../workers/work_manager.dart';
import '../utils/log.dart';
import '../services/notification/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLogin = false;

  List<Widget> get _pages => [
    const DailyPage(),
    const StatsPage(),
    const TaskPage(),
    ProfilePage(onLoginSuccess: _onLogin, onLogout: _onLogout),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// =========================
  /// 🚀 启动恢复状态（关键）
  /// =========================
  Future<void> _bootstrap() async {
    bool login = await AuthManager.isLoggedIn();
    _isLogin = login;
    setState(() {
      _currentIndex = login ? 0 : 3;
    });
    if (login) {
      _onLogin();
    }
  }

  /// =========================
  /// 🔐 登录后启动系统
  /// =========================
  Future<void> _onLogin() async {
    /// 1️⃣ 更新UI状态（关键）
    setState(() {
      _isLogin = true;
      _currentIndex = 0;
    });

    /// 2️⃣ 启动任务系统
    await TaskGenerator.start();
    await DailySummarizer.start();
    Log.d("登录启动！！！");
    NotificationService.show(title: "启动", body: "所有后台任务已启动");

    /// 3️⃣ startup check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await StartupPermissionDialog.checkAndShow(context);
      await StartupChecker.check(context);
    });
  }

  /// =========================
  /// 🚪 登出（核心）
  /// =========================
  Future<void> _onLogout() async {
    /// 1️⃣ 停止所有任务（关键）
    await TaskGenerator.stop();
    await DailySummarizer.stop();
    await WorkManagerService.cancelAll();
    Log.d("登出，停止后台任务");
    NotificationService.show(title: "停止", body: "后台任务已杀死！");

    /// 2️⃣ 更新UI状态
    setState(() {
      _isLogin = false;
      _currentIndex = 3;
    });
  }

  /// =========================
  /// 🧭 tab控制（防未登录）
  /// =========================
  void onTabTap(int index) {
    if (!_isLogin) {
      setState(() => _currentIndex = 3);
      return;
    }

    setState(() => _currentIndex = index);
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLogin
          ? _pages[_currentIndex]
          : ProfilePage(onLoginSuccess: _onLogin, onLogout: _onLogout),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: '今日'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '任务'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
