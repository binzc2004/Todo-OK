import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

class StartupPermissionDialog {
  static const String _key = "startup_permission_dont_show_again";

  /// 检查是否需要弹窗（只在未设置时弹）
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool(_key) ?? false;

    if (dontShow) return;

    Future.microtask(() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _StartupPermissionDialog(),
      );
    });
  }

  static Future<void> setDontShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

class _StartupPermissionDialog extends StatefulWidget {
  const _StartupPermissionDialog();

  @override
  State<_StartupPermissionDialog> createState() =>
      _StartupPermissionDialogState();
}

class _StartupPermissionDialogState extends State<_StartupPermissionDialog> {
  bool dontShowAgain = false;

  /// ✅ 打开系统设置首页（关键修改点）
  Future<void> openSystemSettings() async {
    if (!Platform.isAndroid) return;

    final intent = AndroidIntent(action: 'android.settings.SETTINGS');

    await intent.launch();
  }

  Future<void> finish() async {
    if (dontShowAgain) {
      await StartupPermissionDialog.setDontShowAgain();
    }
    Navigator.pop(context);
  }

  Widget _step(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("开启后台提醒权限"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("为了保证你的 Todo 提醒在后台和锁屏状态下正常工作，请在系统设置中手动开启相关权限："),

            const SizedBox(height: 12),

            const Text(
              "📌 建议检查的内容：",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            _step("自启动权限（允许应用开机/后台启动）"),
            _step("后台运行权限（避免被系统清理）"),
            _step("电池优化限制（允许后台活动）"),

            const SizedBox(height: 12),

            const Text(
              "📍 操作路径提示：",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            _step("设置 → 权限管理 → 找到本应用"),
            _step("进入后检查：权限 / 电池 / 后台运行"),

            const SizedBox(height: 12),

            const Text(
              "⚠️ 如果不设置，可能导致无法收到提醒",
              style: TextStyle(color: Colors.redAccent),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (v) {
                    setState(() {
                      dontShowAgain = v ?? false;
                    });
                  },
                ),
                const Expanded(child: Text("我已了解，不再提示")),
              ],
            ),
          ],
        ),
      ),

      actions: [
        TextButton(onPressed: finish, child: const Text("知道了")),

        ElevatedButton(
          onPressed: openSystemSettings,
          child: const Text("打开系统设置"),
        ),
      ],
    );
  }
}
