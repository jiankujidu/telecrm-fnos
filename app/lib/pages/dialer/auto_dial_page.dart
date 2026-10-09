import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../api/dial_push_api.dart';
import '../../services/dialer_service.dart';

/// 云端自动外呼（手机端执行器）
///
/// 逻辑：本页只做三件事——问后端「现在拨谁」→ 拨出去 → 上报结果。
/// 顺序、间隔秒数、暂停/结束全部由电脑端后台决定，手机每轮都问一次，
/// 所以電腦上一改，手机下一轮立刻生效。
class AutoDialPage extends StatefulWidget {
  const AutoDialPage({super.key});

  @override
  State<AutoDialPage> createState() => _AutoDialPageState();
}

class _AutoDialPageState extends State<AutoDialPage> {
  static const _primary = Color(Constants.primaryColorValue);

  Timer? _poll;
  Timer? _countdown;

  String _phase = 'none'; // none | paused | wait | dial | finished
  int _leftSeconds = 0;

  int? _taskId;
  int? _itemId;
  String _taskName = '';
  String _name = '';
  String _phone = '';
  String _company = '';
  int _seq = 0;
  int _total = 0;
  int _dialed = 0;
  int _interval = 15;

  /// 自动模式：拨出后倒计时结束仍未选择结果，则按默认结果上报并自动进下一条
  bool _autoMode = true;
  String _defaultResult = 'no_answer';
  bool _reporting = false;
  bool _busy = false;

  static const _results = <Map<String, String>>[
    {'key': 'connected', 'label': '已接通', 'icon': 'check'},
    {'key': 'add_customer', 'label': '已加客户', 'icon': 'person'},
    {'key': 'no_answer', 'label': '未接听', 'icon': 'phone_missed'},
    {'key': 'refused', 'label': '拒接', 'icon': 'block'},
    {'key': 'shutdown', 'label': '关机/停机', 'icon': 'power'},
    {'key': 'empty', 'label': '空号', 'icon': 'error'},
  ];

  @override
  void initState() {
    super.initState();
    _ensurePermission();
    _tick();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _ensurePermission() async {
    final ok = await DialerService.ensurePermission();
    if (!ok && mounted) {
      Fluttertoast.showToast(msg: '未授予电话权限，将降级为唤起拨号界面');
    }
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final r = await DialPushApi.next();
      if (!mounted) return;
      final status = (r['status'] ?? 'none').toString();
      switch (status) {
        case 'dial':
          _taskId = _int(r['taskId']);
          _itemId = _int(r['itemId']);
          _taskName = (r['taskName'] ?? '').toString();
          _name = (r['name'] ?? '').toString();
          _phone = (r['phone'] ?? '').toString();
          _company = (r['company'] ?? '').toString();
          _seq = _int(r['seq']) ?? 0;
          _total = _int(r['total']) ?? 0;
          _dialed = _int(r['dialed']) ?? 0;
          _interval = _int(r['intervalSeconds']) ?? 15;
          // 是新的一通才拨，避免重复拨同一个号
          if (_phase != 'dial') {
            _phase = 'dial';
            _leftSeconds = _interval;
            setState(() {});
            await _doDial();
          }
          break;
        case 'wait':
          _taskId = _int(r['taskId']);
          _taskName = (r['taskName'] ?? '').toString();
          _total = _int(r['total']) ?? 0;
          _dialed = _int(r['dialed']) ?? 0;
          _leftSeconds = _int(r['seconds']) ?? 0;
          _phase = 'wait';
          setState(() {});
          break;
        case 'paused':
          _phase = 'paused';
          setState(() {});
          break;
        case 'finished':
          _phase = 'finished';
          _cancelCountdown();
          setState(() {});
          break;
        default:
          _phase = 'none';
          setState(() {});
      }
    } catch (e) {
      if (mounted && _phase == 'none') setState(() {});
    } finally {
      _busy = false;
    }
  }

