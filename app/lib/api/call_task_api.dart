import 'dart:io';
import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/call_task.dart';
import '../models/page_data.dart';

/// 外呼任务接口（对齐后端 /call-task）
class CallTaskApi {
  /// 文件导入生成任务，返回任务ID
  static Future<int> importFile(
    File file, {
    String? name,
    String sourceType = 'file',
  }) async {
    final fileName = file.path.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (name != null) 'name': name,
      'sourceType': sourceType,
    });
    final r = await http.post('/call-task/import', data: form);
    return (r.data['data'] as num).toInt();
  }

  /// 任务列表（分页）
  static Future<PageData<CallTask>> list({int current = 1, int size = 20}) async {
    final r = await http.get('/call-task/list', queryParameters: {
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => CallTask.fromJson(j));
  }

  /// 任务明细（分页）
  static Future<PageData<CallTaskItem>> items(
    int taskId, {
    int current = 1,
    int size = 50,
  }) async {
    final r = await http.get('/call-task/$taskId/items', queryParameters: {
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => CallTaskItem.fromJson(j));
  }

  /// 从联系人创建任务（拓客/附近企业加入拨打）
  static Future<int> create({
    required List<Map<String, String>> contacts,
    required String name,
    required String sourceType,
  }) async {
    final r = await http.post('/call-task/create', data: {
      'name': name,
      'sourceType': sourceType,
      'items': contacts,
    });
    return (r.data['data'] as num).toInt();
  }
}
