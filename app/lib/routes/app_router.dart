import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_shell.dart';
import '../pages/home/home_page.dart';
import '../pages/dialer/dialer_page.dart';
import '../pages/customer/customer_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/login/login_page.dart';
import '../pages/home/import_page.dart';
import '../pages/records/records_page.dart';
import '../pages/prospect/bigdata_page.dart';
import '../pages/prospect/nearby_page.dart';
import '../pages/member/member_page.dart';
import '../pages/follow_up/follow_up_page.dart';
import '../pages/customer/customer_detail_page.dart';
import '../pages/customer/customer_edit_page.dart';
import '../providers/auth_provider.dart';

/// 路由配置：登录页 + 底部四大导航
final routerProvider = Provider<GoRouter>((ref) {
  // 监听登录态，变化时重建路由以触发重定向
  final auth = ref.watch(authProvider);

  String? _redirect(String? loc) {
    if (!auth.initialized) return null; // 等待本地 token 恢复 / 免登录静默登录
    final loggedIn = auth.isLoggedIn;
    final goingToLogin = loc == '/login';
    if (!loggedIn && !goingToLogin) return '/login';
    // 免登录的离线体验态下，仍允许用户主动进入登录页切换真实账号
    if (loggedIn && goingToLogin && !auth.isGuest) return '/';
    return null;
  }

  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) => _redirect(state.matchedLocation),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/import',
        builder: (_, __) => const ImportPage(),
      ),
      GoRoute(
        path: '/records',
        builder: (_, __) => const RecordsPage(),
      ),
      GoRoute(
        path: '/bigdata',
        builder: (_, __) => const BigDataPage(),
      ),
      GoRoute(
        path: '/nearby',
        builder: (_, __) => const NearbyPage(),
      ),
      GoRoute(
        path: '/member',
        builder: (_, __) => const MemberPage(),
      ),
      GoRoute(
        path: '/follow-up',
        builder: (_, __) => const FollowUpPage(),
      ),
      // 注意：字面量路由要写在 /customer/:id 之前，否则会被参数路由抢先匹配
      GoRoute(
        path: '/customer/new',
        builder: (_, __) => const CustomerEditPage(),
      ),
      GoRoute(
        path: '/customer/:id/edit',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CustomerEditPage(customerId: id);
        },
      ),
      GoRoute(
        path: '/customer/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CustomerDetailPage(customerId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dialer',
              builder: (_, state) {
                final taskId = state.uri.queryParameters['taskId'];
                return DialerPage(taskId: taskId != null ? int.tryParse(taskId) : null);
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/customer', builder: (_, __) => const CustomerPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
});
