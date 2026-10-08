import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/call_record.dart';
import '../models/page_data.dart';

/// 通话记录接口（对齐后端 /call-record）
class CallRecordApi {
  static Future<void> add(CallRecordSubmit dto) async {
    await http.post('/call-record', data: dto.toJson());
  }

  /// 通话记录/话单列表（分页）
  static Future<PageData<CallRecordItem>> list({
    String scope = 'mine',
    String? result,
    int current = 1,
    int size = 20,
  }) async {
    final Map<String, dynamic> q = {
      'scope': scope,
      'current': current,
      'size': size,
    };
    if (result != null && result.isNotEmpty) q['result'] = result;
    final r = await http.get('/call-record/list', queryParameters: q);
    final data = r.data['data'] as Map<String, dynamic>? ?? {};
    return PageData.fromJson(data, (m) => CallRecordItem.fromJson(m as Map<String, dynamic>));
  }

  /// 上传并关联通话录音：先 /file/upload 拿到 URL，再关联到记录
  static Future<void> uploadRecording(int recordId, String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final r = await http.post('/file/upload', data: formData);
    final url = (r.data['data']?['url'] as String?) ?? '';
    if (url.isEmpty) throw Exception('上传未返回地址');
    await http.post('/call-record/$recordId/recording', data: {'recordingUrl': url});
  }

  /// 某客户的通话记录（详情页用，返回列表）
  static Future<List<CallRecordItem>> byCustomer(int customerId) async {
    final r = await http.get('/call-record/by-customer',
        queryParameters: {'customerId': customerId});
    final data = r.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => CallRecordItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
