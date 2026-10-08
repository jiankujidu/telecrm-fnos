/// 跟进/回访模型（对齐后端 FollowUpVO / FollowUp）
class FollowUp {
  final int id;
  final int? customerId;
  final String customerName;
  final String phone;
  final String content;
  final String? tag;
  final String createdAt;

  const FollowUp({
    required this.id,
    this.customerId,
    this.customerName = '',
    this.phone = '',
    this.content = '',
    this.tag,
    this.createdAt = '',
  });

  factory FollowUp.fromJson(Map<String, dynamic> j) => FollowUp(
        id: _toInt(j['id']),
        customerId: j['customerId'],
        customerName: (j['customerName'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        tag: j['tag']?.toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );

  static int _toInt(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
}
