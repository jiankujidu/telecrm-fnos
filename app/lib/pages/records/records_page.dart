import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/call_record_api.dart';
import '../../config/constants.dart';
import '../../models/call_record.dart';
import '../../theme/app_theme.dart';

/// 通话记录（话单）页
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final List<CallRecordItem> _items = [];
  String _result = '';
  int _current = 1;
  final int _size = 20;
  int _total = 0;
  bool _loading = false;
  bool _hasMore = true;

  static const List<Map<String, String>> _filters = [
    {'value': '', 'label': '全部'},
    {'value': CallResult.connected, 'label': '已接通'},
    {'value': CallResult.addCustomer, 'label': '添加客户'},
    {'value': CallResult.notAnswered, 'label': '未接通'},
    {'value': CallResult.empty, 'label': '空号'},
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _current = 1;
      _items.clear();
      _hasMore = true;
    }
    setState(() => _loading = true);
    try {
      final data = await CallRecordApi.list(
        result: _result,
        current: _current,
        size: _size,
      );
      setState(() {
        _items.addAll(data.records);
        _total = data.total;
        _hasMore = _items.length < _total;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败：$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFilter(String value) {
    if (_result == value) return;
    setState(() => _result = value);
    _load(reset: true);
  }

  Future<void> _play(CallRecordItem r) async {
    if (r.recordingUrl.isEmpty) return;
    final url = r.recordingUrl.startsWith('http')
        ? r.recordingUrl
        : '${Constants.baseUrl}${r.recordingUrl}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) Fluttertoast.showToast(msg: '无法打开录音');
    }
  }

  Future<void> _upload(CallRecordItem r) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = picked?.files.single.path;
    if (path == null || path.isEmpty) return;
    setState(() => _loading = true);
    try {
      await CallRecordApi.uploadRecording(r.id, path);
      if (mounted) Fluttertoast.showToast(msg: '录音已上传');
      await _load(reset: true);
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: '上传失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _resultColor(String r) {
    switch (r) {
      case CallResult.connected:
      case CallResult.addCustomer:
        return Colors.green;
      case CallResult.notAnswered:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通话记录')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = _result == f['value'];
                return ChoiceChip(
                  label: Text(f['label']!),
                  selected: active,
                  selectedColor: AppTheme.primary.withOpacity(0.18),
                  labelStyle: TextStyle(color: active ? AppTheme.primary : Colors.black87),
                  onSelected: (_) => _onFilter(f['value']!),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _filters.length,
            ),
          ),
          Expanded(
            child: _items.isEmpty && !_loading
                ? const Center(child: Text('暂无通话记录', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemBuilder: (_, i) {
                      if (i == _items.length) {
                        if (_hasMore) {
                          if (!_loading) {
                            _current++;
                            _load();
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('没有更多了', style: TextStyle(color: Colors.grey))),
                        );
                      }
                      final r = _items[i];
                      final hasRecording = r.recordingUrl.isNotEmpty;
                      return ListTile(
                        leading: Icon(Icons.call, color: _resultColor(r.result)),
                        title: Text(r.phone),
                        subtitle: Text(
                          '${CallResult.labels[r.result] ?? r.result} · ${r.durationText}'
                          '${r.tag != null && r.tag!.isNotEmpty ? ' · ${r.tag}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasRecording)
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: AppTheme.primary),
                                tooltip: '播放录音',
                                onPressed: () => _play(r),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.upload_file, color: Colors.grey),
                                tooltip: '上传录音',
                                onPressed: () => _upload(r),
                              ),
                            Text(
                              r.calledAt.replaceFirst('T', ' ').substring(0, r.calledAt.contains('T') ? 16 : r.calledAt.length),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: _items.length + 1,
                  ),
          ),
        ],
      ),
    );
  }
}
