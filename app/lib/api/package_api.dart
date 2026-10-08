import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/package.dart';
import '../models/page_data.dart';

/// 会员中心接口（对齐后端 /package /order /vip-code）
class PackageApi {
  /// 上架套餐列表
  static Future<List<Package>> packages() async {
    final r = await http.get('/package/list', queryParameters: {'status': 0});
    final list = (r.data['data'] as List?) ?? [];
    return list.map((j) => Package.fromJson(j)).toList();
  }

  /// 创建购买订单，返回订单 id
  static Future<int> createOrder(int packageId) async {
    final r = await http.post('/order', data: {'packageId': packageId});
    return (r.data['data'] as num).toInt();
  }

  /// 模拟支付成功
  static Future<void> payOrder(int orderId) async {
    await http.post('/order/$orderId/pay');
  }

  /// 我的订单（分页）
  static Future<PageData<Order>> orders({int current = 1, int size = 50}) async {
    final r = await http.get('/order/list', queryParameters: {
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => Order.fromJson(j));
  }

  /// 兑换 VIP 码
  static Future<void> redeem(String code) async {
    await http.post('/vip-code/redeem', data: {'code': code});
  }
}
