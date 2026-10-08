import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../api/follow_up_api.dart';
import '../../models/follow_up.dart';

/// 我的回访/跟进列表页
class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  List<FollowUp> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _list = await FollowUpApi.list();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(FollowUp f) async {
    try {
      await FollowUpApi.delete(f.id);
      Fluttertoast.showToast(msg: '已删除回访');
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的回访')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const Center(child: Text('暂无回访记录', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = _list[i];
                      return ListTile(
                        title: Text(f.customerName.isEmpty ? '未知客户' : f.customerName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (f.phone.isNotEmpty)
                              Text(f.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(f.content),
                            if (f.tag != null && f.tag!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(
                                  label: Text(f.tag!, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: const Color(0xFFE8F8F0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _delete(f),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
