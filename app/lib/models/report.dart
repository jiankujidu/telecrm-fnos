/// 今日战报 / 团队概览（对齐后端 /report/overview）
class ReportOverview {
  final int todayCalled;
  final int todayConnected;
  final int todayEmpty;
  final int todayNotAnswered;
  final int todayAddCustomer;
  final String todayConnectRate; // 形如 "12.3%"
  final String todayConvertRate; // 加客户转化率
  final int todayAvgDuration; // 接通通话平均时长（秒）
  final int totalCalled;
  final int validCustomers;
  final int totalCustomers;
  final int totalMembers;
  final int totalTasks;

  const ReportOverview({
    this.todayCalled = 0,
    this.todayConnected = 0,
    this.todayEmpty = 0,
    this.todayNotAnswered = 0,
    this.todayAddCustomer = 0,
    this.todayConnectRate = '0%',
    this.todayConvertRate = '0%',
    this.todayAvgDuration = 0,
    this.totalCalled = 0,
    this.validCustomers = 0,
    this.totalCustomers = 0,
    this.totalMembers = 0,
    this.totalTasks = 0,
  });

  factory ReportOverview.fromJson(Map<String, dynamic> j) {
    return ReportOverview(
      todayCalled: _toInt(j['todayCalled']),
      todayConnected: _toInt(j['todayConnected']),
      todayEmpty: _toInt(j['todayEmpty']),
      todayNotAnswered: _toInt(j['todayNotAnswered']),
      todayAddCustomer: _toInt(j['todayAddCustomer']),
      todayConnectRate: j['todayConnectRate']?.toString() ?? '0%',
      todayConvertRate: j['todayConvertRate']?.toString() ?? '0%',
      todayAvgDuration: _toInt(j['todayAvgDuration']),
      totalCalled: _toInt(j['totalCalled']),
      validCustomers: _toInt(j['validCustomers']),
      totalCustomers: _toInt(j['totalCustomers']),
      totalMembers: _toInt(j['totalMembers']),
      totalTasks: _toInt(j['totalTasks']),
    );
  }

  /// 平均时长格式化为「X分Y秒」
  String get avgDurationText {
    final s = todayAvgDuration;
    if (s <= 0) return '0秒';
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '$m分${sec}秒' : '${sec}秒';
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
