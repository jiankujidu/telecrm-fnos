import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/call_record_api.dart';
import '../services/dialer_service.dart';

/// 通话录音自动回传服务
///
/// 原生层（MainActivity）在通话挂断时通过 MethodChannel 回调 [onCallEnded]，
/// 本服务在开启「自动上传」后：抓取最近录音文件 → 找到该号码最近一条通话记录
/// → 调用 [CallRecordApi.uploadRecording] 自动回传并关联（复用 dio 的 Bearer 鉴权）。
class RecordingService {
  static const MethodChannel _channel = MethodChannel('com.telecrm/recording');
  static const String _autoKey = 'rec_auto_upload';

  static bool _autoUpload = false;

  /// 是否开启自动上传
  static bool get autoUpload => _autoUpload;

  /// 初始化：恢复开关、申请权限、注册原生回调与监听
  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _autoUpload = sp.getBool(_autoKey) ?? false;
    _channel.setMethodCallHandler(_handleNative);
    if (_autoUpload) await _ensureMonitor();
  }

  /// 设置自动上传开关（持久化）；开启时申请权限并启动原生监听
  static Future<void> setAutoUpload(bool value) async {
    _autoUpload = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_autoKey, value);
    if (value) await _ensureMonitor();
  }

  /// 申请 READ_PHONE_STATE 并通知原生注册通话状态监听
  static Future<void> _ensureMonitor() async {
    try {
      if (await Permission.phone.status.isDenied) {
        await Permission.phone.request();
      }
    } catch (_) {}
    try {
      await _channel.invokeMethod('enableCallMonitor');
    } catch (_) {}
  }

  static Future<dynamic> _handleNative(MethodCall call) async {
    if (call.method == 'onCallEnded') {
      final phone = call.arguments is Map ? (call.arguments['phone'] as String? ?? '') : '';
      if (_autoUpload) uploadForPhone(phone);
    }
    return null;
  }

  /// 自动回传最近录音并关联到对应通话记录
  ///
  /// 先按 [phone] 匹配最近一条通话记录，未匹配到则取最近一条；
  /// 已有关联录音则跳过。供原生挂断回调与拨号页标记成功后调用。
  static Future<void> uploadForPhone(String phone) async {
    try {
      final files = await DialerService.scanRecordings();
      if (files.isEmpty) return;
      final path = files.first;

      final data = await CallRecordApi.list(current: 1, size: 30);
      if (data.records.isEmpty) return;

      // 优先匹配同一号码的最近记录，否则取最近一条
      final target = data.records.where((r) => r.phone == phone).isNotEmpty
          ? data.records.firstWhere((r) => r.phone == phone)
          : data.records.first;

      if (target.recordingUrl.isNotEmpty) return; // 已有关联录音则不覆盖
      await CallRecordApi.uploadRecording(target.id, path);
    } catch (_) {
      // 自动回传失败静默处理，用户仍可在「通话记录」页手动上传
    }
  }
}
