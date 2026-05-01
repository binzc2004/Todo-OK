import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_database.dart';

class DevPage extends StatefulWidget {
  const DevPage({super.key});

  @override
  State<DevPage> createState() => _DevPageState();
}

class _DevPageState extends State<DevPage> {
  Map<String, List<Map<String, dynamic>>> dbData = {};
  Map<String, Object?> kvData = {};

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  /// =========================
  /// 加载全部数据
  /// =========================
  Future<void> loadAll() async {
    await _loadDB();
    await _loadKV();
    setState(() {});
  }

  /// =========================
  /// SQLite
  /// =========================
  Future<void> _loadDB() async {
    final db = await AppDatabase.instance.database;

    final tables = ['task', 'daily_task', 'daily_stats', 'user'];

    for (final t in tables) {
      final res = await db.query(t);
      dbData[t] = res;
    }
  }

  /// =========================
  /// KV
  /// =========================
  Future<void> _loadKV() async {
    final sp = await SharedPreferences.getInstance();

    kvData = {for (var k in sp.getKeys()) k: sp.get(k)};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧪 Dev Console"),
        actions: [
          IconButton(onPressed: loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            /// ======================
            /// SQLite
            /// ======================
            const Text(
              "📦 SQLite",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...dbData.entries.map((e) {
              return _buildTable(e.key, e.value);
            }),

            const SizedBox(height: 20),

            /// ======================
            /// KV
            /// ======================
            const Text(
              "🔑 SharedPreferences",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildKV(),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// 表 UI
  /// =========================
  Widget _buildTable(String name, List<Map<String, dynamic>> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text("$name  (${data.length})"),

        children: data.isEmpty
            ? [const Padding(padding: EdgeInsets.all(12), child: Text("空数据"))]
            : data.map((row) => _buildRow(row)).toList(),
      ),
    );
  }

  /// =========================
  /// 单条数据美化
  /// =========================
  Widget _buildRow(Map<String, dynamic> row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: row.entries.map((e) {
            return Text("${e.key}: ${e.value}");
          }).toList(),
        ),
      ),
    );
  }

  /// =========================
  /// KV UI
  /// =========================
  Widget _buildKV() {
    return Card(
      child: ExpansionTile(
        title: Text("KV (${kvData.length})"),
        children: kvData.entries.map((e) {
          return ListTile(title: Text(e.key), subtitle: Text("${e.value}"));
        }).toList(),
      ),
    );
  }
}
