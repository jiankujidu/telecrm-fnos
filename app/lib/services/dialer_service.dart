import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// 拨号结果
class DialResult {
  final bool ok;
  final String message;

  /// true 表示因为没权限而降级为「唤起拨号界面」，UI 上应提示去授权
  final bool needPermission;

  const DialResult(this.ok, this.message, {this.needPermission = false});
}

/// 拨号服务：Android 走 MethodChannel 直拨（无权限时自动降级为唤起拨号界面），iOS 走 url_launcher
class DialerService {
  static const _channel = MethodChannel('com.telecrm/dialer');

  /// 检查并申请拨号权限（Android）。iOS 无需权限。
  static Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.phone.status;
    if (status.isGranted) return true;
    final req = await Permission.phone.request();
    return req.isGranted;
  }

  /// 打开系统应用设置页，让用户手动授予权限
  static Future<void> openPermissionSettings() => openAppSettings();

  /// 拨号
  /// [phone] 号码，[simSlot] 卡1/卡2（-1 表示默认）
  static Future<DialResult> call(String phone, {int simSlot = -1}) async {
    final p = phone.trim();
    if (p.isEmpty) return const DialResult(false, '请先输入号码');

    // iOS：只能唤起系统拨号界面
    if (Platform.isIOS) {
      final uri = Uri(scheme: 'tel', path: p);
      try {
        final can = await canLaunchUrl(uri);
        if (!can) return const DialResult(false, '无法唤起拨号');
        final ok = await launchUrl(uri);
        return DialResult(ok, ok ? '' : '唤起拨号失败');
      } catch (e) {
        return DialResult(false, '拨号失败：$e');
      }
    }

    // Android：先拿权限，再由原生直拨；没权限也会降级成 ACTION_DIAL，保证点了一定有反应
    final granted = await ensurePermission();
    try {
      final res = await _channel.invokeMethod<Map>('call', {
        'phone': p,
        'simSlot': simSlot,
      });
      final map = (res ?? const {}).cast<String, dynamic>();
      final ok = map['ok'] == true;
      final msg = (map['message'] ?? '').toString();
      final needPermission = map['needPermission'] == true;
      return DialResult(ok, msg, needPermission: needPermission || !granted);
    } on PlatformException catch (e) {
      return DialResult(false, '拨号失败：${e.message ?? e.code}');
    } catch (e) {
      // 兜底：原生通道异常时直接用 url_launcher 唤起拨号界面
      try {
        final uri = Uri(scheme: 'tel', path: p);
        final ok = await launchUrl(uri);
        return DialResult(ok, ok ? '' : '唤起拨号失败');
      } catch (_) {
        return DialResult(false, '拨号失败：$e');
      }
    }
  }

  /// 读取系统通话记录（Android）
  static Future<List<Map<String, dynamic>>> readCallLogs() async {
    try {
      final List<dynamic>? logs =
          await _channel.invokeMethod<List<dynamic>>('readCallLogs');
      return (logs ?? []).cast<Map<String, dynamic>>();
    } on PlatformException {
      return [];
    }
  }

  /// 扫描系统通话录音文件（Android，各厂商路径不同）
  static Future<List<String>> scanRecordings() async {
    try {
      final List<dynamic>? files =
          await _channel.invokeMethod<List<dynamic>>('scanRecordings');
      return (files ?? []).cast<String>();
    } on PlatformException {
      return [];
    }
  }
}
