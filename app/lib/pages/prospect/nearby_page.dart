import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/constants.dart';
import '../../api/prospect_api.dart';
import '../../api/call_task_api.dart';
import '../../models/prospect.dart';
import '../../services/dialer_service.dart';

/// 附近企业页：定位 + 按距离排序 + 批量加入拨打任务
class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  double _lat = 22.5431;
  double _lng = 114.0579;
  double _radius = 5;
  List<Prospect> _list = [];
  bool _loading = true;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _locateAndLoad();
  }

  Future<void> _locateAndLoad() async {
    setState(() => _loading = true);
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _lat = pos.latitude;
        _lng = pos.longitude;
      } else {
        Fluttertoast.showToast(msg: '未授权定位，已使用默认位置（深圳）');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '定位失败，已使用默认位置（深圳）');
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ProspectApi.nearby(_lat, _lng, _radius);
      if (mounted) setState(() => _list = list);
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
        name: '附近企业 ${DateTime.now().month}-${DateTime.now().day}',
        sourceType: 'nearby',
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
      appBar: AppBar(title: const Text('附近企业')),
      body: Column(
        children: [
          _buildBar(green),
          Expanded(child: _buildList(green)),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty ? null : _buildActionBar(green),
    );
  }

  Widget _buildBar(Color green) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '当前位置：${_lat.toStringAsFixed(3)}, ${_lng.toStringAsFixed(3)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const Text('半径', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          DropdownButton<double>(
            value: _radius,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('1km')),
              DropdownMenuItem(value: 3.0, child: Text('3km')),
              DropdownMenuItem(value: 5.0, child: Text('5km')),
              DropdownMenuItem(value: 10.0, child: Text('10km')),
            ],
            onChanged: (v) {
              if (v != null) {
                _radius = v;
                _load();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            color: green,
            onPressed: _locateAndLoad,
            tooltip: '重新定位',
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color green) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_list.isEmpty) {
      return const Center(child: Text('附近没有匹配的企业', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
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
                            if (p.distance != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${p.distance!.toStringAsFixed(1)} km',
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            if (p.industry != null) _tag(p.industry!, green),
                          ],
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

  Widget _tag(String t, Color green) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(t, style: TextStyle(color: green, fontSize: 12)),
      );

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
