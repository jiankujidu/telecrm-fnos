/// 快捷备注模型
class QuickNote {
  final String id;
  final String label;

  const QuickNote({required this.id, required this.label});

  factory QuickNote.fromJson(Map<String, dynamic> json) =>
      QuickNote(id: json['id'], label: json['label']);

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}
