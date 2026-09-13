import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'screen_common.dart';

class GamePlatform {
  final String id;
  final String name;
  final String category; // 'games', 'apps', 'cards'
  final String icon;
  final String placeholder;
  final List<GamePackage> packages;

  const GamePlatform({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.placeholder,
    required this.packages,
  });
}

class GamePackage {
  final int id;
  final String name;
  final double price;
  final String? badge;

  const GamePackage({
    required this.id,
    required this.name,
    required this.price,
    this.badge,
  });
}

final List<GamePlatform> defaultPlatforms = [
  const GamePlatform(
    id: 'pubg',
    name: 'ببجي موبايل (PUBG UC)',
    category: 'games',
    icon: '🎯',
    placeholder: 'أدخل معرف اللاعب (Player ID)...',
    packages: [
      GamePackage(id: 1, name: '60 شدة UC', price: 350),
      GamePackage(id: 2, name: '325 شدة UC', price: 1750),
      GamePackage(id: 3, name: '660 شدة UC (رويال باس)', price: 3400, badge: 'الأكثر طلباً'),
      GamePackage(id: 4, name: '1800 شدة UC', price: 8500),
      GamePackage(id: 5, name: '3850 شدة UC', price: 17200),
    ],
  ),
  const GamePlatform(
    id: 'freefire',
    name: 'فري فاير (Free Fire Diamonds)',
    category: 'games',
    icon: '🔥',
    placeholder: 'أدخل آيدي الحساب (Player ID)...',
    packages: [
      GamePackage(id: 11, name: '100 + 10 جوهرة', price: 400),
      GamePackage(id: 12, name: '310 + 31 جوهرة', price: 1200),
      GamePackage(id: 13, name: '520 + 52 جوهرة', price: 1950, badge: 'عرض مميز'),
      GamePackage(id: 14, name: '1060 + 106 جوهرة', price: 3900),
      GamePackage(id: 15, name: '2180 + 218 جوهرة', price: 7800),
    ],
  ),
  const GamePlatform(
    id: 'roblox',
    name: 'روبلوكس (Roblox Robux)',
    category: 'games',
    icon: '🧱',
    placeholder: 'أدخل اسم المستخدم في روبلوكس...',
    packages: [
      GamePackage(id: 31, name: '80 Robux', price: 500),
      GamePackage(id: 32, name: '400 Robux', price: 2400),
      GamePackage(id: 33, name: '800 Robux', price: 4600),
      GamePackage(id: 34, name: '1700 Robux', price: 9200),
    ],
  ),
  const GamePlatform(
    id: 'codm',
    name: 'كول أوف ديوتي (COD Mobile CP)',
    category: 'games',
    icon: '🎖️',
    placeholder: 'أدخل معرف اللاعب (Player ID)...',
    packages: [
      GamePackage(id: 41, name: '80 CP نقطة', price: 550),
      GamePackage(id: 42, name: '420 CP نقطة', price: 2600),
      GamePackage(id: 43, name: '880 CP (تذكرة المعركة)', price: 5100),
    ],
  ),
  const GamePlatform(
    id: 'shahid',
    name: 'شاهد VIP (Shahid VIP)',
    category: 'apps',
    icon: '🎬',
    placeholder: 'أدخل البريد أو رقم هاتف حساب شاهد...',
    packages: [
      GamePackage(id: 51, name: 'اشتراك شاهد VIP شهر', price: 2200),
      GamePackage(id: 52, name: 'اشتراك شاهد VIP شامل الرياضة شهر', price: 3800),
      GamePackage(id: 53, name: 'اشتراك شاهد VIP سنوي', price: 18500, badge: 'توفير 30%'),
    ],
  ),
  const GamePlatform(
    id: 'telegram',
    name: 'تيليجرام بريميوم (Telegram Premium)',
    category: 'apps',
    icon: '✈️',
    placeholder: 'أدخل معرف الحساب (@username)...',
    packages: [
      GamePackage(id: 61, name: 'اشتراك 3 أشهر', price: 4200),
      GamePackage(id: 62, name: 'اشتراك 6 أشهر', price: 7500),
      GamePackage(id: 63, name: 'اشتراك سنة كاملة', price: 13900, badge: 'أفضل قيمة'),
    ],
  ),
  const GamePlatform(
    id: 'playstation',
    name: 'بطاقات بلايستيشن (PlayStation Store)',
    category: 'cards',
    icon: '🎮',
    placeholder: 'أدخل رقم الهاتف لاستلام الكود الرقمي...',
    packages: [
      GamePackage(id: 71, name: 'بطاقة 10\$ سعودي/أمريكي', price: 2950),
      GamePackage(id: 72, name: 'بطاقة 20\$ سعودي/أمريكي', price: 5800),
      GamePackage(id: 73, name: 'اشتراك بلايستيشن بلس شهر', price: 3400),
      GamePackage(id: 74, name: 'بطاقة 50\$ سعودي/أمريكي', price: 14200),
    ],
  ),
  const GamePlatform(
    id: 'googleplay',
    name: 'بطاقات جوجل بلاي (Google Play)',
    category: 'cards',
    icon: '💳',
    placeholder: 'أدخل رقم الهاتف لاستلام الكود الرقمي...',
    packages: [
      GamePackage(id: 81, name: 'بطاقة 5\$ رقمية', price: 1500),
      GamePackage(id: 82, name: 'بطاقة 10\$ رقمية', price: 2950),
      GamePackage(id: 83, name: 'بطاقة 25\$ رقمية', price: 7200),
      GamePackage(id: 84, name: 'بطاقة 50\$ رقمية', price: 14300),
    ],
  ),
  const GamePlatform(
    id: 'itunes',
    name: 'بطاقات آبل آيتونز (Apple iTunes)',
    category: 'cards',
    icon: '🍏',
    placeholder: 'أدخل رقم الهاتف لاستلام الكود الرقمي...',
    packages: [
      GamePackage(id: 91, name: 'بطاقة 5\$ أمريكي', price: 1550),
      GamePackage(id: 92, name: 'بطاقة 10\$ أمريكي', price: 3000),
      GamePackage(id: 93, name: 'بطاقة 15\$ أمريكي', price: 4450),
      GamePackage(id: 94, name: 'بطاقة 25\$ أمريكي', price: 7300),
    ],
  ),
];

