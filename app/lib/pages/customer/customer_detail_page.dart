import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../api/customer_api.dart';
import '../../api/call_record_api.dart';
import '../../api/follow_up_api.dart';
import '../../models/customer.dart';
import '../../models/call_record.dart';
import '../../models/follow_up.dart';
import '../../services/dialer_service.dart';
import '../../config/constants.dart';

/// 客户详情页：基本信息 + 通话记录 + 回访时间线（三块聚合）
class CustomerDetailPage extends StatefulWidget {
  final int customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final results = await Future.wait([
      CustomerApi.detail(widget.customerId),
      CallRecordApi.byCustomer(widget.customerId),
      FollowUpApi.list(customerId: widget.customerId),
    ]);
    return _DetailData(
      customer: results[0] as Customer,
      records: results[1] as List<CallRecordItem>,
      followUps: results[2] as List<FollowUp>,
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除客户'),
        content: const Text('确认删除该客户及其画像？删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await CustomerApi.remove(widget.customerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  /// 拨打该客户电话
  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) return;
    final r = await DialerService.call(phone);
    if (!mounted) return;
    if (r.message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
    }
    if (!r.ok && r.needPermission) {
      await DialerService.openPermissionSettings();
      return;
    }
    if (r.ok) {
      // 累计拨打次数
      try {
        await CustomerApi.touchCall(widget.customerId);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客户详情'),
        actions: [
          IconButton(
            tooltip: '编辑画像',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final ok = await context.push<bool>('/customer/${widget.customerId}/edit');
              if (ok == true && mounted) setState(() => _future = _load());
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') await _delete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('删除客户')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('加载失败：${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _infoCard(d.customer),
                const SizedBox(height: 12),
                _actionRow(d.customer),
                const SizedBox(height: 12),
                _sectionTitle('通话记录（${d.records.length}）'),
                if (d.records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('暂无通话记录', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...d.records.map(_recordTile).toList(),
                const SizedBox(height: 12),
                _sectionTitle('回访时间线（${d.followUps.length}）'),
                if (d.followUps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('暂无回访记录', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...d.followUps.map(_followTile).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(Customer c) {
    final rows = <(String, String)>[
      if (c.company != null && c.company!.isNotEmpty) ('公司', c.company!),
      ('电话', c.phone),
      if (c.address != null && c.address!.isNotEmpty) ('地址', c.address!),
      if (c.remark != null && c.remark!.isNotEmpty) ('备注', c.remark!),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F8F0),
                  child: Text(
                    (c.name ?? c.phone).isNotEmpty
                        ? (c.name ?? c.phone).substring(0, 1)
                        : '?',
                    style: const TextStyle(color: Color(0xFF21C17A)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(c.name ?? '未知客户',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (c.tags != null)
                  Chip(label: Text(c.tags!), backgroundColor: const Color(0xFFE8F8F0)),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(e.$1,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Text(e.$2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 拨号 / 编辑画像 快捷操作
  Widget _actionRow(Customer c) {
    final green = Color(Constants.primaryColorValue);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _call(c.phone),
            icon: const Icon(Icons.call),
            label: const Text('拨打电话'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: BorderSide(color: green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final ok = await context.push<bool>('/customer/${widget.customerId}/edit');
              if (ok == true && mounted) setState(() => _future = _load());
            },
            icon: const Icon(Icons.badge_outlined),
            label: const Text('编辑画像'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF21C17A))),
      );

  Widget _recordTile(CallRecordItem r) {
    final color = <String, Color>{
      'empty': Colors.grey,
      'not_answered': Colors.orange,
      'connected': Colors.green,
      'add_customer': const Color(0xFF21C17A),
    }[r.result] ?? Colors.grey;
    final label = CallResult.labels[r.result] ?? r.result;
    return Card(
      child: ListTile(
        leading: Icon(Icons.call, color: color),
        title: Row(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(r.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        subtitle: Text(
            '${r.calledAt} · 时长 ${r.durationText}${r.remark != null ? ' · ${r.remark}' : ''}'),
        trailing: r.recordingUrl.isNotEmpty
            ? const Icon(Icons.graphic_eq, color: Color(0xFF21C17A))
            : null,
      ),
    );
  }

  Widget _followTile(FollowUp f) => Card(
        child: ListTile(
          leading: const Icon(Icons.event_note, color: Color(0xFF21C17A)),
          title: Text(f.content),
          subtitle: Text('${f.createdAt}${f.tag != null ? ' · ${f.tag}' : ''}'),
        ),
      );
}

class _DetailData {
  final Customer customer;
  final List<CallRecordItem> records;
  final List<FollowUp> followUps;
  _DetailData({
    required this.customer,
    required this.records,
    required this.followUps,
  });
}
