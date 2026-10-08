import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'api/http_client.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/recording_service.dart';
import 'services/floating_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadBaseUrl(); // 恢复用户自定义的服务器地址
  await bootstrapAuth(); // 免登录：先用演示账号静默登录（最多等 5 秒）
  await RecordingService.init();
  // 暴露全局容器，供原生悬浮窗回调驱动拨号会话
  final container = ProviderContainer();
  await FloatingService.init(container);
  runApp(UncontrolledProviderScope(container: container, child: const TeleCrmApp()));
}

class TeleCrmApp extends ConsumerWidget {
  const TeleCrmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '电销CRM',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
