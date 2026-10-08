import 'http_client.dart';
import '../models/follow_up.dart';

/// 跟进/回访接口（对齐后端 /follow-up）
class FollowUpApi {
  /// 我的回访列表（不传 customerId）或指定客户的回访（传 customerId）
  static Future<List<FollowUp>> list({int? customerId}) async {
    final q = <String, dynamic>{};
    if (customerId != null) q['customerId'] = customerId;
    final r = await http.get('/follow-up/list', queryParameters: q);
    final data = r.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => FollowUp.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 创建回访（外呼标记后触发）
  static Future<void> add(int customerId, String content, [String? tag]) async {
    await http.post('/follow-up/add', data: {
      'customerId': customerId,
      'content': content,
      'tag': tag,
    });
  }

  /// 删除回访
  static Future<void> delete(int id) async {
    await http.delete('/follow-up/$id');
  }
}
