/// 通话结果枚举（对齐后端 CallRecordDTO.result）
class CallResult {
  static const String empty = 'empty'; // 空号
  static const String notAnswered = 'not_answered'; // 未接通
  static const String connected = 'connected'; // 已接通
  static const String addCustomer = 'add_customer'; // 添加客户

  static const Map<String, String> labels = {
    empty: '空号',
    notAnswered: '未接通',
    connected: '已接通',
    addCustomer: '添加客户',
  };
}

/// 通话记录提交参数（对齐后端 CallRecordDTO）
class CallRecordSubmit {
  final int? taskItemId;
  final int? customerId;
  final String phone;
  final int duration;
  final String result;
  final String? remark;
  final String? tag;

  CallRecordSubmit({
    this.taskItemId,
    this.customerId,
    required this.phone,
    this.duration = 0,
    required this.result,
    this.remark,
    this.tag,
  });

  Map<String, dynamic> toJson() => {
        'taskItemId': taskItemId,
        'customerId': customerId,
        'phone': phone,
        'duration': duration,
        'result': result,
        'remark': remark,
        'tag': tag,
      };
}

/// 通话记录列表项（对齐后端 CallRecord 返回）
class CallRecordItem {
  final int id;
  final String phone;
  final int duration;
  final String result;
  final String recordingUrl;
  final String? remark;
  final String? tag;
  final String calledAt;

  CallRecordItem.fromJson(Map<String, dynamic> j)
      : id = PageDataInt(j['id']),
        phone = (j['phone'] ?? '').toString(),
        duration = PageDataInt(j['duration']),
        result = (j['result'] ?? '').toString(),
        recordingUrl = (j['recordingUrl'] ?? '').toString(),
        remark = j['remark']?.toString(),
        tag = j['tag']?.toString(),
        calledAt = (j['calledAt'] ?? '').toString();

  /// 格式化时长 如 1′05″
  String get durationText {
    final s = duration;
    if (s <= 0) return '0″';
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}′${sec}″' : '${sec}″';
  }
}

/// 局部 int 解析（避免循环依赖 page_data.dart）
int PageDataInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
