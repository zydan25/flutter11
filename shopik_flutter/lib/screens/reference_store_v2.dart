import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'reference_account_clean.dart' show UserProfileEditScreen;
import 'reference_store_legacy.dart' as legacy;

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final search = TextEditingController();
  final cart = <int, int>{};
  final favorites = <int>{};
  String category = 'الكل';
  int bannerIndex = 0;

  static const _defaultCategories = <String>[
    'الكل',
    'رجالي',
    'نسائي',
    'الملابس',
    'إلكترونيات',
    'هواتف',
    'عطور ومكياج',
    'أحذية وحقائب',
    'ساعات ونظارات',
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _addToCart(Product product, [int qty = 1]) {
    setState(() {
      cart[product.id] = (cart[product.id] ?? 0) + qty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة "${product.name}" إلى السلة'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: Colors.white,
          onPressed: () => _openCart(context),
        ),
      ),
    );
  }

  void _toggleFavorite(int productId) {
    setState(() {
      if (favorites.contains(productId)) {
        favorites.remove(productId);
      } else {
        favorites.add(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final q = search.text.trim().toLowerCase();

    // Categories
    final dynamicServerCategories = app.categories
        .map((c) => '${c['name'] ?? c['title'] ?? ''}'.trim())
        .where((x) => x.isNotEmpty)
        .toList();
    final chips = dynamicServerCategories.isNotEmpty
        ? <String>{'الكل', ...dynamicServerCategories}.toList()
        : _defaultCategories;

    // Filtered Products
    final products = app.products.where((p) {
      final haystack = '${p.name} ${p.brand} ${p.vendorName} ${p.categories.join(' ')}'.toLowerCase();
      final matchesQuery = q.isEmpty || haystack.contains(q);
      final matchesCategory = category == 'الكل' || p.categories.contains(category);
      return matchesQuery && matchesCategory;
    }).toList();

    final totalCartCount = cart.values.fold<int>(0, (sum, value) => sum + value);
    num total = 0;
    for (final entry in cart.entries) {
      final p = app.products.where((x) => x.id == entry.key).firstOrNull;
      if (p != null) total += (p.salePrice ?? p.price) * entry.value;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8B1D3B),
          onRefresh: app.refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
            children: [
              _buildStoreTopHeader(context, app, totalCartCount),
              const SizedBox(height: 10),
              _buildSearchCapsule(),
              const SizedBox(height: 12),
              _buildPromotionalBanner(),
              const SizedBox(height: 14),
              _buildCategoriesSection(chips, products.length),
              const SizedBox(height: 16),
              _buildVerifiedStoresSection(app),
              const SizedBox(height: 16),
              _buildProductsSection(context, app, products),
            ],
          ),
        ),
      ),
      bottomSheet: totalCartCount == 0
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalCartCount منتجات في السلة',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                          Text(
                            money(total),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8B1D3B),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openCart(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1D3B),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                      label: const Text(
                        'عرض السلة والدفع',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // 1. Store Top Header Bar (Matching StoreView.tsx)
  // ==========================================
  Widget _buildStoreTopHeader(BuildContext context, AppController app, int totalCartCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Logo & Title
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B1D3B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x224C0519)),
              boxShadow: const [
                BoxShadow(color: Color(0x150F172A), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'سوق شبيك بلس',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'المتجر الإلكتروني المعتمد',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Account Pill Button
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileEditScreen()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                border: Border.all(color: const Color(0xFFFECDD3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8B1D3B)),
                  SizedBox(width: 4),
                  Text(
                    'حسابي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B1D3B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Orders Button with counter badge
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const legacy.OrdersDetailView()),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: const CircleBorder(),
            ),
            icon: Badge(
              isLabelVisible: app.orders.isNotEmpty,
              label: Text(
                '${app.orders.length}',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
              ),
              backgroundColor: const Color(0xFF8B1D3B),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF334155), size: 19),
            ),
            tooltip: 'طلباتي في المتجر',
          ),
          // Cart Button with counter badge
          IconButton(
            onPressed: () => _openCart(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: const CircleBorder(),
            ),
            icon: Badge(
              isLabelVisible: totalCartCount > 0,
              label: Text(
                '$totalCartCount',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
              ),
              backgroundColor: const Color(0xFF059669),
              child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF334155), size: 19),
            ),
            tooltip: 'سلة المشتريات',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. Search Capsule (Matching StoreView.tsx)
  // ==========================================
  Widget _buildSearchCapsule() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: search,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: search.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                  onPressed: () {
                    search.clear();
                    setState(() {});
                  },
                )
              : null,
          hintText: 'ابحث عن منتج، متجر، أو صنف...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  // ==========================================
  // 3. Today's Deal Banner (Matching StoreView.tsx)
  // ==========================================
  Widget _buildPromotionalBanner() {
    final banners = const [
      (
        'تخفيضات كبرى في سوق شبيك',
        'خصومات حصرية حتى 40% على الملابس والإلكترونيات',
        'عرض اليوم'
      ),
      (
        'منتجات أصلية ومتاجر موثوقة',
        'خيارات موثقة وأسعار واضحة داخل سوق شبيك المعتمد',
        'موثوق'
      ),
      (
        'تسوق بسهولة والدفع من المحفظة',
        'اطلب، ادفع من محفظتك برصيدك، وتابع طلبك فورياً',
        'شبيك بلس'
      ),
    ];
    final item = banners[bannerIndex % banners.length];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) {
          setState(() => bannerIndex = (bannerIndex + 1) % banners.length);
        }
        if ((details.primaryVelocity ?? 0) > 0) {
          setState(() => bannerIndex = (bannerIndex - 1 + banners.length) % banners.length);
        }
      },
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF9B1344),
              Color(0xFF881337),
              Color(0xFF701A75),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x200F172A), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.$3,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const Text(
                  'متجر شبيك المعتمد',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.$1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.$2,
              style: const TextStyle(color: Color(0xFFFFE4E6), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => category = 'الكل'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'تصفح المنتجات ←',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'تطبيق شبيك وسوق بلس',
                  style: TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. Categories Section (Matching StoreView.tsx & Screenshot 1)
  // ==========================================
  Widget _buildCategoriesSection(List<String> chips, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => legacy.CategoryProductsView(initialCategory: category),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  children: [
                    const Text(
                      'أقسام المتجر',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($count منتج)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => legacy.CategoryProductsView(initialCategory: category),
                  ),
                );
              },
              child: Row(
                children: const [
                  Text(
                    'عرض كافة الأقسام',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_back_ios_rounded, size: 10, color: Color(0xFF8B1D3B)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: false,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final name = chips[i];
                final active = category == name;
                return InkWell(
                  onTap: () {
                    setState(() => category = name);
                    if (name != 'الكل') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => legacy.CategoryProductsView(initialCategory: name),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF8B1D3B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: active
                          ? const [BoxShadow(color: Color(0x228B1D3B), blurRadius: 6, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. Verified Stores Section (Matching StoreView.tsx)
  // ==========================================
  Widget _buildVerifiedStoresSection(AppController app) {
    final vendors = app.vendors.isNotEmpty
        ? app.vendors.take(6).toList()
        : () {
            final map = <int, Map<String, dynamic>>{};
            for (final p in app.products) {
              if (p.vendorId != null && !map.containsKey(p.vendorId)) {
                map[p.vendorId!] = {
                  'id': p.vendorId,
                  'store_name': p.vendorName.isNotEmpty ? p.vendorName : 'متجر شبيك',
                  'phone': p.vendorPhone,
                  'logo_url': p.vendorLogo,
                  'cover_url': p.vendorCover,
                  'status': 'active',
                  'rating': p.rating > 0 ? p.rating : 4.9,
                  'badge': 'متجر معتمد وموثوق',
                };
              }
            }
            return map.values.take(6).toList();
          }();

    if (vendors.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.storefront_rounded, color: Color(0xFF8B1D3B), size: 17),
                SizedBox(width: 6),
                Text(
                  'متاجر شبيك المعتمدة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                if (vendors.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => legacy.StoreProfileView(vendor: Map<String, dynamic>.from(vendors.first)),
                    ),
                  );
                }
              },
              child: const Text(
                'عرض المتاجر ←',
                style: TextStyle(fontSize: 11, color: Color(0xFF8B1D3B), fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.35,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: vendors.length > 4 ? 4 : vendors.length,
          itemBuilder: (_, i) {
            final vendor = vendors[i];
            final storeName = '${vendor['store_name'] ?? vendor['name'] ?? 'متجر شبيك'}';
            final badge = '${vendor['badge'] ?? 'متجر معتمد وموثوق'}';
            final rating = num.tryParse('${vendor['rating'] ?? 4.9}') ?? 4.9;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => legacy.StoreProfileView(vendor: Map<String, dynamic>.from(vendor)),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x080F172A), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          storeName.isNotEmpty ? storeName.replaceAll('متجر', '').trim().substring(0, 1) : 'ش',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // 6. Real Products Section (Matching StoreView.tsx)
  // ==========================================
  Widget _buildProductsSection(BuildContext context, AppController app, List<Product> products) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B1D3B), size: 16),
                SizedBox(width: 6),
                Text(
                  'منتجات المتجر الحقيقية (من الخادم)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            InkWell(
              onTap: app.refreshAll,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF8B1D3B)),
                    SizedBox(width: 3),
                    Text(
                      'تحديث',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFFCBD5E1)),
                SizedBox(height: 10),
                Text(
                  'لا توجد منتجات تطابق البحث',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                ),
                SizedBox(height: 4),
                Text(
                  'جرب تغيير كلمة البحث أو اختيار قسم آخر',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final product = products[i];
              final isFav = favorites.contains(product.id);
              return _ProductCard(
                product: product,
                favorite: isFav,
                onFavorite: () => _toggleFavorite(product.id),
                onAdd: () => _addToCart(product),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => legacy.ProductDetailView(
                      product: product,
                      onAdd: () => _addToCart(product),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ==========================================
  // Open Cart Bottom Sheet Modal
  // ==========================================
  Future<void> _openCart(BuildContext context) async {
    final app = context.read<AppController>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(app: app, cart: cart),
    );
    if (result == true && mounted) {
      setState(() => cart.clear());
    }
  }
}

// ==========================================
// 7. Product Card Component (Matching StoreView.tsx)
// ==========================================
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sale = product.salePrice;
    final price = sale ?? product.price;
    final isDiscounted = sale != null && sale < product.price;
    final storeName = product.vendorName.isNotEmpty ? product.vendorName : 'متجر شبيك';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with Badges
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFF1F5F9),
                      child: product.image != null && product.image!.isNotEmpty
                          ? Image.network(
                              absoluteUrl(product.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                            ),
                    ),
                  ),
                  // Store Name Pill Badge (Bottom-Right)
                  Positioned(
                    bottom: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0F172A),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button (Top-Left)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: InkWell(
                      onTap: onFavorite,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: favorite ? const Color(0xFFF43F5E) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge (Top-Right)
                  if (isDiscounted)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'خصم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.categories.isNotEmpty ? product.categories.first : (product.brand.isNotEmpty ? product.brand : 'عام'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            money(price, product.currency),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF8B1D3B),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isDiscounted)
                            Text(
                              money(product.price, product.currency),
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1D3B),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x208B1D3B), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 19),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. Cart Sheet Modal (Matching StoreView.tsx)
// ==========================================
class _CartSheet extends StatefulWidget {
  const _CartSheet({required this.app, required this.cart});
  final AppController app;
  final Map<int, int> cart;

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  bool busy = false;
  String? errorMessage;
  bool orderSuccess = false;

  @override
  Widget build(BuildContext context) {
    num total = 0;
    final rows = <Map<String, dynamic>>[];
    for (final e in widget.cart.entries) {
      final p = widget.app.products.where((x) => x.id == e.key).firstOrNull;
      if (p == null) continue;
      final price = p.salePrice ?? p.price;
      total += price * e.value;
      rows.add({'p': p, 'qty': e.value});
    }

    final totalCount = widget.cart.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: Color(0xFF8B1D3B), size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سلة المشتريات ($totalCount)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body
          Expanded(
            child: orderSuccess
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 54),
                          SizedBox(height: 12),
                          Text(
                            'تم تأكيد طلبك بنجاح!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'تم خصم المبلغ من المحفظة وجاري تجهيز الشحنة والتوصيل.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                : rows.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'السلة فارغة حالياً',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'تصفح منتجات المتجر وأضف ما ترغب به',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        itemBuilder: (_, i) {
                          final p = rows[i]['p'] as Product;
                          final qty = rows[i]['qty'] as int;
                          final unitPrice = p.salePrice ?? p.price;

                          return Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: p.image != null && p.image!.isNotEmpty
                                      ? Image.network(
                                          absoluteUrl(p.image!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      money(unitPrice, p.currency),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8B1D3B),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: qty <= 1
                                          ? () => setState(() => widget.cart.remove(p.id))
                                          : () => setState(() => widget.cart[p.id] = qty - 1),
                                      icon: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFF64748B)),
                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => widget.cart[p.id] = qty + 1),
                                      icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF059669)),
                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Bottom Summary & Checkout Button
          if (!orderSuccess && rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي النهائي:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      Text(
                        money(total),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF8B1D3B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wallet Balance Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الدفع من رصيد المحفظة المتوفر:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                        ),
                        Text(
                          money(widget.app.walletBalance),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFE11D48)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: busy ? null : () => _checkout(context, total),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1D3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: busy
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'جاري التحقق من الخادم وإتمام الطلب...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'تأكيد الطلب والتحقق من الخادم',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context, num total) async {
    if (widget.app.walletBalance < total) {
      setState(() {
        errorMessage = 'رصيد المحفظة غير كافٍ لإتمام الشراء. يرجى شحن الرصيد أولاً.';
      });
      return;
    }

    setState(() {
      busy = true;
      errorMessage = null;
    });

    try {
      final items = widget.cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList();
      final shippingAddress = widget.app.addresses.isNotEmpty
          ? Map<String, dynamic>.from(widget.app.addresses.first)
          : {
              'governorate': 'صنعاء',
              'city': 'حدة',
              'street_details': 'الشارع الرئيسي',
              'phone': widget.app.user?.phone ?? '',
            };

      await widget.app.api.createOrder(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: 'wallet',
      );

      setState(() {
        orderSuccess = true;
        busy = false;
      });

      // Refresh data
      unawaited(widget.app.refreshAll());

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'تعذر إنشاء الطلب: ${e.toString().replaceAll('Exception:', '').trim()}';
        busy = false;
      });
    }
  }
}
