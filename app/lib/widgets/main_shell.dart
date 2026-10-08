import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主框架：底部四大导航（首页/自动拨号/客户/我的）
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const List<_TabItem> _tabs = [
    _TabItem(icon: Icons.home_outlined, label: '首页', route: '/'),
    _TabItem(icon: Icons.dialpad_outlined, label: '自动拨号', route: '/dialer'),
    _TabItem(icon: Icons.people_outline, label: '客户', route: '/customer'),
    _TabItem(icon: Icons.person_outline, label: '我的', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: const Color(0xFF21C17A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => navigationShell.goBranch(i),
        items: _tabs
            .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String route;
  const _TabItem({required this.icon, required this.label, required this.route});
}
