import '../api/http_client.dart';
import '../models/report.dart';

/// 报表统计接口（复用后端 /report/overview）
class ReportApi {
  /// 团队今日概览（teamId 由后端从登录态解析，无需前端传参）
  static Future<ReportOverview> overview() async {
    final r = await http.get('/report/overview');
    return ReportOverview.fromJson(r.data['data']);
  }
}
