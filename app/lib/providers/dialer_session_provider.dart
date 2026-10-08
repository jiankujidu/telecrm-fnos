import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../api/call_task_api.dart';
import '../api/call_record_api.dart';
import '../models/call_task.dart';
import '../models/call_record.dart';
import '../services/dialer_service.dart';
import '../services/floating_service.dart';
import '../services/recording_service.dart';

/// 自动拨号会话状态：单一事实来源，页面与悬浮窗共享同一份拨打列表
class DialerSession {
  final int? taskId;
  final List<CallTaskItem> items;
  final bool loading;
  final String? error;
  final int simSlot;
  final bool floatEnabled;

  /// 未接通自动重拨上限（0 = 关闭）
  final int maxRedial;

  /// 各任务明细已重拨次数：taskItemId -> count
  final Map<int, int> redialCounts;

  const DialerSession({
    this.taskId,
    this.items = const [],
    this.loading = false,
    this.error,
    this.simSlot = 0,
    this.floatEnabled = false,
    this.maxRedial = 0,
    this.redialCounts = const {},
  });

  DialerSession copyWith({
    int? taskId,
    List<CallTaskItem>? items,
    bool? loading,
    String? error,
    int? simSlot,
    bool? floatEnabled,
    int? maxRedial,
    Map<int, int>? redialCounts,
  }) =>
      DialerSession(
        taskId: taskId ?? this.taskId,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        simSlot: simSlot ?? this.simSlot,
        floatEnabled: floatEnabled ?? this.floatEnabled,
        maxRedial: maxRedial ?? this.maxRedial,
        redialCounts: redialCounts ?? this.redialCounts,
      );

  /// 当前待拨打项（第一个未拨打）
  CallTaskItem? get current {
    for (final e in items) {
      if (!e.isDialed) return e;
    }
    return null;
  }

  int get dialedCount => items.where((e) => e.isDialed).length;

  /// 指定明细的重拨提示（如「重拨 2/3」），未重拨返回 null
  String? redialLabelFor(int id) {
    final c = redialCounts[id] ?? 0;
    if (c <= 0 || maxRedial <= 0) return null;
    return '重拨 $c/$maxRedial';
  }
}

final dialerSessionProvider =
    StateNotifierProvider<DialerSessionNotifier, DialerSession>((ref) => DialerSessionNotifier());

class DialerSessionNotifier extends StateNotifier<DialerSession> {
  DialerSessionNotifier() : super(const DialerSession());

  /// 触发重拨的结果集合（未接通才重拨，空号/已接通不重拨）
  static const Set<String> _redialResults = {CallResult.notAnswered};

  void setSimSlot(int v) => state = state.copyWith(simSlot: v);

  /// 转发给 state：指定明细的重拨提示（如「重拨 2/3」）
  String? redialLabelFor(int id) => state.redialLabelFor(id);

  /// 设置未接通自动重拨次数（0 = 关闭）
  void setMaxRedial(int v) => state = state.copyWith(maxRedial: v < 0 ? 0 : v);

  /// 加载任务明细（进入自动拨号时调用）
  Future<void> load(int taskId) async {
    state = state.copyWith(taskId: taskId, loading: true, error: null);
    try {
      final p = await CallTaskApi.items(taskId, current: 1, size: 200);
      state = state.copyWith(items: p.records, loading: false, redialCounts: const {});
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceFirst('ApiException: ', ''), loading: false);
    }
  }

  /// 开启/关闭悬浮窗连续拨打
  Future<void> setFloatEnabled(bool enabled) async {
    if (enabled) {
      final ok = await FloatingService.canDrawOverlay();
      if (!ok) {
        await FloatingService.requestOverlayPermission();
        throw Exception('请在系统设置中开启“显示悬浮窗”权限后返回');
      }
      state = state.copyWith(floatEnabled: true);
      final cur = state.current;
      if (cur != null) {
        _dial(cur.phone);
        await FloatingService.show(item: cur, redialLabel: redialLabelFor(cur.id));
      }
    } else {
      state = state.copyWith(floatEnabled: false);
      await FloatingService.hide();
    }
  }

  /// 拨号并提示失败原因
  Future<bool> _dial(String phone) async {
    final r = await DialerService.call(phone, simSlot: state.simSlot);
    if (r.message.isNotEmpty) Fluttertoast.showToast(msg: r.message);
    if (!r.ok && r.needPermission) await DialerService.openPermissionSettings();
    return r.ok;
  }

  /// 标记当前项并推进（自动模式核心）：写入记录 → 未接通自动重拨 / 否则推进下一通
  /// [forceAdvance] = true 时（如悬浮窗「下一通」）跳过重拨逻辑直接推进
  Future<void> markAndAdvance(String result, {bool forceAdvance = false}) async {
    final cur = state.current;
    if (cur == null) return;
    await CallRecordApi.add(CallRecordSubmit(
      taskItemId: cur.id,
      customerId: cur.customerId,
      phone: cur.phone,
      result: result,
    ));

    final canRedial = !forceAdvance &&
        _redialResults.contains(result) &&
        state.maxRedial > 0 &&
        (state.redialCounts[cur.id] ?? 0) < state.maxRedial;

    if (canRedial) {
      final nextCount = (state.redialCounts[cur.id] ?? 0) + 1;
      state = state.copyWith(redialCounts: {...state.redialCounts, cur.id: nextCount});
      // 不 reload：保持 cur 为当前项，直接重拨同一号码
      _dial(cur.phone);
      if (state.floatEnabled) {
        await FloatingService.show(item: cur, redialLabel: redialLabelFor(cur.id));
      }
      return;
    }

    await reload();
    await _afterMark(cur.phone);
  }

  /// 标记完成后的公共步骤：回传录音 + 自动拨打下一通/收尾
  Future<void> _afterMark(String phone) async {
    if (RecordingService.autoUpload) {
      try {
        await RecordingService.uploadForPhone(phone);
      } catch (_) {
        // 无录音可忽略
      }
    }
    final next = state.current;
    if (next == null) {
      if (state.floatEnabled) await FloatingService.hide();
      return;
    }
    _dial(next.phone);
    if (state.floatEnabled) await FloatingService.show(item: next, redialLabel: redialLabelFor(next.id));
  }

  /// 重新拉取明细（刷新 isDialed 状态）
  Future<void> reload() async {
    if (state.taskId != null) await load(state.taskId!);
  }
}
