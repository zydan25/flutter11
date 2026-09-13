import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'reference_store.dart';
import 'reference_account.dart';
import 'reference_security.dart';
import 'screen_common.dart';
import 'payment_screen.dart';
import 'operations_screen.dart';
import 'games_services_screen.dart';
import 'statement_screen.dart';
import 'reports_screen.dart';
import 'transfer_screen.dart';
import 'wifi_screen.dart';
export 'payment_screen.dart';
export 'games_services_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    MainHomeScreen(),
    PaymentScreen(),
    StoreView(),
    OperationsScreen(),
    UserProfileEditScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'حسابي', Icons.home_rounded, Icons.home_outlined, AppColors.burgundy),
              _buildNavItem(1, 'السداد', Icons.credit_card_rounded, Icons.credit_card_outlined, AppColors.burgundy),
              _buildNavItem(2, 'المتجر', Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, AppColors.emerald),
              _buildNavItem(3, 'العمليات', Icons.history_rounded, Icons.history_outlined, AppColors.blue),
              _buildNavItem(4, 'الإعدادات', Icons.settings_rounded, Icons.settings_outlined, const Color(0xFF475569)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int itemIndex, String label, IconData activeIcon, IconData inactiveIcon, Color activeColor) {
    final isSelected = index == itemIndex;
    return InkWell(
      onTap: () => setState(() => index = itemIndex),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : AppColors.muted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? activeColor : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  bool hidden = false;
  bool refreshing = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final user = app.user;
    final first = user?.name.trim().isNotEmpty == true ? user!.name.trim().substring(0, 1) : 'ش';
    final shortcuts = <_HomeShortcut>[
      const _HomeShortcut('شبكة السداد', 'خدمات الاتصالات والباقات', Icons.credit_card_rounded, AppColors.burgundy, 1),
      const _HomeShortcut('متجر شبيك', 'المنتجات والمتاجر والسلل', Icons.storefront_rounded, AppColors.emerald, 2),
      _HomeShortcut('طلباتي (${app.orders.length})', 'متابعة وفحص الطلبات الحالية', Icons.shopping_bag_rounded, AppColors.emerald, 11),
      const _HomeShortcut('سجل العمليات', 'العمليات الحقيقية من الخادم', Icons.receipt_long_rounded, AppColors.blue, 3),
      const _HomeShortcut('كشف الحساب', 'الرصيد والقيود المحاسبية', Icons.account_balance_wallet_rounded, AppColors.teal, 4),
      const _HomeShortcut('التقارير والإحصائيات', 'مبيعات الخدمات والأداء', Icons.bar_chart_rounded, AppColors.indigo, 5),
      const _HomeShortcut('تحويل لمشترك', 'إرسال رصيد لمشترك آخر', Icons.send_rounded, AppColors.amber, 6),
      const _HomeShortcut('كروت الوايفاي', 'الشبكات والكروت', Icons.wifi_rounded, AppColors.teal, 7),
      const _HomeShortcut('الألعاب والبرامج', 'الشحن والخدمات الرقمية', Icons.sports_esports_rounded, AppColors.purple, 8),
      const _HomeShortcut('البصمة والأمان', 'حماية الحساب والجهاز', Icons.fingerprint_rounded, Color(0xFF475569), 9),
      const _HomeShortcut('عناوين التوصيل', 'إدارة عناوين الشحن', Icons.location_on_rounded, AppColors.blue, 10),
    ];

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.burgundy,
        onRefresh: app.refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 28),
          children: [
            Row(
              children: [
                CircleAvatar(radius: 21, backgroundColor: AppColors.burgundy, child: Text(first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('تطبيق شبيك وسوق بلس', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    Row(children: [
                      Flexible(child: Text(user?.name.isNotEmpty == true ? user!.name : 'حسابي الرقمي', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                      const SizedBox(width: 5),
                      const StatusBadge(text: 'موثق ✓'),
                    ]),
                  ]),
                ),
                IconButton(
                  onPressed: refreshing ? null : () async {
                    setState(() => refreshing = true);
                    await app.refreshAll();
                    if (mounted) setState(() => refreshing = false);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), border: Border.all(color: const Color(0xFFA7F3D0)), borderRadius: BorderRadius.circular(17)),
              child: Row(
                children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 9),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.name.isNotEmpty == true ? user!.name : 'العميل المعتمد', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                    Text('الهاتف: ${user?.phone ?? ''}  •  المحافظة: ${user?.governorate ?? ''}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF047857), fontWeight: FontWeight.w700)),
                  ])),
                  const StatusBadge(text: 'عميل معتمد', color: AppColors.emerald),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.burgundyLight, AppColors.burgundy, AppColors.burgundyDark]),
                borderRadius: BorderRadius.circular(21),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.credit_card_rounded, color: Color(0xFFFDE68A), size: 19),
                    const SizedBox(width: 7),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('بطاقة الرصيد الرقمية', style: TextStyle(fontSize: 10, color: Color(0xFFFDE68A), fontWeight: FontWeight.w900)),
                      Text('الرصيد من نظام المحاسبة في الخادم', style: TextStyle(fontSize: 8.5, color: Colors.white70, fontWeight: FontWeight.w700)),
                    ])),
                    IconButton(onPressed: app.refreshWalletAndReports, icon: const Icon(Icons.sync_rounded, color: Color(0xFFFDE68A))),
                    IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white, size: 18)),
                  ]),
                  const Divider(color: Colors.white24, height: 17),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('الرصيد المتاح للعمليات', style: TextStyle(fontSize: 9, color: Color(0xFFFDE68A), fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(hidden ? '••••••••' : money(app.walletBalance), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ]),
                    const StatusBadge(text: 'مزامنة نشطة', color: AppColors.emerald),
                  ]),
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(child: _WalletMini(title: 'الرصيد الفعلي', value: hidden ? '••••••' : money(app.walletBalance), icon: Icons.account_balance_wallet_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _WalletMini(title: 'نقاط الولاء', value: '${user?.points.toStringAsFixed(0) ?? 0}', icon: Icons.stars_rounded)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: _QuickAction(title: 'طلباتي', subtitle: '${app.orders.length} طلب', icon: Icons.inventory_2_rounded, color: AppColors.emerald, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersDetailView())))),
              const SizedBox(width: 6),
              Expanded(child: _QuickAction(title: 'تغذية الحساب', subtitle: 'إيداع فوري', icon: Icons.add_circle_outline_rounded, color: AppColors.blue, onTap: () => _showNoDepositContract(context))),
              const SizedBox(width: 6),
              Expanded(child: _QuickAction(title: 'تحويل مالي', subtitle: 'بين المشتركين', icon: Icons.send_rounded, color: AppColors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())))),
              const SizedBox(width: 6),
              Expanded(child: _QuickAction(title: 'شبكة السداد', subtitle: 'خدمات رقمية', icon: Icons.credit_card_rounded, color: AppColors.burgundy, dark: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())))),
            ]),
            const SizedBox(height: 13),
            const RefSection(title: 'حسابي في تطبيق شبيك', icon: Icons.apps_rounded),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shortcuts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.36),
              itemBuilder: (_, index) {
                final shortcut = shortcuts[index];
                return InkWell(
                  onTap: () => _open(context, shortcut.screen),
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: shortcut.color, borderRadius: BorderRadius.circular(9)), child: Icon(shortcut.icon, color: Colors.white, size: 16)),
                      const Spacer(),
                      Text(shortcut.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(shortcut.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            RefSection(title: 'أحدث العمليات', icon: Icons.history_rounded, action: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsView())), child: const Text('السجل الكامل', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)))),
            const SizedBox(height: 7),
            if (app.operations.isEmpty) const EmptyState(text: 'لا توجد عمليات مسترجعة من الخادم حالياً.', icon: Icons.receipt_long_outlined),
            for (final operation in app.operations.take(5)) RefOperationTile(operation: operation),
            const SizedBox(height: 13),
            const Center(child: Text('برمجة وتطوير: يمن كود للتقنيات الذكية', style: TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w900))),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoDepositContract(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تغذية الحساب', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('واجهة تغذية الحساب موجودة في التصميم المرجعي، لكن عقد إيداع مستقل غير منشور في الخادم الحالي، لذلك لا يتم تسجيل حركة وهمية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, height: 1.5)),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
      ),
    );
  }

  void _open(BuildContext context, int screen) {
    final pages = <int, Widget>{
      1: const PaymentScreen(),
      2: const StoreView(),
      3: const OperationsScreen(),
      4: const StatementScreen(),
      5: const ReportsScreen(),
      6: const TransferScreen(),
      7: const WifiScreen(),
      8: const GamesServicesScreen(),
      9: const FingerprintSettingsScreen(),
      10: const AddressesScreen(),
      11: const OrdersDetailView(),
    };
    final page = pages[screen];
    if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}


