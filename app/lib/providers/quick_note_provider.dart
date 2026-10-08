import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quick_note.dart';
import '../config/constants.dart';

/// 快捷备注状态管理：最多8个，每个≤4汉字
final quickNoteProvider =
    StateNotifierProvider<QuickNoteNotifier, List<QuickNote>>((ref) {
  return QuickNoteNotifier();
});

class QuickNoteNotifier extends StateNotifier<List<QuickNote>> {
  QuickNoteNotifier() : super(const []) {
    _load();
  }

  static const _spKey = 'quick_notes';

  /// 默认备注
  static const List<String> defaults = [
    '不需要',
    '已买',
    '晚点打',
    '直接挂断',
    '不接'
  ];

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_spKey);
    if (raw == null || raw.isEmpty) {
      state = defaults
          .asMap()
          .map((i, e) => MapEntry(i, QuickNote(id: '$i', label: e)))
          .values
          .toList();
    } else {
      state = raw
          .asMap()
          .map((i, e) => MapEntry(i, QuickNote(id: '$i', label: e)))
          .values
          .toList();
    }
  }

  /// 新增（受上限与长度约束）
  Future<void> add(String label) async {
    if (state.length >= Constants.maxQuickNotes) return;
    if (label.length > Constants.maxQuickNoteLength) {
      label = label.substring(0, Constants.maxQuickNoteLength);
    }
    state = [...state, QuickNote(id: DateTime.now().toString(), label: label)];
    await _persist();
  }

  /// 修改
  Future<void> update(String id, String label) async {
    state = [
      for (final n in state)
        if (n.id == id)
          QuickNote(
            id: n.id,
            label: label.length > Constants.maxQuickNoteLength
                ? label.substring(0, Constants.maxQuickNoteLength)
                : label,
          )
        else
          n
    ];
    await _persist();
  }

  /// 删除
  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_spKey, state.map((e) => e.label).toList());
  }
}
