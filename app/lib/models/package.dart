import 'package:flutter/material.dart';

/// 套餐 / 订单 / 兑换码 模型（对齐后端 Package / Order / VipCode）

class Package {
  final int? id;
  final String? name;
  final String? type; // vip=会员套餐, minutes=分钟包
  final int? price; // 单位：分
  final int? minutes; // 通话分钟
  final int? durationDays; // 有效天数
  final int? status; // 0上架 1下架

  Package({
    this.id,
    this.name,
    this.type,
    this.price,
    this.minutes,
    this.durationDays,
    this.status,
  });

  factory Package.fromJson(Map<String, dynamic> j) => Package(
        id: j['id'],
        name: j['name'],
        type: j['type'],
        price: j['price'],
        minutes: j['minutes'],
        durationDays: j['durationDays'],
        status: j['status'],
      );

  /// 价格（元）
  String get priceYuan =>
      price == null ? '—' : '¥${(price! / 100).toStringAsFixed(2)}';

  String get typeLabel => type == 'vip' ? '会员套餐' : '分钟包';

  /// 套餐卖点文案
  String get benefit {
    if (type == 'vip') {
      return durationDays != null ? '有效期 $durationDays 天' : '会员权益';
    }
    return minutes != null ? '含 $minutes 分钟通话' : '通话时长包';
  }
}

class Order {
  final int? id;
  final int? packageId;
  final int? amount; // 单位：分
  final int? status; // 0待支付 1已支付 2已取消
  final String? payTime;
  final String? packageName; // 关联展示用，由客户端 join

  Order({
    this.id,
    this.packageId,
    this.amount,
    this.status,
    this.payTime,
    this.packageName,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        packageId: j['packageId'],
        amount: j['amount'],
        status: j['status'],
        payTime: j['payTime']?.toString(),
      );

  String get amountYuan =>
      amount == null ? '—' : '¥${(amount! / 100).toStringAsFixed(2)}';

  static const _statusLabels = ['待支付', '已支付', '已取消'];
  String get statusLabel => _statusLabels[(status ?? 0).clamp(0, 2)];

  Color get statusColor {
    switch (status ?? 0) {
      case 1:
        return const Color(0xFF21C17A);
      case 2:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}

class VipCode {
  final int? id;
  final String? code;
  final int? status; // 0未使用 1已使用
  final String? usedAt;

  VipCode({this.id, this.code, this.status, this.usedAt});

  factory VipCode.fromJson(Map<String, dynamic> j) => VipCode(
        id: j['id'],
        code: j['code'],
        status: j['status'],
        usedAt: j['usedAt']?.toString(),
      );
}
