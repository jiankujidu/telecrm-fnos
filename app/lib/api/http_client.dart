import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// 登录态 token 在 SharedPreferences 中的存储键
const String authTokenKey = 'auth_token';
const String authUserKey = 'auth_user';

/// 服务器地址（可在「我的 - 服务器地址」里修改）在 SharedPreferences 中的存储键
const String serverBaseUrlKey = 'server_base_url';

/// 统一接口异常
class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// 全局 Dio 单例：自动携带 Bearer Token，统一解析后端 Result{code,message,data}
final Dio http = _createDio();

Dio _createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: Constants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString(authTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      final data = response.data;
      if (data is Map && data['code'] != null && data['code'] != 0) {
        handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: ApiException(data['message']?.toString() ?? '请求失败', data['code']),
        ));
        return;
      }
      handler.next(response);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // 401 由调用方统一处理（清除登录态 / 跳转登录）
      }
      handler.next(error);
    },
  ));
  return dio;
}

/// 从统一返回中提取业务数据段
dynamic extractData(Response response) => response.data['data'];

/// 当前生效的接口基址
String get currentBaseUrl => http.options.baseUrl;

/// 启动时加载用户自定义的服务器地址（未配置则用 Constants.baseUrl）
Future<String> loadBaseUrl() async {
  final sp = await SharedPreferences.getInstance();
  final saved = sp.getString(serverBaseUrlKey);
  if (saved != null && saved.trim().isNotEmpty) {
    http.options.baseUrl = saved.trim();
  }
  return http.options.baseUrl;
}

/// 修改并持久化服务器地址，例如 http://192.168.1.8:8080/api
Future<void> updateBaseUrl(String url) async {
  final value = url.trim();
  final sp = await SharedPreferences.getInstance();
  if (value.isEmpty) {
    await sp.remove(serverBaseUrlKey);
    http.options.baseUrl = Constants.baseUrl;
  } else {
    await sp.setString(serverBaseUrlKey, value);
    http.options.baseUrl = value;
  }
}
