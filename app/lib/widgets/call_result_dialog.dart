import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../api/call_record_api.dart';
import '../../api/follow_up_api.dart';
import '../../models/call_record.dart';
import '../../providers/quick_note_provider.dart';

/// 拨打结束标记弹窗：结果选择 + 快捷备注 + 备注，提交到后端
/// [onSubmitExternal] 非空时（自动模式），点击结果交由外部会话统一写记录并推进/重拨；
/// 否则（手动拨号）由本弹窗自行写记录。
class CallResultDialog extends ConsumerStatefulWidget {
  final String phone;
  final int? taskItemId;
  final int? customerId;
  final Future<void> Function(String)? onSubmitExternal;
  final ValueChanged<String>? onSubmitted;

  const CallResultDialog({
    super.key,
    required this.phone,
    this.taskItemId,
    this.customerId,
    this.onSubmitExternal,
    this.onSubmitted,
  });

  @override
  ConsumerState<CallResultDialog> createState() => _CallResultDialogState();
}

class _CallResultDialogState extends ConsumerState<CallResultDialog> {
  String? _remark;
  String? _selectedTag;
  String? _followUpContent;
  String? _followUpTag;
  bool _submitting = false;

  static const List<(String, String)> _results = [
    ('空号', CallResult.empty),
    ('未接通', CallResult.notAnswered),
    ('已接通', CallResult.connected),
    ('添加客户', CallResult.addCustomer),
  ];

  Future<void> _submit(String result) async {
    setState(() => _submitting = true);
    try {
      if (widget.onSubmitExternal != null) {
        await widget.onSubmitExternal!(result);
      } else {
        await CallRecordApi.add(CallRecordSubmit(
          taskItemId: widget.taskItemId,
          customerId: widget.customerId,
          phone: widget.phone,
          result: result,
          remark: _remark,
          tag: _selectedTag,
        ));
      }

      // 写回访（仅当有关联客户且填写了内容；失败不影响标记）
      if (widget.customerId != null &&
          _followUpContent != null &&
          _followUpContent!.trim().isNotEmpty) {
        try {
          await FollowUpApi.add(
              widget.customerId!, _followUpContent!.trim(), _followUpTag?.trim());
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: '已标记：${CallResult.labels[result]}');
        if (widget.onSubmitExternal == null) widget.onSubmitted?.call(widget.phone);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(quickNoteProvider);
    return AlertDialog(
      title: Text('标记通话 - ${widget.phone}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._results.map((r) => ListTile(
                  title: Text(r.$1),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_submitting,
                  onTap: () => _submit(r.$2),
                )),
            const Divider(),
            const Text('快捷备注', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: notes
                  .map((n) => FilterChip(
                        label: Text(n.label),
                        selected: _selectedTag == n.label,
                        selectedColor: const Color(0xFFE8F8F0),
                        onSelected: (sel) => setState(() => _selectedTag = sel ? n.label : null),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: '补充备注',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => _remark = v,
            ),
            if (widget.customerId != null) ...[
              const Divider(),
              const Text('创建回访任务', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                decoration: const InputDecoration(
                  hintText: '跟进内容（选填，标记后生成回访）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                onChanged: (v) => _followUpContent = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: '标签（选填，如：有意向 / 待报价）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (v) => _followUpTag = v,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