// Note: PaymentScreen has been moved to payment_screen.dart with full production telecom networks

class DynamicServiceCard extends StatelessWidget {
  const DynamicServiceCard({super.key, required this.service, required this.color, required this.phone});
  final Map<String, dynamic> service;
  final Color color;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    final rawItems = service['items'];
    final items = rawItems is List ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    return PageCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(radius: 19, backgroundColor: color, child: const Icon(Icons.bolt_rounded, color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${service['name'] ?? 'خدمة'}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
            Text('${service['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
          ])),
        ]),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                InkWell(
                  onTap: () => _open(context, item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(width: 112, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(.22))), child: Column(children: [Text('${item['name'] ?? 'عنصر'}', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(money(item['price']), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900))])),
                ),
            ],
          )
        else
          OutlinedButton.icon(onPressed: () => _open(context, null), icon: const Icon(Icons.play_arrow_rounded), label: const Text('تنفيذ الخدمة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
      ]),
    );
  }

  void _open(BuildContext context, Map<String, dynamic>? item) => showDialog(context: context, builder: (_) => DynamicServiceDialog(service: service, item: item, color: color, phone: phone));
}

class DynamicServiceDialog extends StatefulWidget {
  const DynamicServiceDialog({super.key, required this.service, required this.color, required this.phone, this.item});
  final Map<String, dynamic> service;
  final Map<String, dynamic>? item;
  final Color color;
  final TextEditingController phone;
  @override State<DynamicServiceDialog> createState() => _DynamicServiceDialogState();
}

