import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../api/call_task_api.dart';

/// 文件导入页：选择 xls/xlsx/csv/txt 并上传生成任务
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String? _fileName;
  int? _taskId;
  bool _loading = false;
  String? _error;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: Constants.importExtensions,
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    final name = file.path.split('/').last;

    setState(() {
      _fileName = name;
      _taskId = null;
      _error = null;
      _loading = true;
    });
    try {
      final id = await CallTaskApi.importFile(file, name: name);
      setState(() => _taskId = id);
      Fluttertoast.showToast(msg: '导入成功，任务 #$id');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文件导入')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '支持 xls / xlsx / csv / txt，单次最多 ${Constants.maxImportCount} 条，无表头将自动识别手机号列。',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(Constants.primaryColorValue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _pickAndImport,
              icon: const Icon(Icons.upload_file),
              label: Text(_loading ? '导入中...' : '选择文件并导入'),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 16),
              Text('已选择：$_fileName', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
            if (_taskId != null) ...[
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFFE8F8F0),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('导入成功，任务 #$_taskId'),
                  subtitle: const Text('点击开始自动拨号'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/dialer?taskId=$_taskId'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
