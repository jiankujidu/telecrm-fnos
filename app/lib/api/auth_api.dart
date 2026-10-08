import 'package:dio/dio.dart';
import 'http_client.dart';

/// 鉴权接口（对齐后端 /auth）
class AuthApi {
  /// 登录：返回 { token, user }
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final r = await http.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return Map<String, dynamic>.from(r.data['data']);
  }

  /// 注册：返回 User
  static Future<Map<String, dynamic>> register(
    String phone,
    String password,
    String nickname,
  ) async {
    final r = await http.post('/auth/register', data: {
      'phone': phone,
      'passwordHash': password, // 后端约定入参为明文密码
      'nickname': nickname,
    });
    return Map<String, dynamic>.from(r.data['data']);
  }
}
