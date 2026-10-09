import 'http_client.dart';

/// 云端自动外呼（手机端只需三个接口：next / report / release）
class DialPushApi {
  /// 轮询：现在该拨谁
  /// status: none | paused | wait | dial | finished
  static Future<Map<String, dynamic>> next() async {
    final r = await http.get('/dial-push/next');
    return Map<String, dynamic>.from(r.data['data'] ?? {});
  }

  /// 上报通话结果
  static Future<void> report({
    required int taskId,
    required int itemId,
    required String result,
    int duration = 0,
    String remark = '',
  }) async {
    await http.post('/dial-push/report', data: {
      'taskId': taskId,
      'itemId': itemId,
      'result': result,
      'duration': duration,
      'remark': remark,
    });
  }

  /// 放弃当前这条（退回队列，下一轮再拨）
  static Future<void> release({required int taskId, required int itemId}) async {
    await http.post('/dial-push/release', data: {
      'taskId': taskId,
      'itemId': itemId,
    });
  }

  /// 任务列表（手机端查看）
  static Future<List<Map<String, dynamic>>> list() async {
    final r = await http.get('/dial-push/list');
    final l = r.data['data'] as List<dynamic>? ?? [];
    return l.cast<Map<String, dynamic>>();
  }

  /// 任务明细
  static Future<List<Map<String, dynamic>>> items(int taskId) async {
    final r = await http.get('/dial-push/$taskId/items');
    final l = r.data['data'] as List<dynamic>? ?? [];
    return l.cast<Map<String, dynamic>>();
  }
}
