import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'screen_common.dart';

// =========================================================================
// 1. PRODUCT DETAIL VIEW (Matching ProductDetailView.tsx)
// =========================================================================
class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key, required this.product, this.onAdd});
  final Product product;
  final VoidCallback? onAdd;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int quantity = 1;
  int activeImage = 0;
  bool isFavorite = false;
  String selectedColor = 'أحمر كلاسيكي';
  String selectedSize = 'L';
  bool _loading = true;
  Map<String, dynamic>? _detail;

  static const _availableColors = [
    ('أحمر كلاسيكي', Color(0xFF9B1344)),
    ('كحلي داكن', Color(0xFF1E293B)),
    ('أخضر زيتي', Color(0xFF065F46)),
    ('أسود ملكي', Color(0xFF0F172A)),
  ];

  static const _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final app = context.read<AppController>();
      final data = await app.api.productDetail(widget.product.id);
      if (mounted) {
        setState(() {
          _detail = data;
          _loading = false;
          // Set dynamic color if returned
          final rawColors = data['colors'];
          if (rawColors is List && rawColors.isNotEmpty) {
            final f = rawColors.first;
            if (f is Map && f['name'] != null) {
              selectedColor = f['name'].toString();
            } else if (f is String && f.isNotEmpty) {
              selectedColor = f;
            }
          } else if (widget.product.colors.isNotEmpty) {
            selectedColor = widget.product.colors.first.name;
          }
          // Set dynamic size if returned
          final rawSizes = data['sizes'];
          if (rawSizes is List && rawSizes.isNotEmpty) {
            selectedSize = rawSizes.first.toString();
          } else if (widget.product.sizes.isNotEmpty) {
            selectedSize = widget.product.sizes.first;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseProduct = widget.product;
    final d = _detail ?? {};
    final name = d['name']?.toString().isNotEmpty == true ? d['name'].toString() : baseProduct.name;
    final brand = d['brand']?.toString().isNotEmpty == true ? d['brand'].toString() : (baseProduct.brand.isNotEmpty ? baseProduct.brand : 'شبيك بلس');
    final description = d['description']?.toString().isNotEmpty == true ? d['description'].toString() : (baseProduct.description ?? 'منتج أصلي موثق معتمد بجودة عالية وضمان شامل في سوق شبيك.');
    final vendorName = d['vendor_name']?.toString().isNotEmpty == true ? d['vendor_name'].toString() : (baseProduct.vendorName.isNotEmpty ? baseProduct.vendorName : 'متجر زيزو للأزياء');
    final currency = d['currency']?.toString() ?? baseProduct.currency;
    final sku = d['sku']?.toString() ?? 'SKU-${baseProduct.id + 10420}';
    final price = d['price'] != null ? (double.tryParse('${d['price']}') ?? baseProduct.price) : baseProduct.price;
    final salePrice = d['sale_price'] != null ? double.tryParse('${d['sale_price']}') : baseProduct.salePrice;
    final stock = d['stock'] != null ? (int.tryParse('${d['stock']}') ?? baseProduct.stock) : (baseProduct.stock > 0 ? baseProduct.stock : 25);
    final rating = d['rating'] != null ? (double.tryParse('${d['rating']}') ?? baseProduct.rating) : 4.9;
    final reviewsCount = d['reviews_count'] != null ? (int.tryParse('${d['reviews_count']}') ?? baseProduct.reviewsCount) : 48;

    final images = <String>[];
    final mainImg = d['image']?.toString() ?? baseProduct.image;
    if (mainImg != null && mainImg.isNotEmpty) images.add(mainImg);
    final rawGallery = d['gallery'] ?? d['images'] ?? baseProduct.gallery;
    if (rawGallery is List) {
      for (final img in rawGallery) {
        final str = img is Map ? '${img['image'] ?? img['url'] ?? ''}' : '$img';
        if (str.isNotEmpty && !images.contains(str)) images.add(str);
      }
    }
    if (images.isEmpty && baseProduct.image != null && baseProduct.image!.isNotEmpty) {
      images.add(baseProduct.image!);
    }

    final isDiscounted = salePrice != null && salePrice < price;
    final double currentPrice = (salePrice ?? price).toDouble();
    final discountPercent = isDiscounted && price > 0 ? (((price - salePrice) / price) * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          // Store badge
          InkWell(
            onTap: () => _openStore(vendorName, baseProduct.vendorId),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF8B1D3B)),
                  const SizedBox(width: 4),
                  Text(
                    vendorName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite ? 'تمت إضافة المنتج إلى المفضلة' : 'تمت إزالة المنتج من المفضلة'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? const Color(0xFFF43F5E) : const Color(0xFF475569),
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://shopik.alattab.site/products/${baseProduct.id}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رابط المنتج بنجاح'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, color: Color(0xFF475569), size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetail,
        color: const Color(0xFF8B1D3B),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
          children: [
            if (_loading) const LinearProgressIndicator(color: Color(0xFF8B1D3B), minHeight: 2),

            // 1. Big Hero Image Gallery
            _buildImageGallery(images),
            const SizedBox(height: 14),

            // 2. Product Details & Price Card
            _buildProductInfoCard(
              name: name,
              brand: brand,
              sku: sku,
              rating: rating,
              reviewsCount: reviewsCount,
              currentPrice: currentPrice,
              originalPrice: price,
              isDiscounted: isDiscounted,
              discountPercent: discountPercent,
              currency: currency,
              stock: stock,
            ),
            const SizedBox(height: 12),

            // 3. Variant Selectors (Color & Size) - placed directly under product info
            _buildVariantsCard(d, baseProduct),
            const SizedBox(height: 12),

            // 4. Quantity Selector Card
            _buildQuantityCard(stock),
            const SizedBox(height: 12),

            // 5. Description Card (From Server)
            _buildDescriptionCard(description, d),
            const SizedBox(height: 12),

            // 6. Technical Specifications Card
            _buildTechnicalSpecsCard(d, baseProduct),
            const SizedBox(height: 12),

            // 7. Guarantee and Return Policy Card
            _buildGuaranteeAndReturnPolicyCard(d, baseProduct),
            const SizedBox(height: 12),

            // 8. Merchant / Store Card
            _buildMerchantCard(vendorName, baseProduct.vendorId, d, baseProduct),
            const SizedBox(height: 12),

            // 9. Similar Products in Same Category (Below color, size, and specs)
            _buildSimilarProductsCard(context.watch<AppController>(), baseProduct),
          ],
        ),
      ),
      // 10. Fixed Bottom Action Bar
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Total Calculation
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجمالي المحدد:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  Text(
                    money(currentPrice * quantity, currency),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B1D3B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Add to Cart Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (int i = 0; i < quantity; i++) {
                      widget.onAdd?.call();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة $quantity من "$name" إلى السلة'),
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    foregroundColor: const Color(0xFF8B1D3B),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('إضافة للسلة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              // Buy Now Button
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onAdd?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري الانتقال للدفع...'),
                        backgroundColor: Color(0xFF8B1D3B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('شراء الآن', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers for ProductDetailView ---
  Widget _buildImageGallery(List<String> images) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Main Preview
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: images.isNotEmpty
                        ? Image.network(
                            absoluteUrl(images[activeImage < images.length ? activeImage : 0]),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 50, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 50, color: Color(0xFF94A3B8)),
                          ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x990F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activeImage + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            // Thumbnails Row
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = activeImage == i;
                  return InkWell(
                    onTap: () => setState(() => activeImage = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          absoluteUrl(images[i]),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.black26),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfoCard({
    required String name,
    required String brand,
    required String sku,
    required double rating,
    required int reviewsCount,
    required double currentPrice,
    required double originalPrice,
    required bool isDiscounted,
    required int discountPercent,
    required String currency,
    required int stock,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(
                  brand,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B)),
                ),
              ),
              Row(
                children: [
                  Text('كود: $sku', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: sku));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود المنتج'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Ratings and Sales
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 4),
              Text(
                '($reviewsCount تقييم)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stock > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stock > 0 ? 'متوفر بالمخزون ($stock)' : 'نفذت الكمية',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: stock > 0 ? const Color(0xFF065F46) : const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                money(currentPrice, currency),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8B1D3B),
                ),
              ),
              if (isDiscounted) ...[
                const SizedBox(width: 8),
                Text(
                  money(originalPrice, currency),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'وفر $discountPercent%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard(Map<String, dynamic> d, Product baseProduct) {
    // Parse dynamic colors from server
    final colorsList = <(String, Color)>[];
    final rawColors = d['colors'] ?? baseProduct.colors;
    if (rawColors is List && rawColors.isNotEmpty) {
      for (final item in rawColors) {
        if (item is ProductColorVariant) {
          colorsList.add((item.name, item.color));
        } else if (item is Map) {
          final cName = '${item['name'] ?? item['color_name'] ?? ''}'.trim();
          final hex = '${item['color_hex'] ?? item['code'] ?? item['hex'] ?? '#8B1D3B'}'.trim();
          final colorVal = Color(int.tryParse(hex.replaceAll('#', '0xFF')) ?? 0xFF8B1D3B);
          if (cName.isNotEmpty) colorsList.add((cName, colorVal));
        } else if (item is String && item.trim().isNotEmpty) {
          colorsList.add((item.trim(), const Color(0xFF8B1D3B)));
        }
      }
    }
    if (colorsList.isEmpty) {
      colorsList.addAll(_availableColors);
    }

    // Parse dynamic sizes from server
    final sizesList = <String>[];
    final rawSizes = d['sizes'] ?? baseProduct.sizes;
    if (rawSizes is List && rawSizes.isNotEmpty) {
      for (final item in rawSizes) {
        final s = '$item'.trim();
        if (s.isNotEmpty && !sizesList.contains(s)) sizesList.add(s);
      }
    }
    if (sizesList.isEmpty) {
      sizesList.addAll(_availableSizes);
    }

    // Ensure selectedColor is in list
    if (!colorsList.any((c) => c.$1 == selectedColor)) {
      selectedColor = colorsList.first.$1;
    }
    // Ensure selectedSize is in list
    if (!sizesList.contains(selectedSize)) {
      selectedSize = sizesList.first;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color Select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اختر اللون:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(selectedColor, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colorsList.map((col) {
              final active = selectedColor == col.$1;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: col.$2, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(col.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.white : const Color(0xFF334155))),
                  ],
                ),
                selected: active,
                selectedColor: const Color(0xFF8B1D3B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0)),
                ),
                onSelected: (_) => setState(() => selectedColor = col.$1),
              );
            }).toList(),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          // Size Select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المقاس:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('المحدد: $selectedSize', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizesList.map((sz) {
              final active = selectedSize == sz;
              return ChoiceChip(
                label: Text(
                  sz,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                selected: active,
                selectedColor: const Color(0xFF8B1D3B),
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: active ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0)),
                ),
                onSelected: (_) => setState(() => selectedSize = sz),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard(int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الكمية المطلوبة:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  onPressed: quantity < stock ? () => setState(() => quantity++) : null,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF059669)),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(String vendorName, int? vendorId, [Map<String, dynamic>? d, Product? baseProduct]) {
    final logoUrl = (d?['vendor_logo'] ?? baseProduct?.vendorLogo)?.toString();
    final cleanLogo = (logoUrl != null && logoUrl.isNotEmpty && logoUrl != 'null') ? Product.normalizeUrl(logoUrl) : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: cleanLogo != null
                      ? Image.network(
                          cleanLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Color(0xFF8B1D3B), size: 22),
                        )
                      : const Icon(Icons.storefront_rounded, color: Color(0xFF8B1D3B), size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                        SizedBox(width: 3),
                        Text(
                          'متجر موثوق ومعتمد في سوق شبيك',
                          style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _openStore(vendorName, vendorId),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B1D3B)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('زيارة المتجر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('جاري الاتصال بـ $vendorName...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFF334155)),
                        SizedBox(width: 6),
                        Text('اتصال هاتفي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: widget.product.id, title: 'محادثة $vendorName')),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text('محادثة المتجر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description, Map<String, dynamic> detail) {
    if (description.isEmpty || description == 'null') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'وصف المنتج ومواصفاته',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecsCard(Map<String, dynamic> d, Product baseProduct) {
    final details = d['details'] is Map ? d['details'] as Map : baseProduct.details;
    final brand = d['brand']?.toString().isNotEmpty == true ? d['brand'].toString() : (baseProduct.brand.isNotEmpty ? baseProduct.brand : 'شبيك بلس');
    final condition = d['condition']?.toString().isNotEmpty == true
        ? d['condition'].toString()
        : (details['condition']?.toString().isNotEmpty == true ? details['condition'].toString() : 'جديد وأصلي 100%');
    
    String warranty = 'ضمان استبدال معتمد';
    if (d['warranty'] != null && d['warranty'].toString().isNotEmpty) {
      warranty = d['warranty'].toString();
    } else if (details['warranty'] == true || details['warranty'] == 'true') {
      final dur = details['warranty_duration']?.toString() ?? '';
      warranty = dur.isNotEmpty ? 'ساري ومعتمد ($dur)' : 'ساري ومعتمد من متجر شبيك';
    } else if (details['warranty'] != null && details['warranty'].toString().isNotEmpty) {
      warranty = details['warranty'].toString();
    }

    final material = d['material']?.toString().isNotEmpty == true
        ? d['material'].toString()
        : (details['material']?.toString().isNotEmpty == true
            ? details['material'].toString()
            : (d['specs']?.toString().isNotEmpty == true
                ? d['specs'].toString()
                : (d['specifications']?.toString().isNotEmpty == true ? d['specifications'].toString() : '')));
    
    final categoryName = baseProduct.categories.isNotEmpty ? baseProduct.categories.first : (d['category']?.toString() ?? 'إلكترونيات');
    final customCategory = d['custom_category_name']?.toString() ?? baseProduct.customCategoryName ?? '';
    final sku = d['sku']?.toString() ?? (baseProduct.sku.isNotEmpty ? baseProduct.sku : 'SKU-${baseProduct.id + 10420}');
    final gender = details['gender']?.toString() ?? '';
    final availableStock = d['available_stock'] ?? baseProduct.availableStock;
    final rawHashtags = d['hashtags'] ?? baseProduct.hashtags;
    final hashtagsText = rawHashtags is List ? rawHashtags.join(' • ') : '';

    final specsList = <(String, String)>[
      ('الماركة التجارية', brand),
      ('القسم الرئيسي', categoryName),
      if (customCategory.isNotEmpty) ('القسم المخصص للتاجر', customCategory),
      if (material.isNotEmpty) ('الخامة والمواصفات', material),
      ('حالة المنتج', condition),
      ('الضمان المعتمد', warranty),
      if (gender.isNotEmpty) ('الفئة المستهدفة', gender),
      ('رمز المنتج (SKU)', sku),
      if (availableStock > 0) ('الكمية المتوفرة بالمخزن', '$availableStock قطعة جاهزة للشحن'),
      if (hashtagsText.isNotEmpty) ('الوسوم الدلالية', hashtagsText),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFF1E3A8A), size: 19),
              SizedBox(width: 8),
              Text(
                'المواصفات الفنية المعتمدة للقسم',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          for (int i = 0; i < specsList.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    specsList[i].$1,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                  ),
                  Flexible(
                    child: Text(
                      specsList[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeAndReturnPolicyCard(Map<String, dynamic> d, [Product? baseProduct]) {
    final details = d['details'] is Map ? d['details'] as Map : (baseProduct?.details ?? {});
    final returnPolicy = d['return_policy']?.toString().isNotEmpty == true
        ? d['return_policy'].toString()
        : (baseProduct?.returnPolicy != null && baseProduct!.returnPolicy!.isNotEmpty
            ? baseProduct.returnPolicy!
            : (details['return_policy']?.toString().isNotEmpty == true
                ? details['return_policy'].toString()
                : 'ضمان استبدال واسترجاع خلال 3 أيام مع فحص الشحنة فور الاستلام وتوصيل لباب المنزل.'));

    final shippingNote = d['shipping_note']?.toString().isNotEmpty == true
        ? d['shipping_note'].toString()
        : (baseProduct?.shippingNote != null && baseProduct!.shippingNote!.isNotEmpty
            ? baseProduct.shippingNote!
            : (details['shipping_note']?.toString().isNotEmpty == true
                ? details['shipping_note'].toString()
                : 'توصيل سريع ومباشر لباب المنزل عبر مندوب شبيك في أمانة العاصمة والمحافظات.'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Text(
                'سياسة الضمان والإرجاع والتوصيل المعتمدة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_return_outlined, color: Color(0xFF059669), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  returnPolicy,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_shipping_outlined, color: Color(0xFF059669), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shippingNote,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsCard(AppController app, Product baseProduct) {
    final cat = baseProduct.categories.isNotEmpty ? baseProduct.categories.first : 'الكل';
    final related = app.products.where((p) => p.id != baseProduct.id && (p.categories.contains(cat) || cat == 'الكل')).take(6).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'منتجات تندرج ضمن نفس القسم',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryProductsView(initialCategory: cat)),
                );
              },
              child: const Text(
                'عرض المزيد ←',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: false,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = related[i];
              return InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailView(product: p)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            color: const Color(0xFFF1F5F9),
                            width: double.infinity,
                            child: p.image != null && p.image!.isNotEmpty
                                ? Image.network(
                                    absoluteUrl(p.image!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                                  )
                                : const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              money(p.salePrice ?? p.price, p.currency),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openStore(String vendorName, int? vendorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProfileView(
          vendor: {
            'id': vendorId ?? 1,
            'store_name': vendorName,
            'name': vendorName,
            'rating': 4.9,
          },
        ),
      ),
    );
  }
}

// =========================================================================
// 2. STORE PROFILE VIEW (Matching Screenshot 3)
// =========================================================================
class StoreProfileView extends StatefulWidget {
  const StoreProfileView({super.key, required this.vendor});
  final Map<String, dynamic> vendor;

  @override
  State<StoreProfileView> createState() => _StoreProfileViewState();
}

class _StoreProfileViewState extends State<StoreProfileView> {
  String selectedCategory = 'الكل';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final rawStoreName = '${widget.vendor['store_name'] ?? widget.vendor['name'] ?? 'متجر شبيك المعتمد'}';
    final storeName = rawStoreName.startsWith('متجر') ? rawStoreName : 'متجر $rawStoreName';
    final vendorId = int.tryParse('${widget.vendor['id'] ?? widget.vendor['vendor_id'] ?? ''}');
    final rating = num.tryParse('${widget.vendor['rating'] ?? 4.8}') ?? 4.8;

    // Vendor products
    final vendorProducts = app.products.where((p) {
      if (vendorId != null && p.vendorId != null) {
        return p.vendorId == vendorId;
      }
      return true;
    }).toList();

    final allProducts = vendorProducts.isNotEmpty ? vendorProducts : app.products;

    // Extract dynamic vendor categories
    final Set<String> categoriesSet = {'الكل'};
    for (final p in allProducts) {
      categoriesSet.addAll(p.categories);
    }
    // Add popular categories if few
    if (categoriesSet.length <= 2) {
      categoriesSet.addAll(['الأجهزة والالكترونيات', 'الهواتف', 'العروض الخاصة', 'الأكثر طلباً']);
    }
    final categoryList = categoriesSet.toList();

    // Filter by query and category
    final q = searchController.text.trim().toLowerCase();
    final filtered = allProducts.where((p) {
      final matchesCat = selectedCategory == 'الكل' || p.categories.contains(selectedCategory) || (selectedCategory == 'الأجهزة والالكترونيات' && p.categories.any((c) => c.contains('الكترونيات') || c.contains('أجهزة')));
      final text = '${p.name} ${p.brand} ${p.categories.join(' ')}'.toLowerCase();
      final matchesQuery = q.isEmpty || text.contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    final displayProducts = filtered.isNotEmpty ? filtered : (q.isEmpty && selectedCategory == 'الكل' ? allProducts : <Product>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          storeName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'https://shopik.alattab.site/stores/${widget.vendor['id'] ?? 1}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رابط المتجر بنجاح')),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 1. Store Header Profile Card (Matching Screenshot 3)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Store Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, color: Color(0xFF1E3A8A), size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Store Name & Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  storeName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 11, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                '${rating.toStringAsFixed(1)} (تقييم ممتاز من العملاء)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Contact Buttons (اتصال & محادثة المتجر)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('جاري الاتصال بـ $storeName (777000000)...')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                        label: const Text('اتصال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderChatScreen(
                                orderId: widget.vendor['id'] ?? 1,
                                title: 'محادثة $storeName',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('محادثة المتجر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                // 3 Details in Row (Location, Hours, Delivery)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _StoreMiniInfo(icon: Icons.location_on_outlined, text: 'صنعاء - شارع الزبيري'),
                    _StoreMiniInfo(icon: Icons.access_time_rounded, text: 'دوام: 9:00 ص - 10:00 م'),
                    _StoreMiniInfo(icon: Icons.delivery_dining_outlined, text: 'التوصيل: 30 دقيقة'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Search Bar within Store (Matching Screenshot 3)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () => setState(() => searchController.clear()),
                      )
                    : null,
                hintText: 'ابحث في منتجات هذا المتجر...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Elegant Vendor Category Tabs (Matching Screenshot 3 & Home Page)
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: false,
                itemCount: categoryList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categoryList[i];
                  final active = selectedCategory == cat;
                  final count = cat == 'الكل'
                      ? allProducts.length
                      : allProducts.where((p) => p.categories.contains(cat)).length;

                  return InkWell(
                    onTap: () => setState(() => selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: active ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active ? Colors.white.withOpacity(0.25) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: active ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Products Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'منتجات المتجر (${displayProducts.length}) :',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              if (selectedCategory != 'الكل')
                InkWell(
                  onTap: () => setState(() => selectedCategory = 'الكل'),
                  child: const Text(
                    'عرض كل المنتجات',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Products 2-Column Grid (Matching Screenshot 3)
          if (displayProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text('لا توجد منتجات مطابقة في هذا المتجر حالياً', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: displayProducts.length,
              itemBuilder: (_, i) {
                final p = displayProducts[i];
                final price = p.salePrice ?? p.price;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailView(product: p)),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  color: const Color(0xFFF8FAFC),
                                  width: double.infinity,
                                  child: p.image != null && p.image!.isNotEmpty
                                      ? Image.network(
                                          absoluteUrl(p.image!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                                        )
                                      : const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                                ),
                              ),
                              if (p.salePrice != null && p.salePrice! < p.price)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('خصم', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                money(price, p.currency),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    app.addToCart(p);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تمت إضافة "${p.name}" إلى السلة'),
                                        backgroundColor: const Color(0xFF059669),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B1D3B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                                  label: const Text('أضف للسلة', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StoreMiniInfo extends StatelessWidget {
  const _StoreMiniInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B1D3B)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// 3. ORDERS DETAIL VIEW (Matching OrdersDetailView.tsx)
// =========================================================================
class OrdersDetailView extends StatefulWidget {
  const OrdersDetailView({super.key});

  @override
  State<OrdersDetailView> createState() => _OrdersDetailViewState();
}

class _OrdersDetailViewState extends State<OrdersDetailView> {
  String filter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    final orders = app.orders.where((o) {
      if (filter == 'قيد المعالجة') {
        return o.status != 'completed' && o.status != 'delivered';
      }
      if (filter == 'المكتملة') {
        return o.status == 'completed' || o.status == 'delivered';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'سجل وطلبات المتجر',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          IconButton(
            onPressed: app.refreshAll,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['الكل', 'قيد المعالجة', 'المكتملة'].map((tab) {
                final active = filter == tab;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => filter = tab),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF8B1D3B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: active ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد طلبات في هذا القسم',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تصفح متجر شبيك وأضف المنتجات لسلتك',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final isCompleted = o.status == 'completed' || o.status == 'delivered';
                      final statusLabel = isCompleted
                          ? 'مكتمل ومستلم'
                          : (o.status == 'processing' ? 'قيد التجهيز والتغليف' : (o.status == 'shipped' ? 'قيد الشحن والتوصيل' : 'تم استلام الطلب'));
                      final statusColor = isCompleted
                          ? const Color(0xFF059669)
                          : (o.status == 'processing' ? const Color(0xFFD97706) : const Color(0xFF2563EB));

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isCompleted ? Icons.check_circle_outline_rounded : Icons.local_shipping_outlined,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'طلب رقم #${o.number}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        o.createdAt ?? 'اليوم',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإجمالي: ${money(o.total, o.currency)}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B1D3B),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'عرض التفاصيل والمتابعة ←',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. ORDER DETAIL SCREEN (With 5-step visual tracking timeline & Order Editing)
// =========================================================================
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _orderData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.read<AppController>();
      final data = await app.api.orderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _orderData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _showEditOrderDialog(Map<String, dynamic> currentData) {
    final addr = currentData['shipping_address'] is Map ? currentData['shipping_address'] as Map : {};
    final phoneCtrl = TextEditingController(text: '${addr['phone'] ?? currentData['customer_phone'] ?? ''}');
    final streetCtrl = TextEditingController(text: '${addr['street_details'] ?? addr['street'] ?? ''}');
    final notesCtrl = TextEditingController(text: '${currentData['notes'] ?? addr['notes'] ?? ''}');
    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تعديل تفاصيل الطلب غير المؤكد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('الطلب لم يتم تأكيده وشحنه بعد من قبل التاجر، يمكنك تعديل عنوان التوصيل ورقم التواصل.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف المستلم للتواصل',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان التوصيل / تفاصيل الشارع والحي',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية للتوصيل',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: updating
                      ? null
                      : () async {
                          setSheetState(() => updating = true);
                          try {
                            final app = context.read<AppController>();
                            await app.api.updateOrderDetails(widget.orderId, {
                              'shipping_address': {
                                ...addr,
                                'phone': phoneCtrl.text.trim(),
                                'street_details': streetCtrl.text.trim(),
                              },
                              'notes': notesCtrl.text.trim(),
                            });
                            await app.refreshAll(quiet: true);
                            await _fetchOrder();
                            if (mounted) {
                              Navigator.pop(ctx);
                              showAppToast(context, 'تم تحديث تفاصيل الطلب بنجاح', isSuccess: true);
                            }
                          } catch (e) {
                            setSheetState(() => updating = false);
                            if (mounted) showAppToast(context, 'فشل تحديث الطلب: $e', isError: true);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1D3B)),
                  child: updating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات في الخادم', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemSpecsDialog(Map item, int itemIndex, List<Map> allItems, String currency) {
    final title = '${item['product_name'] ?? item['name'] ?? 'منتج شبيك'}';
    final vendorName = '${item['vendor_name'] ?? item['vendor'] ?? 'متجر شبيك بلس'}';
    final currentImg = '${item['image'] ?? item['product_image'] ?? ''}';
    final price = num.tryParse('${item['price'] ?? item['unit_price'] ?? 0}') ?? 0;

    String currentColor = '${item['color'] ?? item['selected_color'] ?? ''}'.trim();
    String currentSize = '${item['size'] ?? item['selected_size'] ?? ''}'.trim();
    int currentQty = int.tryParse('${item['quantity'] ?? 1}') ?? 1;
    final noteCtrl = TextEditingController(text: '${item['notes'] ?? item['item_notes'] ?? ''}');

    final standardColors = ['أبيض', 'أسود', 'كحلي', 'أحمر', 'رمادي', 'زيتي', 'بيج', 'أزرق', 'بني'];
    final standardSizes = ['S', 'M', 'L', 'XL', 'XXL', '38', '39', '40', '41', '42', '43', '44', 'فري سايز'];

    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تعديل مواصفات المنتج في الطلب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF8B1D3B)),
                      const SizedBox(width: 5),
                      Text('متجر: $vendorName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1D3B))),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: currentImg.isNotEmpty
                            ? Image.network(
                                Product.normalizeUrl(currentImg),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B)),
                              )
                            : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Text('السعر: ${money(price, currency)} للقطعة', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),

                const Text('اختيار اللون المطلوب:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: standardColors.map((c) {
                    final sel = currentColor == c;
                    return ChoiceChip(
                      label: Text(c, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sel ? Colors.white : const Color(0xFF334155))),
                      selected: sel,
                      selectedColor: const Color(0xFF8B1D3B),
                      backgroundColor: const Color(0xFFF8FAFC),
                      onSelected: (_) => setSheetState(() => currentColor = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                const Text('اختيار المقاس المطلوب:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: standardSizes.map((s) {
                    final sel = currentSize == s;
                    return ChoiceChip(
                      label: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sel ? Colors.white : const Color(0xFF334155))),
                      selected: sel,
                      selectedColor: const Color(0xFF8B1D3B),
                      backgroundColor: const Color(0xFFF8FAFC),
                      onSelected: (_) => setSheetState(() => currentSize = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الكمية المطلوبة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: currentQty > 1 ? () => setSheetState(() => currentQty--) : null,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('$currentQty', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF059669)),
                            onPressed: () => setSheetState(() => currentQty++),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة خاصة للتاجر حول هذا المنتج (اختياري)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: updating
                        ? null
                        : () async {
                            setSheetState(() => updating = true);
                            try {
                              final updatedList = List<Map<dynamic, dynamic>>.from(allItems);
                              final updatedItem = Map<dynamic, dynamic>.from(item);
                              updatedItem['color'] = currentColor;
                              updatedItem['selected_color'] = currentColor;
                              updatedItem['size'] = currentSize;
                              updatedItem['selected_size'] = currentSize;
                              updatedItem['quantity'] = currentQty;
                              updatedItem['notes'] = noteCtrl.text.trim();
                              updatedList[itemIndex] = updatedItem;

                              num newTotal = 0;
                              for (final it in updatedList) {
                                final p = num.tryParse('${it['price'] ?? it['unit_price'] ?? 0}') ?? 0;
                                final q = int.tryParse('${it['quantity'] ?? 1}') ?? 1;
                                newTotal += (p * q);
                              }

                              final app = context.read<AppController>();
                              try {
                                await app.api.updateOrderDetails(widget.orderId, {
                                  'items': updatedList,
                                  'order_items': updatedList,
                                  'total': newTotal,
                                });
                              } catch (_) {}

                              if (mounted) {
                                setState(() {
                                  _orderData = {
                                    ...?_orderData,
                                    'items': updatedList,
                                    'total': newTotal,
                                  };
                                });
                                Navigator.pop(ctx);
                                showAppToast(context, 'تم تحديث مواصفات المنتج في الطلب بنجاح', isSuccess: true);
                              }
                            } catch (e) {
                              setSheetState(() => updating = false);
                              if (mounted) showAppToast(context, 'فشل تحديث المنتج: $e', isError: true);
                            }
                          },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1D3B)),
                    child: updating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('حفظ التعديلات في الطلب', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        content: const Text('هل أنت متأكد من رغبتك في إلغاء هذا الطلب واسترجاع قيمته للمحفظة؟', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final app = context.read<AppController>();
      await app.api.cancelOrder(widget.orderId);
      await app.refreshAll(quiet: true);
      await _fetchOrder();
      if (mounted) {
        showAppToast(context, 'تم إلغاء الطلب بنجاح', isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppToast(context, 'فشل إلغاء الطلب: $e', isError: true);
    }
  }

  Future<void> _confirmReceived() async {
    try {
      final app = context.read<AppController>();
      await app.api.confirmReceived(widget.orderId);
      await app.refreshAll(quiet: true);
      await _fetchOrder();
      if (mounted) {
        showAppToast(context, 'تم تأكيد استلام الطلب بنجاح. شكراً لتسوقك معنا!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppToast(context, 'فشل تأكيد الاستلام: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B1D3B))),
      );
    }

    final d = _orderData ?? {};
    final List<Map<dynamic, dynamic>> items = d['items'] is List
        ? (d['items'] as List)
            .whereType<Map>()
            .map<Map<dynamic, dynamic>>((item) => Map<dynamic, dynamic>.from(item))
            .toList()
        : <Map<dynamic, dynamic>>[];
    final status = '${d['status'] ?? 'pending'}';
    final currency = '${d['currency'] ?? 'YER'}';
    final isPending = status == 'pending' || status == 'placed' || status == 'received' || status == 'new' || status == 'under_review';
    final isShipped = status == 'shipped' || status == 'out_for_delivery';
    final isCompleted = status == 'completed' || status == 'delivered';
    final orderNumber = d['order_number'] ?? d['number'] ?? widget.orderId;
    final total = num.tryParse('${d['total'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل الطلب #$orderNumber',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: _fetchOrder,
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF64748B)),
            tooltip: 'تحديث حالة الطلب من الخادم',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // If order is unconfirmed / pending, show notice banner
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الطلب غير مؤكد بعد من التاجر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                        SizedBox(height: 2),
                        Text('يمكنك تعديل مواصفات أي منتج (اللون، المقاس، الكمية) بالضغط على زر التعديل بجوار المنتج.', style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 1. Five-step visual tracking timeline (Matching OrdersDetailView.tsx)
          _buildTimelineCard(status),
          const SizedBox(height: 12),

          // 2. Ordered Items List with merchant info & variant details
          _buildItemsCard(items, currency, isPending),
          const SizedBox(height: 12),

          // 3. Shipping Address Card
          _buildAddressCard(d),
          const SizedBox(height: 12),

          // 4. Payment Summary Card
          _buildPaymentSummaryCard(total, currency),
          const SizedBox(height: 12),

          // 5. Actions Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: widget.orderId, title: 'محادثة الطلب #$orderNumber')),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D3B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('محادثة التاجر / المندوب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),

              if (isShipped) ...[
                FilledButton.icon(
                  onPressed: _confirmReceived,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('تأكيد الاستلام', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
              ],

              if (isPending) ...[
                OutlinedButton.icon(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('إلغاء الطلب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String status) {
    int activeStep = 1;
    if (status == 'processing') activeStep = 2;
    if (status == 'shipped') activeStep = 3;
    if (status == 'out_for_delivery') activeStep = 4;
    if (status == 'completed' || status == 'delivered') activeStep = 5;

    final steps = const [
      'تم استلام وتأكيد الطلب',
      'قيد التجهيز والتغليف',
      'تم تسليم الشحنة للمندوب',
      'في الطريق إلى عنوانك',
      'تم الاستلام بنجاح',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_shipping_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'حالة وتتبع الشحنة الفعلي',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Column(
            children: List.generate(steps.length, (i) {
              final stepNumber = i + 1;
              final isDone = stepNumber <= activeStep;
              final isCurrent = stepNumber == activeStep;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : Text('$stepNumber', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: stepNumber < activeStep ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w900 : (isDone ? FontWeight.bold : FontWeight.w500),
                          color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<Map> items, String currency, bool isPending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'المنتجات المطلوبة وتفاصيلها',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length} ${items.length == 1 ? 'منتج' : 'منتجات'}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          if (items.isEmpty)
            const Text('منتجات متجر شبيك بلس المعتمدة', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
          else
            for (int i = 0; i < items.length; i++) ...[
              _buildSingleOrderItemRow(items[i], i, items, currency, isPending),
              if (i < items.length - 1) const Divider(height: 22, color: Color(0xFFF1F5F9)),
            ],
        ],
      ),
    );
  }

  Widget _buildSingleOrderItemRow(Map item, int index, List<Map> allItems, String currency, bool isPending) {
    final title = '${item['product_name'] ?? item['name'] ?? 'منتج شبيك'}';
    final vendorName = '${item['vendor_name'] ?? item['vendor'] ?? item['store_name'] ?? 'متجر شبيك بلس'}';
    final price = num.tryParse('${item['price'] ?? item['unit_price'] ?? 0}') ?? 0;
    final qty = int.tryParse('${item['quantity'] ?? 1}') ?? 1;
    final imgUrl = '${item['image'] ?? item['product_image'] ?? ''}';
    final color = '${item['color'] ?? item['selected_color'] ?? ''}'.trim();
    final size = '${item['size'] ?? item['selected_size'] ?? ''}'.trim();
    final notes = '${item['notes'] ?? item['item_notes'] ?? ''}'.trim();
    final sku = '${item['sku'] ?? ''}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF8B1D3B)),
              const SizedBox(width: 4),
              Text(
                'متجر: $vendorName',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: imgUrl.isNotEmpty
                    ? Image.network(
                        Product.normalizeUrl(imgUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B)),
                      )
                    : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF8B1D3B)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  if (sku.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('SKU: $sku', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (color.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _variantColor(color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(color, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      if (size.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('المقاس: $size', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('الكمية: $qty', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${money(price, currency)} للقطعة', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('ملاحظة: $notes', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              money(price * qty, currency),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
            ),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditItemSpecsDialog(item, index, allItems, currency),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1D3B),
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  backgroundColor: const Color(0xFFFFF1F2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text('تعديل مواصفات المنتج', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _variantColor(String c) {
    final lower = c.trim().toLowerCase();
    if (lower.contains('أسود') || lower.contains('اسود') || lower.contains('black')) return const Color(0xFF0F172A);
    if (lower.contains('أبيض') || lower.contains('ابيض') || lower.contains('white')) return const Color(0xFFCBD5E1);
    if (lower.contains('أحمر') || lower.contains('احمر') || lower.contains('red')) return const Color(0xFFDC2626);
    if (lower.contains('أزرق') || lower.contains('ازرق') || lower.contains('blue')) return const Color(0xFF2563EB);
    if (lower.contains('كحلي') || lower.contains('navy')) return const Color(0xFF1E3A8A);
    if (lower.contains('أخضر') || lower.contains('اخضر') || lower.contains('green')) return const Color(0xFF16A34A);
    if (lower.contains('زيتي') || lower.contains('olive')) return const Color(0xFF4D7C0F);
    if (lower.contains('رمادي') || lower.contains('gray') || lower.contains('grey')) return const Color(0xFF64748B);
    if (lower.contains('بيج') || lower.contains('beige')) return const Color(0xFFD4B996);
    if (lower.contains('بني') || lower.contains('brown')) return const Color(0xFF78350F);
    if (lower.contains('وردي') || lower.contains('pink')) return const Color(0xFFEC4899);
    return const Color(0xFF8B1D3B);
  }

  Widget _buildAddressCard(Map<String, dynamic> d) {
    final addr = d['shipping_address'] is Map ? d['shipping_address'] as Map : {};
    final gov = addr['governorate'] ?? 'صنعاء';
    final city = addr['city'] ?? 'حدة';
    final street = addr['street_details'] ?? addr['street'] ?? 'الشارع العام';
    final phone = addr['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: Color(0xFF8B1D3B), size: 18),
              SizedBox(width: 6),
              Text(
                'عنوان التوصيل والاستلام',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Text('$gov - $city, $street', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text('رقم هاتف المستلم: $phone', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(num total, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('طريقة الدفع:', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text('محفظة شبيك (مدفوع بالكامل)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                ],
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي الطلب:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(money(total, currency), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B))),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. ORDER CHAT SCREEN (Direct vendor and driver chat)
// =========================================================================
class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({super.key, required this.orderId, this.title});
  final int orderId;
  final String? title;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[
    {
      'sender': 'vendor',
      'text': 'أهلاً بك! تم استلام طلبك وجاري تجهيزه للشحن فوراً.',
      'time': '10:30 ص',
    },
    {
      'sender': 'user',
      'text': 'مرحباً، شكراً لكم، متى موعد التوصيل المتوقع؟',
      'time': '10:32 ص',
    },
    {
      'sender': 'vendor',
      'text': 'سيصلك المندوب اليوم خلال ساعتين إن شاء الله.',
      'time': '10:33 ص',
    },
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({
        'sender': 'user',
        'text': text,
        'time': 'الآن',
      });
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? 'محادثة الطلب #${widget.orderId}',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Quick suggestions
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              children: [
                _buildQuickChip('أين وصلت الشحنة؟'),
                _buildQuickChip('يرجى الاتصال بي عند الوصول'),
                _buildQuickChip('شكراً جزيلاً'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final isMe = m['sender'] == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF8B1D3B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m['text']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m['time']}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالتك للمتجر أو المندوب...',
                          hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B1D3B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        onPressed: () {
          setState(() {
            messages.add({'sender': 'user', 'text': label, 'time': 'الآن'});
          });
        },
      ),
    );
  }
}

// =========================================================================
// 6. CATEGORY PRODUCTS VIEW & SCREEN (Matching Screenshot 1)
// =========================================================================
class CategoryProductsView extends StatefulWidget {
  const CategoryProductsView({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  State<CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<CategoryProductsView> {
  late String selectedMainCategory;
  String selectedSubCategory = 'الكل';

  final List<String> mainCategories = [
    'الكل',
    'الإلكترونيات',
    'الملابس',
    'المأكولات',
    'العطور',
    'الرياضة',
    'الأحذية',
    'الساعات',
  ];

  final Map<String, List<String>> subCategoriesMap = {
    'الكل': ['الكل', 'هواتف', 'أجهزة لوحية', 'كمبيوترات', 'إكسسوارات', 'شاشات', 'سماعات'],
    'الإلكترونيات': ['الكل', 'هواتف', 'أجهزة لوحية', 'كمبيوترات', 'إكسسوارات', 'شاشات', 'سماعات'],
    'الملابس': ['الكل', 'رجالي', 'نسائي', 'أطفال', 'شتوي', 'صيفي', 'رسمي'],
    'المأكولات': ['الكل', 'حلويات', 'مشروبات', 'معلبات', 'مخبوزات', 'طازج'],
    'العطور': ['الكل', 'عطور رجالية', 'عطور نسائية', 'بخور وعود', 'معطرات جو'],
    'الرياضة': ['الكل', 'أجهزة رياضية', 'ملابس رياضية', 'أحذية رياضية', 'مكملات'],
    'الأحذية': ['الكل', 'أحذية رجالية', 'أحذية نسائية', 'أحذية رياضية', 'صنادل'],
    'الساعات': ['الكل', 'ساعات ذكية', 'ساعات كلاسيكية', 'ساعات رياضية'],
  };

  @override
  void initState() {
    super.initState();
    selectedMainCategory = widget.initialCategory ?? 'الكل';
    if (!mainCategories.contains(selectedMainCategory) && selectedMainCategory != 'جميع الأقسام') {
      mainCategories.insert(1, selectedMainCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final subList = subCategoriesMap[selectedMainCategory] ?? subCategoriesMap['الكل']!;

    // Filter products
    final products = app.products.where((p) {
      if (selectedMainCategory == 'الكل' || selectedMainCategory == 'جميع الأقسام') {
        if (selectedSubCategory == 'الكل') return true;
        return p.name.toLowerCase().contains(selectedSubCategory.toLowerCase()) ||
            p.categories.any((c) => c.toLowerCase().contains(selectedSubCategory.toLowerCase()));
      }

      final matchesMain = p.categories.contains(selectedMainCategory) ||
          p.name.toLowerCase().contains(selectedMainCategory.toLowerCase());

      if (selectedSubCategory == 'الكل') return matchesMain;

      final matchesSub = p.name.toLowerCase().contains(selectedSubCategory.toLowerCase()) ||
          p.categories.any((c) => c.toLowerCase().contains(selectedSubCategory.toLowerCase()));

      return matchesMain && matchesSub;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'أقسام وتصنيفات المنتجات',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 1. Level-1 Main Category Tabs (Matching Screenshot 1)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: false,
              itemCount: mainCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = mainCategories[i];
                final active = selectedMainCategory == cat;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedMainCategory = cat;
                      selectedSubCategory = 'الكل';
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
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
                        cat,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 2. Level-2 Sub-Category Tabs (Matching Screenshot 1)
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: false,
              itemCount: subList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final sub = subList[i];
                final active = selectedSubCategory == sub;
                return InkWell(
                  onTap: () => setState(() => selectedSubCategory = sub),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        sub,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. Sky-Blue Active Category Banner (Matching Screenshot 1)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.category_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصفح قسم: $selectedMainCategory ${selectedSubCategory != "الكل" ? "• $selectedSubCategory" : ""}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${products.length} منتج يندرج ضمن هذا القسم',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Products 2-Column Grid (Matching Screenshot 1)
          if (products.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text('لا توجد منتجات في هذا التصنيف حالياً', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                final price = p.salePrice ?? p.price;
                final isDiscounted = p.salePrice != null && p.salePrice! < p.price;
                final vendorName = p.vendorName ?? 'متجر شبيك المعتمد';

                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailView(product: p)),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image & Top Badges
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  color: const Color(0xFFF8FAFC),
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: p.image != null && p.image!.isNotEmpty
                                      ? Image.network(
                                          absoluteUrl(p.image!),
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
                              // Discount badge
                              if (isDiscounted)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('خصم', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              // Heart icon
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.favorite_border_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand / Subcategory pill
                              if (p.brand.isNotEmpty || p.categories.isNotEmpty)
                                Text(
                                  p.brand.isNotEmpty ? p.brand : p.categories.first,
                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              // Title
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 3),
                              // Store Name
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      vendorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.check_circle, size: 10, color: Color(0xFF059669)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Price and Add Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        money(price, p.currency),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF8B1D3B)),
                                      ),
                                      if (isDiscounted)
                                        Text(
                                          money(p.price, p.currency),
                                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough),
                                        ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {
                                      app.addToCart(p);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تمت إضافة "${p.name}" إلى السلة'),
                                          backgroundColor: const Color(0xFF059669),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B1D3B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
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
              },
            ),
        ],
      ),
    );
  }
}

class CategoriesFlutterScreen extends StatelessWidget {
  const CategoriesFlutterScreen({super.key});
  @override
  Widget build(BuildContext context) => const CategoryProductsView();
}
