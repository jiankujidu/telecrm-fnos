import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/customer_api.dart';
import '../../models/customer.dart';
import '../../config/constants.dart';
import '../../services/dialer_service.dart';

/// 客户页：我的客户 / 团队客户 / 客户库（公海）
class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('客户'),
          actions: [
            IconButton(
              tooltip: '新增客户',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () async {
                final ok = await context.push<bool>('/customer/new');
                if (ok == true && context.mounted) {
                  // 新增成功后刷新（切 Tab 也会重新拉取）
                  ScaffoldMessenger.maybeOf(context);
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '我的客户'),
              Tab(text: '团队客户'),
              Tab(text: '客户库'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [
            _CustomerListTab(scope: 'mine'),
            _CustomerListTab(scope: 'team'),
            _CustomerListTab(scope: 'public'),
          ],
        ),
      ),
    );
  }
}

class _CustomerListTab extends StatefulWidget {
  final String scope;
  const _CustomerListTab({required this.scope});

  @override
  State<_CustomerListTab> createState() => _CustomerListTabState();
}

class _CustomerListTabState extends State<_CustomerListTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Customer>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Customer>> _load() async {
    final page = await CustomerApi.list(widget.scope, size: 100);
    return page.records;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final green = Color(Constants.primaryColorValue);
    return FutureBuilder<List<Customer>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败：${snap.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                TextButton(onPressed: _refresh, child: const Text('重试')),
              ],
            ),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('暂无客户数据', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('新增客户'),
                  onPressed: () async {
                    final ok = await context.push<bool>('/customer/new');
                    if (ok == true) _refresh();
                  },
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = list[i];
              final subtitle = [
                if (c.company != null && c.company!.isNotEmpty) c.company!,
                c.phone,
              ].join(' · ');
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F8F0),
                    child: Text(
                      (c.name ?? c.phone).isNotEmpty
                          ? (c.name ?? c.phone).substring(0, 1)
                          : '?',
                      style: TextStyle(color: green),
                    ),
                  ),
                  title: Text(c.name ?? '未知客户'),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '拨号',
                        icon: Icon(Icons.call, color: green),
                        onPressed: () async {
                          final r = await DialerService.call(c.phone);
                          if (r.message.isNotEmpty) {
                            // ignore: use_build_context_synchronously
                            _toast(r.message);
                          }
                          if (!r.ok && r.needPermission) {
                            await DialerService.openPermissionSettings();
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'detail') {
                            context.push('/customer/${c.id}');
                          } else if (v == 'edit') {
                            final ok = await context.push<bool>('/customer/${c.id}/edit');
                            if (ok == true) _refresh();
                          } else if (v == 'delete') {
                            await _confirmDelete(c);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'detail', child: Text('详情')),
                          PopupMenuItem(value: 'edit', child: Text('编辑画像')),
                          PopupMenuItem(value: 'delete', child: Text('删除')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => ctx.push('/customer/${c.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除客户'),
        content: Text('确认删除「${c.name ?? c.phone}」及其画像？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CustomerApi.remove(int.parse(c.id));
      _toast('已删除');
      await _refresh();
    } catch (e) {
      _toast('删除失败：$e');
    }
  }
}
