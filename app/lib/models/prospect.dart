/// 拓客企业模型（对齐后端 Prospect）
class Prospect {
  final int? id;
  final String company;
  final String? legalPerson;
  final String? phone;
  final String? province;
  final String? city;
  final String? address;
  final String? industry;
  final String? scale;
  final String? registeredCapital;
  final String? foundDate;
  final String? businessScope;
  final double? distance;

  Prospect({
    this.id,
    required this.company,
    this.legalPerson,
    this.phone,
    this.province,
    this.city,
    this.address,
    this.industry,
    this.scale,
    this.registeredCapital,
    this.foundDate,
    this.businessScope,
    this.distance,
  });

  factory Prospect.fromJson(Map<String, dynamic> j) => Prospect(
        id: j['id'],
        company: j['company'] ?? '',
        legalPerson: j['legalPerson'],
        phone: j['phone'],
        province: j['province'],
        city: j['city'],
        address: j['address'],
        industry: j['industry'],
        scale: j['scale'],
        registeredCapital: j['registeredCapital'],
        foundDate: j['foundDate'],
        businessScope: j['businessScope'],
        distance: j['distance'] != null ? (j['distance'] as num).toDouble() : null,
      );

  /// 转为联系人，用于「加入拨打任务」
  Map<String, String> toContact() => {
        'company': company,
        'name': legalPerson ?? '',
        'phone': phone ?? '',
        'address': address ?? '',
        'remark': '',
      };

  String get region => [province, city].where((e) => e != null && e!.isNotEmpty).join('-');
}
