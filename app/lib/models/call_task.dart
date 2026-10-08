/// 外呼任务模型（对齐后端 CallTask）
class CallTask {
  final int id;
  final int? teamId;
  final int? userId;
  final String? name;
  final String? sourceType;
  final String? status;
  final int totalCount;
  final int calledCount;
  final int validCount;

  const CallTask({
    required this.id,
    this.teamId,
    this.userId,
    this.name,
    this.sourceType,
    this.status,
    this.totalCount = 0,
    this.calledCount = 0,
    this.validCount = 0,
  });

  factory CallTask.fromJson(Map<String, dynamic> j) => CallTask(
        id: _toInt(j['id']),
        teamId: j['teamId'],
        userId: j['userId'],
        name: j['name'],
        sourceType: j['sourceType'],
        status: j['status'],
        totalCount: _toInt(j['totalCount']),
        calledCount: _toInt(j['calledCount']),
        validCount: _toInt(j['validCount']),
      );

  static int _toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
}

/// 外呼任务明细模型（对齐后端 CallTaskItem）
class CallTaskItem {
  final int id;
  final int? taskId;
  final int? customerId;
  final String? name;
  final String phone;
  final String? company;
  final String? address;
  final String? remark;
  final String? status;
  final String? callResult;
  final int callCount;
  final String? lastCallAt;

  const CallTaskItem({
    required this.id,
    this.taskId,
    this.customerId,
    this.name,
    required this.phone,
    this.company,
    this.address,
    this.remark,
    this.status,
    this.callResult,
    this.callCount = 0,
    this.lastCallAt,
  });

  factory CallTaskItem.fromJson(Map<String, dynamic> j) => CallTaskItem(
        id: _toInt(j['id']),
        taskId: j['taskId'],
        customerId: j['customerId'],
        name: j['name'],
        phone: j['phone']?.toString() ?? '',
        company: j['company'],
        address: j['address'],
        remark: j['remark'],
        status: j['status'],
        callResult: j['callResult'],
        callCount: _toInt(j['callCount']),
        lastCallAt: j['lastCallAt']?.toString(),
      );

  /// 是否已拨打（非待拨打状态即视为已处理）
  bool get isDialed => status != null && status != 'pending';

  static int _toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
}
