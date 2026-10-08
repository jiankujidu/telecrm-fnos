import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../api/http_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/floating_service.dart';
import '../../services/recording_service.dart';

/// 我的页：个人信息、团队、套餐、设置、退出登录
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final phone = auth.phone;
    final maskedPhone = phone.length >= 11 ? phone.replaceRange(3, 7, '****') : phone;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(auth.nickname),
            subtitle: Text(maskedPhone),
          ),
          const Divider(),
          const ListTile(title: Text('我的团队'), trailing: Icon(Icons.chevron_right)),
          ListTile(
            title: const Text('套餐 / 余额'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/member'),
          ),
          const _AutoUploadTile(),
          ListTile(
            title: const Text('我的回访'),
            subtitle: const Text('外呼标记后创建的跟进任务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/follow-up'),
          ),
          const ListTile(title: Text('通话录音'), trailing: Icon(Icons.chevron_right)),
          ListTile(
            title: const Text('通话记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/records'),
          ),
          ListTile(
            title: const Text('悬浮窗设置'),
            subtitle: const Text('开启连续拨打前需授权显示悬浮窗'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final ok = await FloatingService.canDrawOverlay();
              if (!ok) {
                await FloatingService.requestOverlayPermission();
                Fluttertoast.showToast(msg: '请在系统设置中开启“显示悬浮窗”权限');
              } else {
                Fluttertoast.showToast(msg: '悬浮窗权限已开启，进入自动拨号可开启连续拨打');
              }
            },
          ),
          const ListTile(title: Text('电池白名单'), trailing: Icon(Icons.chevron_right)),
          const ListTile(title: Text('帮助文档'), trailing: Icon(Icons.chevron_right)),
          const _ServerUrlTile(),
          if (Constants.autoLogin && auth.isGuest)
            ListTile(
              title: const Text('登录真实账号'),
              subtitle: const Text('当前为免登录体验态，数据来自演示环境'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/login'),
            ),
          ListTile(
            title: const Text('退出登录'),
            textColor: Colors.red,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(Constants.autoLogin ? '/' : '/login');
            },
          ),
        ],
      ),
    );
  }
}

/// 服务器地址设置（真机连局域网后端时修改，例如 http://192.168.1.8:8080/api）
class _ServerUrlTile extends StatefulWidget {
  const _ServerUrlTile();

  @override
  State<_ServerUrlTile> createState() => _ServerUrlTileState();
}

class _ServerUrlTileState extends State<_ServerUrlTile> {
  final _ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctl.text = currentBaseUrl;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    _ctl.text = currentBaseUrl;
    _ctl.selection = TextSelection.fromPosition(TextPosition(offset: _ctl.text.length));
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('服务器地址'),
            content: TextField(
              controller: _ctl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.8:8080/api',
                helperText: '真机请填电脑的局域网 IP，不要用 10.0.2.2',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final url = _ctl.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      Fluttertoast.showToast(msg: '地址需以 http:// 或 https:// 开头');
      return;
    }
    await updateBaseUrl(url);
    Fluttertoast.showToast(msg: '已切换到 $url');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('服务器地址'),
      subtitle: Text(currentBaseUrl, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _edit,
    );
  }
}

/// 通话录音自动上传开关
class _AutoUploadTile extends StatefulWidget {
  const _AutoUploadTile();

  @override
  State<_AutoUploadTile> createState() => _AutoUploadTileState();
}

class _AutoUploadTileState extends State<_AutoUploadTile> {
  bool _value = RecordingService.autoUpload;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('通话录音自动上传'),
      subtitle: const Text('挂断后自动回传最近录音并关联通话记录'),
      value: _value,
      activeColor: const Color(0xFF21C17A),
      onChanged: (val) async {
        await RecordingService.setAutoUpload(val);
        if (mounted) setState(() => _value = val);
      },
    );
  }
}