  int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> _doDial() async {
    if (_phone.isEmpty) return;
    final r = await DialerService.call(_phone);
    if (r.message.isNotEmpty) Fluttertoast.showToast(msg: r.message);
    if (!r.ok && r.needPermission) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('需要拨号权限'),
          content: const Text('自动直拨需要「电话」权限。\n未授权时只能唤起拨号界面，需要手动点一下拨出。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('以后再说')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('去授权')),
          ],
        ),
      );
      if (go == true) await DialerService.openPermissionSettings();
    }
    _startCountdown();
  }

  void _startCountdown() {
    _cancelCountdown();
    _leftSeconds = _interval > 0 ? _interval : 5;
    setState(() {});
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_leftSeconds <= 1) {
        t.cancel();
        if (_autoMode && _itemId != null) {
          await _report(_defaultResult);
        } else {
          setState(() => _leftSeconds = 0);
        }
        return;
      }
      setState(() => _leftSeconds--);
    });
  }

  void _cancelCountdown() {
    _countdown?.cancel();
    _countdown = null;
  }

  Future<void> _report(String result) async {
    if (_taskId == null || _itemId == null || _reporting) return;
    _reporting = true;
    _cancelCountdown();
    try {
      await DialPushApi.report(taskId: _taskId!, itemId: _itemId!, result: result);
      Fluttertoast.showToast(msg: '已记录：${_labelOf(result)}');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      _reporting = false;
      if (mounted) {
        setState(() {
          _phase = 'wait';
          _itemId = null;
          _phone = '';
          _leftSeconds = _interval;
        });
      }
      await Future.delayed(const Duration(milliseconds: 300));
      _busy = false;
      await _tick();
    }
  }

  String _labelOf(String key) {
    for (final r in _results) {
      if (r['key'] == key) return r['label']!;
    }
    return key;
  }

  Future<void> _release() async {
    if (_taskId == null || _itemId == null) return;
    _cancelCountdown();
    try {
      await DialPushApi.release(taskId: _taskId!, itemId: _itemId!);
      Fluttertoast.showToast(msg: '已放回队列，稍后重拨');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    }
    if (mounted) {
      setState(() {
        _phase = 'wait';
        _itemId = null;
        _phone = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云端自动外呼'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 14),
            if (_phase == 'dial' && _phone.isNotEmpty) ...[
              _buildCurrentCard(),
              const SizedBox(height: 14),
              _buildResultButtons(),
            ] else
              _buildIdle(),
            const SizedBox(height: 14),
            _buildHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final running = _phase == 'dial' || _phase == 'wait';
    final color = running
        ? _primary
        : _phase == 'paused'
            ? Colors.orange
            : _phase == 'finished'
                ? Colors.blueGrey
                : Colors.grey;
    final text = running
        ? '外呼进行中'
        : _phase == 'paused'
            ? '任务已暂停（电脑端暂停）'
            : _phase == 'finished'
                ? '本轮任务已全部拨完'
                : '等待电脑端下发任务';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                if (_total > 0)
                  Text('$_dialed / $_total',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (_taskName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_taskName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            if (_total > 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _total == 0 ? 0 : _dialed / _total,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
                minHeight: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    return Card(
      color: const Color(0xFFF3FBF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('第 $_seq 条 / 共 $_total 条', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Text(_name.isEmpty ? '未命名客户' : _name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_phone,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            if (_company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_company, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重拨/放回'),
                    onPressed: _release,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _primary),
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text('再拨一次', style: TextStyle(color: Colors.white)),
                    onPressed: () => DialerService.call(_phone),
                  ),
                ),
              ],
            ),
            if (_autoMode && _leftSeconds > 0) ...[
              const SizedBox(height: 10),
              Text('$_leftSeconds 秒后自动进入下一条（默认标记：${_labelOf(_defaultResult)}）',
                  style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultButtons() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('挂断后点一下结果（不点则按默认自动进入下一条）',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _results.map((r) {
                final key = r['key']!;
                final hot = key == 'connected' || key == 'add_customer';
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 68) / 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hot ? _primary : Colors.grey.shade100,
                      foregroundColor: hot ? Colors.white : Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _report(key),
                    child: Text(r['label']!),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdle() {
    IconData icon;
    String title;
    String sub;
    switch (_phase) {
      case 'wait':
        icon = Icons.hourglass_empty;
        title = _leftSeconds > 0 ? '等待 $_leftSeconds 秒' : '准备下一条…';
        sub = '间隔由电脑端设置（当前 $_interval 秒）';
        break;
      case 'paused':
        icon = Icons.pause_circle_outline;
        title = '已暂停';
        sub = '电脑端点「继续」后会自动接着拨';
        break;
      case 'finished':
        icon = Icons.check_circle_outline;
        title = '本轮已拨完';
        sub = '共 $_total 条，等待电脑端下发新任务';
        break;
      default:
        icon = Icons.cloud_queue;
        title = '等待电脑端下发任务';
        sub = '在后台「云端自动外呼」新建任务并点「开始」，本页会自动接单拨号';
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Card(
      color: const Color(0xFFFFFBF0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('使用说明', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('1. 电脑端：云端自动外呼 → 新建任务（选起点客户、间隔秒数）→ 开始'),
            Text('2. 手机端：保持本页在前台，会自动按顺序拨出'),
            Text('3. 每通挂断后点结果，不点则倒计时结束自动进下一条'),
            Text('4. 电脑端可随时暂停/继续/跳过/结束，手机下一轮立即生效'),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    bool tmpAuto = _autoMode;
    String tmpResult = _defaultResult;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('执行设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('自动进入下一条'),
                subtitle: const Text('倒计时结束未选结果时，按默认结果上报并继续'),
                value: tmpAuto,
                activeColor: _primary,
                onChanged: (v) => setSt(() => tmpAuto = v),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('默认结果：'),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: tmpResult,
                    items: _results
                        .map((r) => DropdownMenuItem<String>(
                            value: r['key'], child: Text(r['label']!)))
                        .toList(),
                    onChanged: (v) => setSt(() => tmpResult = v ?? 'no_answer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primary),
                  onPressed: () {
                    setState(() {
                      _autoMode = tmpAuto;
                      _defaultResult = tmpResult;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('保存', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
