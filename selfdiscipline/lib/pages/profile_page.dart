import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth/auth_manager.dart';
import '../utils/json_backup.dart';
import '../services/devmode/dev_mode_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dev_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onLogout;

  const ProfilePage({super.key, this.onLoginSuccess, this.onLogout});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoggedIn = false;

  String username = "";
  String password = "";

  DateTime installDate = DateTime.now();

  /// 🧪 Dev Mode
  bool _devMode = false;
  int _devTapCount = 0;

  @override
  void initState() {
    super.initState();
    initData();
  }

  /// =========================
  /// 初始化
  /// =========================
  Future<void> initData() async {
    final sp = await SharedPreferences.getInstance();
    isLoggedIn = await AuthManager.isLoggedIn();
    username = await AuthManager.currentUser() ?? "";
    final install = sp.getString("install_date");
    if (install == null) {
      installDate = DateTime.now();
      await sp.setString("install_date", installDate.toIso8601String());
    } else {
      installDate = DateTime.parse(install);
    }
    _devMode = await DevModeService.isEnabled();
    setState(() {});
  }

  /// =========================
  /// 登录（走 AuthManager）
  /// =========================
  Future<void> login() async {
    if (username.isEmpty || password.isEmpty) return;
    final success = await AuthManager.login(username, password);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("登录失败")));
      return;
    }
    setState(() {
      isLoggedIn = true;
    });
    widget.onLoginSuccess?.call();
  }

  /// =========================
  /// 登出
  /// =========================
  Future<void> logout() async {
    await AuthManager.logout();
    setState(() {
      isLoggedIn = false;
      username = "";
      password = "";
    });
    widget.onLogout?.call();
  }

  /// =========================
  /// 导入 + 自动登录
  /// =========================
  void importData() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;

    try {
      await JsonBackup.importJson(result.files.first);

      /// 🔥 导入后自动登录（关键）
      final sp = await SharedPreferences.getInstance();
      final importedUser = sp.getString("username") ?? "import_user";
      await AuthManager.login(importedUser, ""); // 密码无所谓，本地逻辑
      setState(() {
        isLoggedIn = true;
        username = importedUser;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("导入成功并自动登录")));
      widget.onLoginSuccess?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("导入失败：$e")));
    }
  }

  /// =========================
  /// 导出
  /// =========================
  void exportData() async {
    final path = await JsonBackup.exportJson();
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(title: const Text("导出成功"), content: Text("文件路径:\n$path")),
    );
  }

  /// =========================
  /// 安装天数
  /// =========================
  int get installDays {
    return DateTime.now().difference(installDate).inDays;
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text("我的"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          /// 👤 用户模块
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoggedIn ? buildLoggedIn() : buildLoginForm(),
          ),

          const SizedBox(height: 20),

          /// 📊 安装统计
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "应用统计",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("安装天数"), Text("$installDays 天")],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 📦 操作按钮
          if (isLoggedIn)
            ElevatedButton(onPressed: exportData, child: const Text("导出数据"))
          else
            ElevatedButton(onPressed: importData, child: const Text("导入数据并登录")),

          const SizedBox(height: 10),

          if (isLoggedIn)
            TextButton(onPressed: logout, child: const Text("退出登录")),
        ],
      ),
    );
  }

  /// =========================
  /// 👇 用户区域（Dev入口）
  /// =========================
  Widget buildLoggedIn() {
    return GestureDetector(
      onTap: () async {
        _devTapCount++;

        if (_devTapCount < 5) return;

        _devTapCount = 0;

        final enabled = await DevModeService.toggle();
        _devMode = enabled;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enabled ? "🧪 开发者模式已开启" : "🚫 开发者模式已关闭")),
        );

        setState(() {});
      },
      child: _devMode ? _buildDevPanel() : _buildNormalUser(),
    );
  }

  Widget _buildNormalUser() {
    return Text("👤 已登录：$username");
  }

  Widget _buildDevPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "👤 已登录：$username",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DevPage()),
            );
          },
          child: const Text("🚀 进入开发者页面"),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            await DevModeService.set(false);
            _devMode = false;
            setState(() {});
          },
          child: const Text("🚫 关闭开发者模式"),
        ),
      ],
    );
  }

  /// =========================
  /// 登录 UI
  /// =========================
  Widget buildLoginForm() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: "账号"),
          onChanged: (v) => username = v,
        ),
        TextField(
          decoration: const InputDecoration(labelText: "密码"),
          obscureText: true,
          onChanged: (v) => password = v,
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: login, child: const Text("登录")),
      ],
    );
  }
}
