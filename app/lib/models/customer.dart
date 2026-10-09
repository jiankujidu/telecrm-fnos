/// 客户模型
class Customer {
  final String id;
  final String? name;
  final String phone;
  final String? company;
  final String? address;
  final String? remark;
  final String? tags;
  final bool pinned;

  const Customer({
    required this.id,
    this.name,
    required this.phone,
    this.company,
    this.address,
    this.remark,
    this.tags,
    this.pinned = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'].toString(),
        name: json['name'],
        phone: json['phone'],
        company: json['company'],
        address: json['address'],
        remark: json['remark'],
        tags: json['tags'],
        pinned: json['pinned'] == 1 || json['pinned'] == true,
      );

  Customer copyWith({bool? pinned}) => Customer(
        id: id,
        name: name,
        phone: phone,
        company: company,
        address: address,
        remark: remark,
        tags: tags,
        pinned: pinned ?? this.pinned,
      );
}
