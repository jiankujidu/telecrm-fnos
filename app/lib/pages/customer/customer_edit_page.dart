import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../api/customer_api.dart';
import '../../models/customer.dart';
import '../../models/customer_profile.dart';
import '../../config/constants.dart';

/// 客户编辑 / 新增页：基本信息 + 客户画像（打电话时整理客户信息）
/// [customerId] 为空表示新增
class CustomerEditPage extends StatefulWidget {
  final int? customerId;
  const CustomerEditPage({super.key, this.customerId});

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _address = TextEditingController();
  final _remark = TextEditingController();
  final _tags = TextEditingController();

  final _age = TextEditingController();
  final _birthday = TextEditingController();
  final _industry = TextEditingController();
  final _position = TextEditingController();
  final _wechat = TextEditingController();
  final _email = TextEditingController();
  final _secondPhone = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _budget = TextEditingController();
  final _channel = TextEditingController();
  final _product = TextEditingController();
  final _pain = TextEditingController();
  final _competitor = TextEditingController();
  final _profileTags = TextEditingController();
  final _summary = TextEditingController();

  String _gender = '';
  String _intentLevel = '';
  int _isDecision = 0;
  String? _nextFollowAt;

  bool _loading = true;
  bool _saving = false;

  bool get _isNew => widget.customerId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _company, _address, _remark, _tags, _age, _birthday,
      _industry, _position, _wechat, _email, _secondPhone, _province, _city,
      _budget, _channel, _product, _pain, _competitor, _profileTags, _summary,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (_isNew) {
      setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        CustomerApi.detail(widget.customerId!),
        CustomerApi.getProfile(widget.customerId!),
      ]);
      final c = results[0] as Customer;
      final p = results[1] as CustomerProfile;
      _name.text = c.name ?? '';
      _phone.text = c.phone;
      _company.text = c.company ?? '';
      _address.text = c.address ?? '';
      _remark.text = c.remark ?? '';
      _tags.text = c.tags ?? '';

      _gender = p.gender;
      _age.text = p.age?.toString() ?? '';
      _birthday.text = p.birthday;
      _industry.text = p.industry;
      _position.text = p.position;
      _wechat.text = p.wechat;
      _email.text = p.email;
      _secondPhone.text = p.secondPhone;
      _province.text = p.province;
      _city.text = p.city;
      _intentLevel = p.intentLevel;
      _budget.text = p.budget;
      _isDecision = p.isDecision;
      _channel.text = p.channel;
      _product.text = p.productInterest;
      _pain.text = p.painPoint;
      _competitor.text = p.competitor;
      _nextFollowAt = p.nextFollowAt;
      _profileTags.text = p.profileTags;
      _summary.text = p.summary;
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: '加载失败：${e.toString().replaceFirst('ApiException: ', '')}');
    }
  }

  Future<void> _save() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: '手机号不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      int id;
      if (_isNew) {
        final c = await CustomerApi.create(
          name: _name.text.trim(),
          phone: phone,
          company: _company.text.trim(),
          address: _address.text.trim(),
          remark: _remark.text.trim(),
          tags: _tags.text.trim(),
        );
        id = int.parse(c.id);
      } else {
        id = widget.customerId!;
        await CustomerApi.update(
          id,
          name: _name.text.trim(),
          phone: phone,
          company: _company.text.trim(),
          address: _address.text.trim(),
          remark: _remark.text.trim(),
          tags: _tags.text.trim(),
        );
      }
      await CustomerApi.saveProfile(id, CustomerProfile(
        gender: _gender,
        age: int.tryParse(_age.text.trim()),
        birthday: _birthday.text.trim(),
        industry: _industry.text.trim(),
        position: _position.text.trim(),
        wechat: _wechat.text.trim(),
        email: _email.text.trim(),
        secondPhone: _secondPhone.text.trim(),
        province: _province.text.trim(),
        city: _city.text.trim(),
        intentLevel: _intentLevel,
        budget: _budget.text.trim(),
        isDecision: _isDecision,
        channel: _channel.text.trim(),
        productInterest: _product.text.trim(),
        painPoint: _pain.text.trim(),
        competitor: _competitor.text.trim(),
        nextFollowAt: _nextFollowAt,
        profileTags: _profileTags.text.trim(),
        summary: _summary.text.trim(),
      ));
      if (!mounted) return;
      Fluttertoast.showToast(msg: '已保存');
      Navigator.of(context).pop(true);
    } catch (e) {
      Fluttertoast.showToast(
          msg: '保存失败：${e.toString().replaceFirst('ApiException: ', '')}',
          toastLength: Toast.LENGTH_LONG);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_isNew) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除客户'),
        content: Text('确认删除「${_name.text.isNotEmpty ? _name.text : _phone.text}」及其画像？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CustomerApi.remove(widget.customerId!);
      if (!mounted) return;
      Fluttertoast.showToast(msg: '已删除');
      Navigator.of(context).pop(true);
    } catch (e) {
      Fluttertoast.showToast(msg: '删除失败：${e.toString().replaceFirst('ApiException: ', '')}');
    }
  }

  Future<void> _pickNextFollow() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() {
      _nextFollowAt =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    final green = Color(Constants.primaryColorValue);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新增客户' : '编辑客户画像'),
        actions: [
          if (!_isNew)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _section('基本信息', green),
                _field(_name, '姓名', Icons.person_outline),
                _field(_phone, '手机号 *', Icons.phone, inputType: TextInputType.phone),
                _field(_company, '公司', Icons.business_outlined),
                _field(_address, '地址', Icons.place_outlined),
                _field(_tags, '标签（逗号分隔）', Icons.label_outline),
                _field(_remark, '备注', Icons.note_outlined, maxLines: 2),

                _section('客户画像', green),
                _chipRow('性别', ['', '男', '女'], _gender, (v) => setState(() => _gender = v),
                    labelOf: (v) => v.isEmpty ? '未知' : v),
                _chipRow('意向等级', ['', 'A', 'B', 'C', 'D'], _intentLevel,
                    (v) => setState(() => _intentLevel = v),
                    labelOf: (v) => v.isEmpty ? '未评估' : '$v 级'),
                SwitchListTile(
                  title: const Text('是否决策人'),
                  value: _isDecision == 1,
                  activeColor: green,
                  onChanged: (v) => setState(() => _isDecision = v ? 1 : 0),
                ),
                Row(
                  children: [
                    Expanded(child: _field(_age, '年龄', Icons.cake_outlined, inputType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_birthday, '生日', Icons.event)),
                  ],
                ),
                _field(_industry, '行业', Icons.factory_outlined),
                _field(_position, '职位', Icons.work_outline),
                Row(
                  children: [
                    Expanded(child: _field(_wechat, '微信', Icons.chat_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_email, '邮箱', Icons.mail_outline)),
                  ],
                ),
                _field(_secondPhone, '备用电话', Icons.phone_forwarded_outlined, inputType: TextInputType.phone),
                Row(
                  children: [
                    Expanded(child: _field(_province, '省份', Icons.map_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_city, '城市', Icons.location_city_outlined)),
                  ],
                ),
                _field(_budget, '预算', Icons.attach_money),
                _field(_channel, '来源渠道', Icons.route_outlined),
                _field(_product, '感兴趣产品', Icons.shopping_bag_outlined),
                _field(_competitor, '在用竞品', Icons.compare_arrows),
                _field(_pain, '客户痛点', Icons.healing_outlined, maxLines: 2),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.alarm, color: green),
                  title: Text(_nextFollowAt == null ? '下次跟进时间（未设置）' : '下次跟进：$_nextFollowAt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickNextFollow,
                ),
                _field(_profileTags, '画像标签（逗号分隔）', Icons.local_offer_outlined),
                _field(_summary, '画像小结', Icons.summarize_outlined, maxLines: 3),

                const SizedBox(height: 20),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('保存', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _section(String t, Color green) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: green)),
      );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: inputType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _chipRow(
    String title,
    List<String> values,
    String current,
    ValueChanged<String> onPick, {
    String Function(String)? labelOf,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(width: 88, child: Text(title, style: const TextStyle(color: Colors.grey))),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: values.map((v) {
                  final selected = v == current;
                  return ChoiceChip(
                    label: Text(labelOf != null ? labelOf(v) : v),
                    selected: selected,
                    selectedColor: Color(Constants.primaryColorValue).withOpacity(0.18),
                    onSelected: (_) => onPick(v),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
}
