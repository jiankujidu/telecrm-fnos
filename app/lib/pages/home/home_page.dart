import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../api/call_task_api.dart';
import '../../api/report_api.dart';
import '../../models/call_task.dart';
import '../../models/report.dart';
import '../../providers/auth_provider.dart';

/// 首页 / 自动拨号页：SIM选择、搜索、四大入口、任务列表、悬浮拨打
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<CallTask> _tasks = [];
  ReportOverview? _report;
  bool _loading = false;

  static const _entries = [
    _Entry(icon: Icons.cloud_download_outlined, label: '大数据拓客'),
    _Entry(icon: Icons.near_me_outlined, label: '附近企业'),
    _Entry(icon: Icons.upload_file_outlined, label: '文件导入'),
    _Entry(icon: Icons.water_outlined, label: '号码公海'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadReport();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final p = await CallTaskApi.list(current: 1, size: 20);
      _tasks = p.records;
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReport() async {
    try {
      _report = await ReportApi.overview();
      if (mounted) setState(() {});
    } catch (_) {
      // 战报非阻断：失败时静默保留占位
    }
  }

  void _onEntryTap(String label) {
    switch (label) {
      case '文件导入':
        context.push('/import');
        break;
      case '大数据拓客':
        context.push('/bigdata');
        break;
      case '附近企业':
        context.push('/nearby');
        break;
      default:
        Fluttertoast.showToast(msg: '$label：功能开发中');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(user.isLoggedIn ? '${user.nickname} · 电销CRM' : '电销CRM'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadTasks(), _loadReport()]);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // 未连接服务器时给出醒目提示（离线体验态）
            if (user.isGuest) const _OfflineBanner(),
            // SIM 卡选择
            const ListTile(
              leading: Icon(Icons.sim_card_outlined),
              title: Text('使用本机SIM卡 1'),
              trailing: Icon(Icons.chevron_right),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // 四大入口
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: _entries
                    .map((e) => InkWell(
                          onTap: () => _onEntryTap(e.label),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFFE8F8F0),
                                child: Icon(e.icon, color: Color(Constants.primaryColorValue)),
                              ),
                              const SizedBox(height: 6),
                              Text(e.label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            _buildBattleReport(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('我的任务', style: Theme.of(context).textTheme.titleMedium),
            ),
            _buildTaskSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(Constants.primaryColorValue),
        onPressed: () => context.push('/dialer'),
        child: const Icon(Icons.call, color: Colors.white),
      ),
    );
  }

  Widget _buildBattleReport() {
    final r = _report;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF21C17A), Color(0xFF1AA86A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('我的今日战报',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                      onPressed: _loadReport,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (r == null)
                  const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metric(label: '今日拨打', value: '${r.todayCalled}'),
                          _Metric(label: '接通率', value: r.todayConnectRate, highlight: true),
                          _Metric(label: '加客户率', value: r.todayConvertRate, highlight: true),
                          _Metric(label: '平均时长', value: r.avgDurationText),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metric(label: '空号', value: '${r.todayEmpty}'),
                          _Metric(label: '未接通', value: '${r.todayNotAnswered}'),
                          _Metric(label: '加客户', value: '${r.todayAddCustomer}'),
                          _Metric(label: '历史总拨打', value: '${r.totalCalled}'),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('暂无任务，去「文件导入」创建', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => context.push('/import'),
              child: const Text('去导入'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = _tasks[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F8F0),
              child: Icon(Icons.assignment, color: Color(Constants.primaryColorValue)),
            ),
            title: Text(t.name ?? '未命名任务'),
            subtitle: Text('共 ${t.totalCount} 条 · 已拨打 ${t.calledCount} · 有效 ${t.validCount}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/dialer?taskId=${t.id}'),
          ),
        );
      },
    );
  }
}

class _Entry {
  final IconData icon;
  final String label;
  const _Entry({required this.icon, required this.label});
}

/// 战报指标单元
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Metric({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: highlight ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

/// 离线体验态提示条：点击去填服务器地址
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '未连接服务器，当前为离线体验，数据无法读取',
              style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('去设置',
                style: TextStyle(fontSize: 13, color: Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }
}
