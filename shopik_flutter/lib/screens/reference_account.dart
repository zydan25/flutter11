import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'screen_common.dart';
import 'reference_account_clean.dart';

export 'reference_account_clean.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final app = context.read<AppController>();
    setState(() => _loading = true);
    try {
      final res = await app.api.addresses();
      if (mounted) {
        setState(() {
          _addresses = res;
          app.addresses = res;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addresses = app.addresses;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العنوان', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العنوان من حسابك؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AppController>().api.deleteAddress(id);
      messenger.showSnackBar(const SnackBar(content: Text('تم حذف العنوان بنجاح')));
      await _fetchAddresses();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
  }

  void _openAddAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressBottomSheet(onSuccess: _fetchAddresses),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      title: 'عناوين التوصيل',
      color: AppColors.blue,
      actions: [
        IconButton(
          onPressed: _fetchAddresses,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _openAddAddressModal,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('إضافة عنوان جديد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
      child: _loading && _addresses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : RefreshIndicator(
              onRefresh: _fetchAddresses,
              color: AppColors.blue,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (_addresses.isEmpty)
                    EmptyState(
                      text: 'لا توجد عناوين توصيل مسجلة حالياً في حسابك.',
                      icon: Icons.location_off_outlined,
                      action: FilledButton(
                        onPressed: _openAddAddressModal,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                        child: const Text('إضافة عنوان الآن'),
                      ),
                    ),
                  for (final item in _addresses) ...[
                    _buildAddressCard(item),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 70),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id'] ?? ''}');
    final isDefault = item['is_default'] == true;
    final recipientName = item['recipient_name'] ?? item['name'] ?? item['full_name'] ?? 'عنوان التوصيل';
    final phone = item['phone'] ?? item['mobile'] ?? '';
    final cityName = item['city_name'] ?? item['city'] ?? item['governorate'] ?? 'اليمن';
    final line1 = item['street_address'] ?? item['line1'] ?? item['details'] ?? item['address'] ?? '';

    return PageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDefault ? AppColors.blue.withOpacity(0.12) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDefault ? AppColors.blue : const Color(0xFF64748B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$recipientName',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          const RefPill('افتراضي', color: AppColors.blue),
                        ],
                      ],
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        'هاتف المستلم: $phone',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              if (id != null)
                IconButton(
                  onPressed: () => _deleteAddress(id),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.map_rounded, size: 14, color: AppColors.blue),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '$cityName - $line1',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddAddressBottomSheet extends StatefulWidget {
  const _AddAddressBottomSheet({required this.onSuccess});
  final Future<void> Function() onSuccess;

  @override
  State<_AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<_AddAddressBottomSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController(text: 'صنعاء');
  final _street = TextEditingController();
  bool _isDefault = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _street.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final city = _city.text.trim();
    final street = _street.text.trim();

    if (name.isEmpty || phone.isEmpty || street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة (الاسم، الهاتف، العنوان)')),
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final app = context.read<AppController>();
      final body = {
        'recipient_name': name,
        'phone': phone,
        'city_name': city,
        'street_address': street,
        'is_default': _isDefault,
      };
      await app.api.createAddress(body);
      await app.refreshAll();
      await widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('تمت إضافة عنوان التوصيل بنجاح'), backgroundColor: AppColors.emerald));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('فشل إضافة العنوان: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: AppColors.blue, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('إضافة عنوان توصيل جديد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 18),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'اسم المستلم بالكامل *',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف للتواصل *',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _city,
              decoration: InputDecoration(
                labelText: 'المدينة / المحافظة *',
                prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _street,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'الشارع / الحي / معالم قريبة *',
                prefixIcon: const Icon(Icons.map_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val),
              title: const Text('تعيين كعنوان افتراضي للشحن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ العنوان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
