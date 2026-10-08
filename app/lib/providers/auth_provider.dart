import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../api/http_client.dart';
import '../api/auth_api.dart';

/// 登录状态
class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool initialized;

  /// 免登录兜底出来的「离线体验态」：没有真实 token，但允许浏览界面
  final bool guest;

  const AuthState({this.token, this.user, this.initialized = false, this.guest = false});

  bool get isLoggedIn => token != null && token!.isNotEmpty;
  bool get isGuest => guest;

  String get nickname => user?['nickname']?.toString() ?? '销售坐席';
  String get phone => user?['phone']?.toString() ?? '';
  int? get userId => user?['id'] is int ? user!['id'] : (user?['id'] is String ? int.tryParse(user!['id']) : null);

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? initialized,
    bool? guest,
  }) =>
      AuthState(
        token: token ?? this.token,
        user: user ?? this.user,
        initialized: initialized ?? this.initialized,
        guest: guest ?? this.guest,
      );
}

/// 免登录预登录是否已在 main() 中执行过
bool _bootstrapDone = false;

/// 免登录预登录：在 runApp 之前把演示账号的 token 写好，
/// 这样首屏不会因为没有 token 而闪一下登录页 / 空数据页。
Future<void> bootstrapAuth() async {
  if (!Constants.autoLogin) return;
  try {
    final sp = await SharedPreferences.getInstance();
    final existing = sp.getString(authTokenKey);
    if (existing != null && existing.isNotEmpty) return;
    final data = await AuthApi.login(Constants.demoPhone, Constants.demoPassword)
        .timeout(const Duration(seconds: 5));
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return;
    await sp.setString(authTokenKey, token);
    final u = data['user'];
    if (u is Map) await sp.setString(authUserKey, jsonEncode(u));
  } catch (_) {
    // 连不上服务器：直接进入离线体验态
  } finally {
    _bootstrapDone = true;
  }
}

/// 全局登录态管理
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(authTokenKey);
    final raw = sp.getString(authUserKey);
    Map<String, dynamic>? user;
    if (raw != null) {
      try {
        user = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }

    // 免登录：本地没有 token 时进入离线体验态，界面照常可浏览
    if ((token == null || token.isEmpty) && Constants.autoLogin) {
      if (!_bootstrapDone) {
        // 兜底：main() 没跑过预登录（例如热重载）时再试一次
        try {
          final data = await AuthApi.login(Constants.demoPhone, Constants.demoPassword)
              .timeout(const Duration(seconds: 5));
          final real = data['token']?.toString();
          if (real != null && real.isNotEmpty) {
            await sp.setString(authTokenKey, real);
            final u = data['user'];
            if (u is Map) {
              user = Map<String, dynamic>.from(u);
              await sp.setString(authUserKey, jsonEncode(user));
            }
            state = AuthState(token: real, user: user, initialized: true, guest: false);
            return;
          }
        } catch (_) {}
      }
      await _enterGuest();
      return;
    }

    state = AuthState(token: token, user: user, initialized: true);
  }

  /// 进入离线体验态：不写盘，下次启动仍会重试真实登录
  Future<void> _enterGuest() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(authTokenKey);
    state = AuthState(
      token: Constants.offlineToken,
      user: <String, dynamic>{
        'id': 1,
        'phone': Constants.demoPhone,
        'nickname': '体验坐席',
        'teamId': 1,
      },
      initialized: true,
      guest: true,
    );
  }

  Future<void> login(String phone, String password) async {
    final data = await AuthApi.login(phone, password);
    final token = data['token']?.toString();
    final user = data['user'];
    if (token == null) throw Exception('登录失败：未返回token');
    final sp = await SharedPreferences.getInstance();
    await sp.setString(authTokenKey, token);
    if (user != null) await sp.setString(authUserKey, jsonEncode(user));
    state = AuthState(
      token: token,
      user: user is Map ? Map<String, dynamic>.from(user) : null,
      initialized: true,
      guest: false,
    );
  }

  Future<void> register(String phone, String password, String nickname) async {
    final user = await AuthApi.register(phone, password, nickname);
    final sp = await SharedPreferences.getInstance();
    if (user != null) await sp.setString(authUserKey, jsonEncode(user));
    state = state.copyWith(user: user is Map ? Map<String, dynamic>.from(user) : null);
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(authTokenKey);
    await sp.remove(authUserKey);
    if (Constants.autoLogin) {
      // 免登录模式下退出=回到离线体验态，不再把用户赶回登录页
      await _enterGuest();
      return;
    }
    state = const AuthState(initialized: true);
  }
}
