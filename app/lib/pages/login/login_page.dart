import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../api/http_client.dart';

/// 登录页：手机号 / 密码 / 服务器地址（可保存、可测试连接）
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneCtl = TextEditingController(text: '13800000001');
  final _pwdCtl = TextEditingController(text: '123456');
  final _serverCtl = TextEditingController();
  bool _loading = false;
  bool _testing = false;
  String _testMsg = '';
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    // 默认带出当前生效的地址（已保存过的则用保存值）
    _serverCtl.text = currentBaseUrl;
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    _pwdCtl.dispose();
    _serverCtl.dispose();
    super.dispose();
  }

  /// 服务器地址根路径（去掉结尾的 /api，用于探测连通性）
  String _rootOf(String apiUrl) {
    final v = apiUrl.trim();
    return v.replaceAll(RegExp(r'/api/?$'), '/');
  }

  Future<void> _testConnection() async {
    final url = _serverCtl.text.trim();
    if (url.isEmpty) {
      Fluttertoast.showToast(msg: '请先填写服务器地址');
      return;
    }
    setState(() {
      _testing = true;
      _testMsg = '正在连接…';
      _testOk = false;
    });
    try {
      final probe = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      final resp = await probe.get(_rootOf(url));
      if (!mounted) return;
      final ok = resp.statusCode != null && resp.statusCode! < 500;
      setState(() {
        _testOk = ok;
        _testMsg = ok ? '连接成功（HTTP ${resp.statusCode}）' : '服务器返回异常：${resp.statusCode}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMsg = '连接失败，请检查地址、端口，以及手机与服务器是否在同一局域网';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _login() async {
    final phone = _phoneCtl.text.trim();
    final pwd = _pwdCtl.text.trim();
    final server = _serverCtl.text.trim();
    if (server.isEmpty) {
      Fluttertoast.showToast(msg: '请先填写服务器地址，例如 ${Constants.serverUrlExample}');
      return;
    }
    if (phone.isEmpty || pwd.isEmpty) {
      Fluttertoast.showToast(msg: '请输入手机号和密码');
      return;
    }
    setState(() => _loading = true);
    try {
      // 先落地服务器地址，再登录
      await updateBaseUrl(server);
      await ref.read(authProvider.notifier).login(phone, pwd);
      if (mounted) context.go('/');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final tip = msg.contains('Connection') || msg.contains('timeout') || msg.contains('refused')
          ? '连不上服务器：$server\n请确认地址与端口，且手机与服务器在同一局域网'
          : msg;
      Fluttertoast.showToast(msg: tip, toastLength: Toast.LENGTH_LONG);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF21C17A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.phone_android, size: 52, color: Color(0xFF21C17A)),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('电销CRM',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 18),

                  // ---------- 服务器地址 ----------
                  const Text('服务器地址',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _serverCtl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: Constants.serverUrlExample,
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.dns_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: '测试连接',
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering, size: 20),
                        onPressed: _testing ? null : _testConnection,
                      ),
                    ),
                  ),
                  if (_testMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _testMsg,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testOk ? const Color(0xFF21C17A) : Colors.redAccent,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    '填飞牛或服务器的局域网地址，端口用部署端口（飞牛默认 18080），结尾必须是 /api',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // ---------- 账号 ----------
                  TextField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pwdCtl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21C17A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('登录', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 免登录模式下允许先离线浏览
                  if (Constants.autoLogin)
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('先离线看看', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                  const Text('演示账号：13800000001 / 123456',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
