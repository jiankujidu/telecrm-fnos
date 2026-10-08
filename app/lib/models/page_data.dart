/// 通用分页返回结构（对齐后端 PageResult）
class PageData<T> {
  final List<T> records;
  final int total;
  final int size;
  final int current;

  PageData({
    required this.records,
    required this.total,
    required this.size,
    required this.current,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final list = (json['records'] as List?) ?? [];
    return PageData(
      records: list.map(fromJsonT).toList(),
      total: _toInt(json['total']),
      size: _toInt(json['size']),
      current: _toInt(json['current']),
    );
  }

  static int _toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
}
