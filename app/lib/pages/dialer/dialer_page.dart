import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../services/dialer_service.dart';
import '../../models/call_task.dart';
import '../../providers/quick_note_provider.dart';
import '../../providers/dialer_session_provider.dart';
import '../../widgets/call_result_dialog.dart';

/// 拨号页：自动拨号模式（taskId != null）/ 手拨模式（taskId == null）
/// 自动模式数据源来自全局 dialerSessionProvider，与悬浮窗共享同一份拨打列表。
class DialerPage extends ConsumerStatefulWidget {
  final int? taskId;
  const DialerPage({super.key, this.taskId});

  @override
  ConsumerState<DialerPage> createState() => _DialerPageState();
}

class _DialerPageState extends ConsumerState<DialerPage> {
  final TextEditingController _phoneCtl = TextEditingController();
  bool _autoClear = true;
  int _simSlot = 0;

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      // 进入自动拨号即加载任务明细到全局会话
      ref.read(dialerSessionProvider.notifier).load(widget.taskId!);
    }
  }

  void _onKey(String k) {
    if (_phoneCtl.text.length < 11) _phoneCtl.text += k;
  }

  Future<void> _callManual() async {
    final phone = _phoneCtl.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: '请先输入号码');
      return;
    }
    final r = await DialerService.call(phone, simSlot: _simSlot);
    if (r.message.isNotEmpty) Fluttertoast.showToast(msg: r.message);
    if (!r.ok) {
      if (r.needPermission) await _askPermission();
      return;
    }
    if (_autoClear) _phoneCtl.clear();
    if (mounted) _showMarkDialog(phone: phone);
  }

  Future<void> _callAuto(CallTaskItem item) async {
    final r = await DialerService.call(item.phone, simSlot: ref.read(dialerSessionProvider).simSlot);
    if (r.message.isNotEmpty) Fluttertoast.showToast(msg: r.message);
    if (!r.ok) {
      if (r.needPermission) await _askPermission();
      return;
    }
    if (mounted) {
      _showMarkDialog(phone: item.phone, taskItemId: item.id, customerId: item.customerId);
    }
  }

  /// 没拨号权限时引导用户去系统设置授权
  Future<void> _askPermission() async {
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要拨号权限'),
        content: const Text('自动直拨需要「电话」权限。\n未授权时只能唤起拨号界面，需手动点一下拨出。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('以后再说')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('去授权')),
        ],
      ),
    );
    if (go == true) await DialerService.openPermissionSettings();
  }

  void _showMarkDialog({required String phone, int? taskItemId, int? customerId}) {
    final auto = widget.taskId != null;
    showDialog(
      context: context,
      builder: (_) => CallResultDialog(
        phone: phone,
        taskItemId: taskItemId,
        customerId: customerId,
        // 自动模式：交给全局会话写记录 + 推进/未接通重拨
        onSubmitExternal: auto
            ? (r) => ref.read(dialerSessionProvider.notifier).markAndAdvance(r)
            : null,
      ),
    );
  }

  /// 未接通自动重拨设置弹窗
  void _showRedialSettings() {
    final s = ref.read(dialerSessionProvider);
    int tmp = s.maxRedial;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('未接通自动重拨'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('标记「未接通」后自动重拨同一号码，达到上限再拨打下一通'),
              const SizedBox(height: 12),
              Text(tmp == 0 ? '当前：关闭' : '重拨次数：$tmp'),
              Slider(
                min: 0,
                max: 5,
                divisions: 5,
                value: tmp.toDouble(),
                activeColor: Color(Constants.primaryColorValue),
                onChanged: (v) => setSt(() => tmp = v.round()),
              ),
              const Text('（0 = 关闭自动重拨）', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                ref.read(dialerSessionProvider.notifier).setMaxRedial(tmp);
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskId != null) return _buildAuto();
    return _buildManual();
  }

  /// 自动拨号模式（数据源 = dialerSessionProvider）
  Widget _buildAuto() {
    final s = ref.watch(dialerSessionProvider);
    final current = s.current;
    final total = s.items.length;
    final redial = current != null ? s.redialLabelFor(current.id) : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动拨号'),
        actions: [
          IconButton(
            tooltip: '未接通自动重拨',
            icon: const Icon(Icons.repeat),
            onPressed: _showRedialSettings,
          ),
          Row(
            children: [
              const Text('悬浮窗', style: TextStyle(fontSize: 12)),
              Switch(
                value: s.floatEnabled,
                activeColor: Colors.white,
                onChanged: (v) async {
                  try {
                    await ref.read(dialerSessionProvider.notifier).setFloatEnabled(v);
                  } catch (e) {
                    Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
            ],
          ),
        ],
        bottom: total > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : s.dialedCount / total,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Color(Constants.primaryColorValue)),
                ),
              )
            : null,
      ),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : s.error != null
              ? Center(child: Text(s.error!, style: const TextStyle(color: Colors.red)))
              : current == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all, size: 56, color: Colors.green),
                          SizedBox(height: 12),
                          Text('全部拨打完成', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('进度：已拨打 ${s.dialedCount} / $total',
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(current.name ?? '未知客户',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  if (current.company != null)
                                    Text(current.company!, style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  Text(current.phone,
                                      style: const TextStyle(
                                          fontSize: 28, letterSpacing: 2, color: Color(0xFF21C17A))),
                                  const SizedBox(height: 8),
                                  if (current.remark != null) Text('备注：${current.remark!}'),
                                  if (redial != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3E0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(redial,
                                            style: const TextStyle(
                                                color: Color(0xFFE65100), fontSize: 12)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (s.floatEnabled)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text('悬浮窗已开启：标记/下一通可在任意 App 上层操作',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
      floatingActionButton: current == null
          ? null
          : FloatingActionButton(
              backgroundColor: Color(Constants.primaryColorValue),
              onPressed: () => _callAuto(current),
              child: const Icon(Icons.call, size: 32, color: Colors.white),
            ),
    );
  }

  /// 手动拨号模式（数字键盘）
  Widget _buildManual() {
    final notes = ref.watch(quickNoteProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('拨号')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtl,
                    decoration: const InputDecoration(
                      hintText: '请输入拨打号码',
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('自动清除'),
            value: _autoClear,
            activeColor: Color(Constants.primaryColorValue),
            onChanged: (v) => setState(() => _autoClear = v),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _keys
                  .map((k) => InkWell(
                        onTap: () => _onKey(k),
                        child: Center(
                          child: Text(k,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Chip(
                label: Text(notes[i].label, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFE8F8F0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FloatingActionButton(
              backgroundColor: Color(Constants.primaryColorValue),
              onPressed: _callManual,
              child: const Icon(Icons.call, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
