import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../api/prospect_api.dart';
import '../../api/call_task_api.dart';
import '../../models/prospect.dart';
import '../../services/dialer_service.dart';

/// 大数据拓客页：筛选 + 企业列表 + 批量加入拨打任务
class BigDataPage extends ConsumerStatefulWidget {
  const BigDataPage({super.key});

  @override
  ConsumerState<BigDataPage> createState() => _BigDataPageState();
}

class _BigDataPageState extends ConsumerState<BigDataPage> {
  List<String> _industries = [];
  List<String> _regions = [];
  List<String> _scales = [];

  String? _industry;
  String? _region;
  String? _scale;
  String _keyword = '';

  List<Prospect> _list = [];
  bool _loading = false;
  int _current = 1;
  bool _hasMore = true;

  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadDicts();
    _load(reset: true);
  }

  Future<void> _loadDicts() async {
    try {
      final d = await ProspectApi.dicts();
      if (mounted) {
        setState(() {
          _industries = List<String>.from(d['industries'] ?? []);
          _regions = List<String>.from(d['regions'] ?? []);
          _scales = List<String>.from(d['scales'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _current = 1;
      _hasMore = true;
      _list = [];
    }
    if (!_hasMore || _loading) return;
    setState(() => _loading = true);
    try {
      final p = await ProspectApi.search(
        industry: _industry,
        region: _region,
        scale: _scale,
        keyword: _keyword,
        current: _current,
        size: 20,
      );
      if (mounted) {
        setState(() {
          _list.addAll(p.records);
          _hasMore = _list.length < p.total;
          _current++;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTask() async {
    final picks = _list.where((p) => _selected.contains(p.id)).toList();
    if (picks.isEmpty) {
      Fluttertoast.showToast(msg: '请先选择企业');
      return;
    }
    try {
      final id = await CallTaskApi.create(
        contacts: picks.map((p) => p.toContact()).toList(),
        name: '大数据拓客 ${DateTime.now().month}-${DateTime.now().day}',
        sourceType: 'bigdata',
      );
      Fluttertoast.showToast(msg: '已创建任务，共 ${picks.length} 条');
      if (mounted) context.push('/dialer?taskId=$id');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    }
  }

  Future<void> _dial(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final r = await DialerService.call(phone);
    if (r.message.isNotEmpty) Fluttertoast.showToast(msg: r.message);
    if (!r.ok && r.needPermission) await DialerService.openPermissionSettings();
  }

  @override
  Widget build(BuildContext context) {
    final green = Color(Constants.primaryColorValue);
    return Scaffold(
      appBar: AppBar(title: const Text('大数据拓客')),
      body: Column(
        children: [
          _buildFilters(green),
          Expanded(child: _buildList(green)),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty ? null : _buildActionBar(green),
    );
  }

  Widget _buildFilters(Color green) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: '搜索公司 / 法人 / 地址',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              fillColor: const Color(0xFFF2F2F2),
              filled: true,
            ),
            onChanged: (v) => _keyword = v,
            onSubmitted: (_) => _load(reset: true),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('行业', _industry, _industries, green, (v) {
                  _industry = v;
                  _load(reset: true);
                }),
                _chip('地区', _region, _regions, green, (v) {
                  _region = v;
                  _load(reset: true);
                }),
                _chip('规模', _scale, _scales, green, (v) {
                  _scale = v;
                  _load(reset: true);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, List<String> options, Color green,
      void Function(String?) onPick) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButton<String>(
        hint: Text(label),
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('全部$label')),
          ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
        ],
        onChanged: onPick,
      ),
    );
  }

  Widget _buildList(Color green) {
    if (_loading && _list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list.isEmpty) {
      return const Center(child: Text('没有匹配的企业', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _list.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == _list.length) {
          _load();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final p = _list[i];
        final checked = _selected.contains(p.id);
        return Card(
          child: InkWell(
            onTap: () => setState(() {
              if (checked) {
                _selected.remove(p.id);
              } else {
                _selected.add(p.id!);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: checked,
                    activeColor: green,
                    onChanged: (_) => setState(() {
                      if (checked) {
                _selected.remove(p.id);
              } else {
                _selected.add(p.id!);
              }
                    }),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.company, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        _row('法人', p.legalPerson),
                        _row('电话', p.phone),
                        _row('地址', p.address),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _tag(p.industry, green),
                            _tag(p.scale, green),
                            _tag(p.registeredCapital, green),
                          ].whereType<Widget>().toList(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.call, color: green),
                    onPressed: () => _dial(p.phone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String k, String? v) => v == null || v.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text('$k：$v', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        );

  Widget? _tag(String? t, Color green) {
    if (t == null || t.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(t, style: TextStyle(color: green, fontSize: 12)),
    );
  }

  Widget _buildActionBar(Color green) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text('已选 ${_selected.length} 家', style: const TextStyle(fontSize: 15)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _selected.clear()),
              child: const Text('清空'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: green),
              onPressed: _createTask,
              child: const Text('加入拨打任务', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