class _DynamicServiceDialogState extends State<DynamicServiceDialog> {
  final fields = <String, TextEditingController>{};
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.service['fields'];
    if (raw is List) {
      for (final entry in raw.whereType<Map>()) {
        final key = '${entry['key'] ?? ''}';
        fields[key] = TextEditingController(text: (key == 'mobile' || key == 'phone') ? widget.phone.text : '${entry['default'] ?? ''}');
      }
    }
    final amount = fields['amount'];
    if (widget.item != null && amount != null && amount.text.isEmpty) amount.text = '${widget.item!['price'] ?? ''}';
  }

  @override void dispose() { for (final controller in fields.values) controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final raw = widget.service['fields'];
    final list = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      title: Text('${widget.service['name'] ?? 'تنفيذ الخدمة'}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.item != null) Container(width: double.infinity, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: widget.color.withOpacity(.08), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${widget.item!['name'] ?? 'العنصر'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)), Text(money(widget.item!['price']), style: TextStyle(color: widget.color, fontWeight: FontWeight.w900))])),
            for (final field in list) Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: fields['${field['key'] ?? ''}'], obscureText: field['secret'] == true, decoration: InputDecoration(labelText: '${field['label'] ?? field['key']}', isDense: true))),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: busy ? null : () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: widget.color), child: Text(busy ? 'جاري...' : 'تنفيذ'))],
    );
  }

  Future<void> _submit() async {
    final payload = <String, dynamic>{for (final entry in fields.entries) if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim()};
    final serviceId = int.tryParse('${widget.service['id']}');
    if (serviceId == null) return;
    setState(() => busy = true);
    try {
      final result = await context.read<AppController>().requestService(serviceId: serviceId, payload: payload, itemId: widget.item == null ? null : int.tryParse('${widget.item!['id']}'), itemType: widget.item == null ? null : '${widget.item!['type'] ?? ''}');
      if (!mounted) return;
      Navigator.pop(context);
      await showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(result['status'] == 'failed' ? 'فشل الطلب' : 'نتيجة العملية', textAlign: TextAlign.center), content: Text('${result['result'] ?? result['error_message'] ?? 'تم إرسال الطلب'}\nالمرجع: ${result['id'] ?? '-'}', textAlign: TextAlign.center), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))]));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _HomeShortcut {
  const _HomeShortcut(this.title, this.subtitle, this.icon, this.color, this.screen);
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int screen;
}

class _WalletMini extends StatelessWidget {
  const _WalletMini({required this.title, required this.value, required this.icon});
  final String title, value;
  final IconData icon;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(11)), child: Row(children: [Icon(icon, color: const Color(0xFFFDE68A), size: 16), const SizedBox(width: 6), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70, fontSize: 7.5)), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900))]))]));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap, this.dark = false});
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool dark;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), decoration: BoxDecoration(color: dark ? color : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: dark ? color : AppColors.border)), child: Column(children: [Icon(icon, color: dark ? Colors.white : color, size: 17), const SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: dark ? Colors.white : const Color(0xFF0F172A))), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 7.5, color: dark ? Colors.white70 : AppColors.muted))])));
}