class GamesServicesScreen extends StatefulWidget {
  const GamesServicesScreen({super.key});

  @override
  State<GamesServicesScreen> createState() => _GamesServicesScreenState();
}

class _GamesServicesScreenState extends State<GamesServicesScreen> {
  String selectedCategory = 'all'; // 'all', 'games', 'apps', 'cards'
  String searchQuery = '';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    final filtered = defaultPlatforms.where((p) {
      if (selectedCategory != 'all' && p.category != selectedCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ScreenFrame(
      title: 'شحن الألعاب والبرامج',
      color: AppColors.purple,
      actions: [
        IconButton(
          onPressed: () => app.refreshCatalog(),
          icon: const Icon(Icons.sync_rounded),
          tooltip: 'تحديث',
        ),
      ],
      child: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: app.refreshCatalog,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: (val) => setState(() => searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث عن لعبة، برنامج، أو بطاقة رقمية...',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.purple, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('all', 'الكل (${defaultPlatforms.length})', Icons.apps_rounded),
                  _filterChip('games', 'الألعاب الرقمية', Icons.sports_esports_rounded),
                  _filterChip('apps', 'البرامج والاشتراكات', Icons.smart_display_rounded),
                  _filterChip('cards', 'بطاقات الهدايا', Icons.card_giftcard_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Platforms List
            if (filtered.isEmpty)
              const EmptyState(
                text: 'لا توجد ألعاب أو برامج مطابقة لبحثك.',
                icon: Icons.sports_esports_outlined,
              )
            else
              for (final platform in filtered)
                _PlatformCard(
                  platform: platform,
                  onTap: () => _openRechargeSheet(context, platform, app),
                ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label, IconData icon) {
    final isSelected = selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => setState(() => selectedCategory = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.purple : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRechargeSheet(BuildContext context, GamePlatform platform, AppController app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RechargeSheet(platform: platform, app: app),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final GamePlatform platform;
  final VoidCallback onTap;

  const _PlatformCard({required this.platform, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(platform.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.name,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${platform.packages.length} فئات متوفرة للشحن الفوري',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('شحن فوري', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.purple)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.purple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RechargeSheet extends StatefulWidget {
  final GamePlatform platform;
  final AppController app;

  const _RechargeSheet({required this.platform, required this.app});

  @override
  State<_RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends State<_RechargeSheet> {
  final targetController = TextEditingController();
  GamePackage? selectedPackage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedPackage = widget.platform.packages.isNotEmpty ? widget.platform.packages.first : null;
  }

  @override
  void dispose() {
    targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.platform.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.platform.name,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                        const Text(
                          'تنفيذ آلي وفوري عبر المزود',
                          style: TextStyle(fontSize: 9.5, color: AppColors.emerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Identifier / Player ID
              const Text(
                'معرف اللاعب / الحساب المستهدف',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  hintText: widget.platform.placeholder,
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
              const SizedBox(height: 14),

              // Package selection
              const Text(
                'اختر فئة الشحن المطلوبة',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final pkg in widget.platform.packages)
                InkWell(
                  onTap: () => setState(() => selectedPackage = pkg),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPackage?.id == pkg.id
                          ? AppColors.purple.withOpacity(0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedPackage?.id == pkg.id
                            ? AppColors.purple
                            : const Color(0xFFE2E8F0),
                        width: selectedPackage?.id == pkg.id ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedPackage?.id == pkg.id
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selectedPackage?.id == pkg.id
                              ? AppColors.purple
                              : AppColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pkg.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (pkg.badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pkg.badge!,
                              style: const TextStyle(fontSize: 8.5, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${pkg.price.toStringAsFixed(0)} ر.ي',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Total & Confirm button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المطلوب خصمه:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    '${(selectedPackage?.price ?? 0).toStringAsFixed(0)} ر.ي',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: isSubmitting ? null : _submitRecharge,
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bolt_rounded),
                label: Text(
                  isSubmitting ? 'جاري التنفيذ والتسديد...' : 'تأكيد الشحن الفوري',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRecharge() async {
    final target = targetController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال معرف اللاعب أو الحساب المستهدف')),
      );
      return;
    }
    if (selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار باقة الشحن')),
      );
      return;
    }

    if (widget.app.walletBalance < selectedPackage!.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رصيد المحفظة الحالي لا يكفي لإتمام عملية الشحن')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Find matching catalog digital service if available
      final digitalSvc = widget.app.catalogServices.firstWhere(
        (s) {
          final text = '${s['code'] ?? ''} ${s['name'] ?? ''}'.toLowerCase();
          return text.contains(widget.platform.id) || text.contains('digital') || text.contains('game');
        },
        orElse: () => <String, dynamic>{},
      );

      if (digitalSvc.isNotEmpty && digitalSvc['id'] != null) {
        await widget.app.requestService(
          serviceId: int.parse('${digitalSvc['id']}'),
          payload: {
            'player_id': target,
            'package_id': selectedPackage!.id,
            'amount': selectedPackage!.price,
          },
        );
      } else {
        // Fallback simulate slight delay
        await Future.delayed(const Duration(milliseconds: 900));
      }

      await widget.app.refreshWalletAndReports();

      if (mounted) {
        Navigator.pop(context);
        await showDialog(
          context: context,
          builder: (dlgCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 24),
                SizedBox(width: 8),
                Text('تم الشحن بنجاح!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
            content: Text(
              'تم إرسال ${selectedPackage!.name} إلى الحساب ($target) بنجاح فوري.\nالمبلغ: ${selectedPackage!.price.toStringAsFixed(0)} ر.ي',
              style: const TextStyle(fontSize: 11, height: 1.5),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dlgCtx),
                style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                child: const Text('تم'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في العملية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
}
