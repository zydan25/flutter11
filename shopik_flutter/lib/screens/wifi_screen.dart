import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await context.read<AppController>().refreshOptional();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final networks = app.wifi;
    final cards = app.wifiCards;

    return ScreenFrame(
      title: 'شبكات الواي فاي والكروت',
      color: AppColors.blue,
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.blue,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PageCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wifi_rounded, color: AppColors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('شراء كروت شبكات الإنترنت المحلية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                        SizedBox(height: 2),
                        Text('اختر الشبكة لشراء كرت فوري برصيدك', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_loading && networks.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.blue)))
            else if (networks.isEmpty)
              EmptyState(
                text: 'لا توجد شبكات واي فاي مضافة حالياً في منطقتك.',
                icon: Icons.wifi_off_rounded,
                action: FilledButton(
                  onPressed: _refresh,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                  child: const Text('تحديث الشبكات'),
                ),
              )
            else
              ...networks.map((net) {
                final name = '${net['name'] ?? net['ssid'] ?? 'شبكة واي فاي'}';
                final location = '${net['location'] ?? net['city'] ?? 'محلية'}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering_rounded, color: AppColors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            Text(location, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          showAppToast(context, 'جاري جلب فئات كروت $name...', isSuccess: true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('شراء كرت', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),

            if (cards.isNotEmpty) ...[
              const SizedBox(height: 16),
              const RefSection(title: 'الكروت المشتراة مسبقاً', icon: Icons.credit_card_rounded),
              const SizedBox(height: 10),
              ...cards.map((card) {
                final code = '${card['card_number'] ?? card['code'] ?? card['pin'] ?? '******'}';
                final netName = '${card['network_name'] ?? 'شبكة واي فاي'}';
                final price = num.tryParse('${card['price'] ?? 0}') ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(netName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('كود الكرت: $code', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.burgundy)),
                        ],
                      ),
                      Text(money(price), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.emerald, fontSize: 12)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
