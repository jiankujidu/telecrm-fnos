import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_task.dart';
import '../providers/dialer_session_provider.dart';

/// 悬浮窗拨号服务：与原生 FloatDialerService 通信，
/// 处理原生侧回传的「标记 / 下一通」回调（驱动全局拨号会话）。
class FloatingService {
  static const _channel = MethodChannel('com.telecrm/float');
  static ProviderContainer? _container;
  static bool _handlerSet = false;

  /// 初始化：注入全局 Riverpod 容器并注册原生回调
  static Future<void> init(ProviderContainer container) async {
    _container = container;
    if (!_handlerSet) {
      _channel.setMethodCallHandler(_handleNative);
      _handlerSet = true;
    }
  }

  /// 是否已授予悬浮窗权限
  static Future<bool> canDrawOverlay() async =>
      await _channel.invokeMethod<bool>('canDrawOverlay') ?? false;

  /// 跳转系统设置开启悬浮窗权限
  static Future<void> requestOverlayPermission() =>
      _channel.invokeMethod('openOverlaySettings');

  /// 启动悬浮窗前台服务
  static Future<void> start() => _channel.invokeMethod('start');

  /// 显示/更新悬浮窗并填充当前拨打项
  static Future<void> show({required CallTaskItem item, String? redialLabel}) =>
      _channel.invokeMethod('show', {
        'phone': item.phone,
        'name': item.name,
        'company': item.company,
        'taskItemId': item.id,
        'customerId': item.customerId,
        'redialLabel': redialLabel ?? '',
      });

  /// 隐藏悬浮窗（保留服务）
  static Future<void> hide() => _channel.invokeMethod('hide');

  /// 停止悬浮窗服务
  static Future<void> stop() => _channel.invokeMethod('stop');

  /// 原生侧回调：onMark（标记结果）/ onNext（下一通）
  static Future<dynamic> _handleNative(MethodCall call) async {
    final container = _container;
    if (container == null) return null;
    final notifier = container.read(dialerSessionProvider.notifier);
    if (call.method == 'onMark') {
      final args = call.arguments as Map<dynamic, dynamic>? ?? {};
      final result = (args['result'] as String?) ?? '';
      if (result.isNotEmpty) {
        try {
          await notifier.markAndAdvance(result);
        } catch (_) {
          // 标记失败由会话内部处理，这里吞掉避免原生侧阻塞
        }
      }
    } else if (call.method == 'onNext') {
      // 「下一通」语义：记为未接通并强制推进（跳过重拨）
      try {
        await notifier.markAndAdvance('not_answered', forceAdvance: true);
      } catch (_) {}
    }
    return null;
  }
}
