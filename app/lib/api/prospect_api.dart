import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/prospect.dart';
import '../models/page_data.dart';

/// 拓客接口（对齐后端 /prospect）
class ProspectApi {
  /// 大数据拓客：按行业/地区/规模/关键词筛选，分页
  static Future<PageData<Prospect>> search({
    String? industry,
    String? region,
    String? scale,
    String? keyword,
    int current = 1,
    int size = 20,
  }) async {
    final r = await http.get('/prospect/search', queryParameters: {
      if (industry != null) 'industry': industry,
      if (region != null) 'region': region,
      if (scale != null) 'scale': scale,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => Prospect.fromJson(j));
  }

  /// 附近企业：按经纬度半径返回，按距离升序
  static Future<List<Prospect>> nearby(double lat, double lng, double radius) async {
    final r = await http.get('/prospect/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    final list = (r.data['data'] as List?) ?? [];
    return list.map((j) => Prospect.fromJson(j)).toList();
  }

  /// 筛选字典：行业/地区/规模
  static Future<Map<String, dynamic>> dicts() async {
    final r = await http.get('/prospect/dicts');
    return Map<String, dynamic>.from(r.data['data']);
  }
}
