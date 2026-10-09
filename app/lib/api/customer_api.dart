import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/customer.dart';
import '../models/customer_profile.dart';
import '../models/page_data.dart';

/// 客户接口（对齐后端 /customer）
class CustomerApi {
  /// 客户列表：scope = mine | team | public
  static Future<PageData<Customer>> list(
    String scope, {
    String? keyword,
    int current = 1,
    int size = 20,
  }) async {
    final r = await http.get('/customer/list', queryParameters: {
      'scope': scope,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => Customer.fromJson(j));
  }

  /// 客户详情（基本信息）
  static Future<Customer> detail(int id) async {
    final r = await http.get('/customer/$id');
    final data = r.data['data'] as Map<String, dynamic>? ?? {};
    return Customer.fromJson(data);
  }

  /// 画像表：客户 + 画像联表分页
  static Future<PageData<Map<String, dynamic>>> profileList(
    String scope, {
    String? keyword,
    String? intentLevel,
    int current = 1,
    int size = 20,
  }) async {
    final r = await http.get('/customer/profile/list', queryParameters: {
      'scope': scope,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (intentLevel != null && intentLevel.isNotEmpty) 'intentLevel': intentLevel,
      'current': current,
      'size': size,
    });
    return PageData.fromJson(r.data['data'], (j) => Map<String, dynamic>.from(j));
  }

  /// 新建客户
  static Future<Customer> create({
    String? name,
    required String phone,
    String? company,
    String? address,
    String? remark,
    String? tags,
    String? status,
  }) async {
    final r = await http.post('/customer/create', data: {
      if (name != null) 'name': name,
      'phone': phone,
      if (company != null) 'company': company,
      if (address != null) 'address': address,
      if (remark != null) 'remark': remark,
      if (tags != null) 'tags': tags,
      if (status != null) 'status': status,
    });
    return Customer.fromJson(r.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// 编辑客户基本信息
  static Future<Customer> update(
    int id, {
    String? name,
    String? phone,
    String? company,
    String? address,
    String? remark,
    String? tags,
    String? status,
  }) async {
    final r = await http.post('/customer/update', data: {
      'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (company != null) 'company': company,
      if (address != null) 'address': address,
      if (remark != null) 'remark': remark,
      if (tags != null) 'tags': tags,
      if (status != null) 'status': status,
    });
    return Customer.fromJson(r.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// 删除客户（同时删除其画像）
  static Future<void> remove(int id) async {
    await http.post('/customer/delete', data: {'id': id});
  }

  /// 批量删除
  static Future<int> removeBatch(List<int> ids) async {
    final r = await http.post('/customer/delete', data: {
      'ids': ids,
    });
    final d = r.data['data'];
    if (d is Map && d['count'] is int) return d['count'];
    return 0;
  }

  /// 读取客户画像（后端不存在时会自动建空画像）
  static Future<CustomerProfile> getProfile(int id) async {
    final r = await http.get('/customer/$id/profile');
    return CustomerProfile.fromJson(r.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// 保存客户画像
  static Future<CustomerProfile> saveProfile(int id, CustomerProfile p) async {
    final r = await http.post('/customer/$id/profile', data: p.toJson());
    return CustomerProfile.fromJson(r.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// 拨打后累计次数
  static Future<CustomerProfile> touchCall(int id) async {
    final r = await http.post('/customer/$id/touch-call');
    return CustomerProfile.fromJson(r.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// 置顶 / 取消置顶（与电脑端通用）
  static Future<void> pin(int id, bool pin) async {
    await http.post('/customer/$id/pin', data: {'pin': pin});
  }
}
