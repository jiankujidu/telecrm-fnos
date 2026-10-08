/// 客户画像模型：打电话过程中整理的客户详细信息
class CustomerProfile {
  final int? id;
  final int? customerId;
  final String gender;
  final int? age;
  final String birthday;
  final String industry;
  final String position;
  final String wechat;
  final String email;
  final String secondPhone;
  final String province;
  final String city;
  final String intentLevel;
  final String budget;
  final int isDecision;
  final String channel;
  final String productInterest;
  final String painPoint;
  final String competitor;
  final String? nextFollowAt;
  final int? callCount;
  final String? lastCalledAt;
  final String profileTags;
  final String summary;

  const CustomerProfile({
    this.id,
    this.customerId,
    this.gender = '',
    this.age,
    this.birthday = '',
    this.industry = '',
    this.position = '',
    this.wechat = '',
    this.email = '',
    this.secondPhone = '',
    this.province = '',
    this.city = '',
    this.intentLevel = '',
    this.budget = '',
    this.isDecision = 0,
    this.channel = '',
    this.productInterest = '',
    this.painPoint = '',
    this.competitor = '',
    this.nextFollowAt,
    this.callCount,
    this.lastCalledAt,
    this.profileTags = '',
    this.summary = '',
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> j) => CustomerProfile(
        id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? ''),
        customerId: j['customerId'] is int
            ? j['customerId']
            : int.tryParse(j['customerId']?.toString() ?? ''),
        gender: (j['gender'] ?? '').toString(),
        age: j['age'] is int ? j['age'] : int.tryParse(j['age']?.toString() ?? ''),
        birthday: (j['birthday'] ?? '').toString(),
        industry: (j['industry'] ?? '').toString(),
        position: (j['position'] ?? '').toString(),
        wechat: (j['wechat'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        secondPhone: (j['secondPhone'] ?? '').toString(),
        province: (j['province'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        intentLevel: (j['intentLevel'] ?? '').toString(),
        budget: (j['budget'] ?? '').toString(),
        isDecision: j['isDecision'] == 1 || j['isDecision'] == true ? 1 : 0,
        channel: (j['channel'] ?? '').toString(),
        productInterest: (j['productInterest'] ?? '').toString(),
        painPoint: (j['painPoint'] ?? '').toString(),
        competitor: (j['competitor'] ?? '').toString(),
        nextFollowAt: j['nextFollowAt']?.toString(),
        callCount: j['callCount'] is int
            ? j['callCount']
            : int.tryParse(j['callCount']?.toString() ?? ''),
        lastCalledAt: j['lastCalledAt']?.toString(),
        profileTags: (j['profileTags'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (customerId != null) 'customerId': customerId,
        'gender': gender,
        'age': age,
        'birthday': birthday,
        'industry': industry,
        'position': position,
        'wechat': wechat,
        'email': email,
        'secondPhone': secondPhone,
        'province': province,
        'city': city,
        'intentLevel': intentLevel,
        'budget': budget,
        'isDecision': isDecision,
        'channel': channel,
        'productInterest': productInterest,
        'painPoint': painPoint,
        'competitor': competitor,
        'nextFollowAt': nextFollowAt,
        'profileTags': profileTags,
        'summary': summary,
      };

  CustomerProfile copyWith({
    String? gender,
    int? age,
    String? birthday,
    String? industry,
    String? position,
    String? wechat,
    String? email,
    String? secondPhone,
    String? province,
    String? city,
    String? intentLevel,
    String? budget,
    int? isDecision,
    String? channel,
    String? productInterest,
    String? painPoint,
    String? competitor,
    String? nextFollowAt,
    String? profileTags,
    String? summary,
  }) =>
      CustomerProfile(
        id: id,
        customerId: customerId,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        birthday: birthday ?? this.birthday,
        industry: industry ?? this.industry,
        position: position ?? this.position,
        wechat: wechat ?? this.wechat,
        email: email ?? this.email,
        secondPhone: secondPhone ?? this.secondPhone,
        province: province ?? this.province,
        city: city ?? this.city,
        intentLevel: intentLevel ?? this.intentLevel,
        budget: budget ?? this.budget,
        isDecision: isDecision ?? this.isDecision,
        channel: channel ?? this.channel,
        productInterest: productInterest ?? this.productInterest,
        painPoint: painPoint ?? this.painPoint,
        competitor: competitor ?? this.competitor,
        nextFollowAt: nextFollowAt ?? this.nextFollowAt,
        callCount: callCount,
        lastCalledAt: lastCalledAt,
        profileTags: profileTags ?? this.profileTags,
        summary: summary ?? this.summary,
      );
}
