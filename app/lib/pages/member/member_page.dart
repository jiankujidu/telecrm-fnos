import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/constants.dart';
import '../../api/package_api.dart';
import '../../models/package.dart';
import '../../models/page_data.dart';
import '../../providers/auth_provider.dart';

/// 会员中心：套餐选购、VIP码兑换、我的订单
class MemberPage extends ConsumerStatefulWidget {
  const MemberPage({super.key});

  @override
  ConsumerState<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends ConsumerState<MemberPage> {
  List<Package> _packages = [];
  List<Order> _orders = [];
  bool _loading = false;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Map<int, String> get _packageNameMap =>
      {for (final p in _packages) p.id!: p.name ?? '套餐'};

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PackageApi.packages(),
        PackageApi.orders(),
      ]);
      _packages = results[0] as List<Package>;
      final orderPage = results[1] as PageData<Order>;
      _orders = orderPage.records; // 套餐名由 _packageNameMap 在 UI 关联
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _orderName(Order o) =>
      o.packageName ?? _packageNameMap[o.packageId] ?? '套餐 #${o.packageId}';

  Future<void> _buy(Package p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('${p.name}\n${p.benefit}\n应付：${p.priceYuan}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认支付'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final orderId = await PackageApi.createOrder(p.id!);
      await PackageApi.payOrder(orderId); // 演示环境模拟支付成功
      Fluttertoast.showToast(msg: '购买成功');
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
      setState(() => _loading = false);
    }
  }

  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      Fluttertoast.showToast(msg: '请输入兑换码');
      return;
    }
    setState(() => _loading = true);
    try {
      await PackageApi.redeem(code);
      Fluttertoast.showToast(msg: '兑换成功');
      _codeCtrl.clear();
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('ApiException: ', ''));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('会员中心')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // 会员概览
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(Constants.primaryColorValue), const Color(0xFF16A567)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.verified_user, color: Color(0xFF21C17A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nickname,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('电销帮会员 · 畅享自动拨号与大数据拓客',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('推荐套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // 套餐网格
            if (_loading && _packages.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_packages.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('暂无上架套餐', style: TextStyle(color: Colors.grey))))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                  children: _packages.map(_buildPackageCard).toList(),
                ),
              ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('VIP 兑换码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: '输入兑换码，如 VIPXXXX...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading ? null : _redeem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(Constants.primaryColorValue),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('兑换'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('我的订单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            _buildOrderList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package p) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p.typeLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF16A567))),
            ),
            const SizedBox(height: 8),
            Text(p.name ?? '套餐', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(p.benefit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.priceYuan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF21C17A))),
                InkWell(
                  onTap: () => _buy(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Color(Constants.primaryColorValue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('购买', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_orders.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16), child: Text('暂无订单', style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = _orders[i];
        return Card(
          child: ListTile(
            title: Text(_orderName(o)),
            subtitle: Text(o.amountYuan),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: o.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(o.statusLabel, style: TextStyle(fontSize: 12, color: o.statusColor)),
            ),
          ),
        );
      },
    );
  }
}
