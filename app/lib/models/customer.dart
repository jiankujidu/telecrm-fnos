/// 客户模型
class Customer {
  final String id;
  final String? name;
  final String phone;
  final String? company;
  final String? address;
  final String? remark;
  final String? tags;

  const Customer({
    required this.id,
    this.name,
    required this.phone,
    this.company,
    this.address,
    this.remark,
    this.tags,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'].toString(),
        name: json['name'],
        phone: json['phone'],
        company: json['company'],
        address: json['address'],
        remark: json['remark'],
        tags: json['tags'],
      );
}
