class UserProfile {
  UserProfile({
    required this.id,
    required this.phone,
    String? name,
    String? fullName,
    this.governorate = '',
    this.role = 'customer',
    this.points = 0,
    String? accountType,
    this.avatar,
    this.cityId,
  })  : name = ((fullName != null && fullName.trim().isNotEmpty) ? fullName : name ?? '').trim(),
        _accountType = (accountType ?? '').trim();

  final int id;
  final String phone;
  final String name;
  final String governorate;
  final String role;
  final num points;
  final String? avatar;
  final int? cityId;
  final String _accountType;

  String get firstName => _namePart(0);
  String get middleName => _namePart(1);
  String get thirdName => _namePart(2);
  String get lastName => _namePart(3);
  String get accountType => _accountType.isNotEmpty ? _accountType : role;

  String _namePart(int index) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return index < parts.length ? parts[index] : '';
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final composedName = [j['first_name'], j['middle_name'], j['third_name'], j['last_name']]
        .where((e) => '${e ?? ''}'.trim().isNotEmpty)
        .join(' ')
        .trim();
    final fallbackName = '${j['name'] ?? j['username'] ?? j['phone'] ?? ''}'.trim();
    return UserProfile(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      phone: '${j['phone'] ?? ''}',
      name: composedName.isNotEmpty ? composedName : fallbackName,
      governorate: '${j['governorate'] ?? ''}',
      role: '${j['role'] ?? 'customer'}',
      points: j['points_balance'] ?? 0,
      accountType: '${j['account_type'] ?? ''}',
      avatar: j['avatar']?.toString(),
      cityId: int.tryParse('${j['city_id'] ?? ''}'),
    );
  }
}

class ServiceItem{ServiceItem({required this.id,required this.name,this.kind='',this.type='',this.price,this.metadata=const{}});final int id;final String name;final String kind;final String type;final num? price;final Map<String,dynamic> metadata;}
class Product {
  Product({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.brand = '',
    this.price = 0.0,
    this.salePrice,
    this.currency = 'YER',
    this.stock = 0,
    this.availableStock = 0,
    this.reservedStock = 0,
    this.discountPercent = 0,
    this.image,
    this.gallery = const [],
    this.vendorName = '',
    this.vendorId,
    this.vendorLogo,
    this.vendorCover,
    this.vendorPhone,
    this.categories = const [],
    this.variants = const [],
    this.colors = const [],
    this.sizes = const [],
    this.details = const {},
    this.hashtags = const [],
    this.customCategoryName,
    this.sku = '',
    this.material = '',
    this.shippingNote = '',
    this.returnPolicy = '',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.soldCount = 0,
    this.rawJson = const {},
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String brand;
  final double price;
  final num? salePrice;
  final String currency;
  final int stock;
  final int availableStock;
  final int reservedStock;
  final int discountPercent;
  final String? image;
  final List<String> gallery;
  final String vendorName;
  final int? vendorId;
  final String? vendorLogo;
  final String? vendorCover;
  final String? vendorPhone;
  final List<String> categories;
  final List<Map<String, dynamic>> variants;
  final List<Map<String, dynamic>> colors;
  final List<Map<String, dynamic>> sizes;
  final Map<String, dynamic> details;
  final List<String> hashtags;
  final String? customCategoryName;
  final String sku;
  final String material;
  final String shippingNote;
  final String returnPolicy;
  final double rating;
  final int reviewsCount;
  final num soldCount;
  final Map<String, dynamic> rawJson;

  static String normalizeUrl(dynamic raw) {
    if (raw == null) return '';
    String s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return '';
    if (s.startsWith('//')) return 'https:$s';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (!s.startsWith('/')) s = '/$s';
    return 'https://shopik.alattab.site$s';
  }

  factory Product.fromJson(Map<String, dynamic> j) {
    final gallery = <String>[];
    final rawGallery = j['gallery'] ?? j['images'];
    if (rawGallery is List) {
      for (final g in rawGallery) {
        if (g is String) {
          final u = normalizeUrl(g);
          if (u.isNotEmpty && !gallery.contains(u)) gallery.add(u);
        } else if (g is Map) {
          final u = normalizeUrl(g['url'] ?? g['image'] ?? g['image_url']);
          if (u.isNotEmpty && !gallery.contains(u)) gallery.add(u);
        }
      }
    }

    // Resolve main image: check main_image_url, main_image, image, then gallery first item
    String rawImg = '${j['main_image_url'] ?? j['main_image'] ?? j['image'] ?? ''}'.trim();
    if (rawImg == 'null' || rawImg.isEmpty) {
      rawImg = gallery.isNotEmpty ? gallery.first : '';
    }
    final finalImg = rawImg.isNotEmpty ? normalizeUrl(rawImg) : null;
    if (finalImg != null && finalImg.isNotEmpty && !gallery.contains(finalImg)) {
      gallery.insert(0, finalImg);
    }

    final cats = <String>[];
    final rc = j['categories'];
    if (rc is List) {
      for (final c in rc) {
        if (c is Map && c['name'] != null) {
          cats.add(c['name'].toString());
        } else if (c is String) {
          cats.add(c);
        }
      }
    }

    final vars = <Map<String, dynamic>>[];
    if (j['variants'] is List) {
      vars.addAll((j['variants'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }

    final cols = <Map<String, dynamic>>[];
    if (j['colors'] is List) {
      cols.addAll((j['colors'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }

    final szs = <Map<String, dynamic>>[];
    if (j['sizes'] is List) {
      szs.addAll((j['sizes'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    }

    final htags = <String>[];
    if (j['hashtags'] is List) {
      for (final h in j['hashtags']) {
        if (h != null && h.toString().isNotEmpty) htags.add(h.toString());
      }
    }

    final detailsMap = j['details'] is Map ? Map<String, dynamic>.from(j['details'] as Map) : <String, dynamic>{};

    // Vendor parsing
    final vMap = j['vendor'] is Map ? (j['vendor'] as Map) : null;
    final vName = '${vMap?['store_name'] ?? j['vendor_name'] ?? ''}'.trim();
    final vId = vMap != null ? int.tryParse('${vMap['id'] ?? ''}') : int.tryParse('${j['vendor_id'] ?? ''}');
    final vLogo = normalizeUrl(vMap?['logo_url']);
    final vCover = normalizeUrl(vMap?['cover_url']);
    final vPhone = vMap?['phone']?.toString() ?? j['vendor_phone']?.toString();

    final pr = double.tryParse('${j['price'] ?? j['effective_price'] ?? 0}') ?? 0.0;
    final slPr = j['sale_price'] == null ? null : num.tryParse('${j['sale_price']}');
    final disc = int.tryParse('${j['discount_percent'] ?? 0}') ??
        (slPr != null && pr > 0 && slPr < pr ? (((pr - slPr) / pr) * 100).round() : 0);

    return Product(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      name: '${j['name'] ?? ''}',
      slug: '${j['slug'] ?? ''}',
      description: '${j['description'] ?? ''}',
      brand: '${j['brand'] ?? ''}',
      price: pr,
      salePrice: slPr,
      currency: '${j['currency'] ?? 'YER'}',
      stock: int.tryParse('${j['stock'] ?? j['available_stock'] ?? 0}') ?? 0,
      availableStock: int.tryParse('${j['available_stock'] ?? j['stock'] ?? 0}') ?? 0,
      reservedStock: int.tryParse('${j['reserved_stock'] ?? 0}') ?? 0,
      discountPercent: disc,
      image: finalImg,
      gallery: gallery,
      vendorName: vName,
      vendorId: vId,
      vendorLogo: vLogo.isNotEmpty ? vLogo : null,
      vendorCover: vCover.isNotEmpty ? vCover : null,
      vendorPhone: vPhone,
      categories: cats,
      variants: vars,
      colors: cols,
      sizes: szs,
      details: detailsMap,
      hashtags: htags,
      customCategoryName: j['custom_category_name']?.toString(),
      sku: '${j['sku'] ?? ''}',
      material: '${j['material'] ?? ''}',
      shippingNote: '${j['shipping_note'] ?? ''}',
      returnPolicy: '${j['return_policy'] ?? ''}',
      rating: double.tryParse('${j['rating'] ?? 0}') ?? 0.0,
      reviewsCount: int.tryParse('${j['reviews_count'] ?? 0}') ?? 0,
      soldCount: num.tryParse('${j['sold_count'] ?? 0}') ?? 0,
      rawJson: Map<String, dynamic>.from(j),
    );
  }
}
class OrderSummary{OrderSummary({required this.id,required this.number,required this.status,required this.total,this.currency='YER',this.createdAt});final int id;final String number;final String status;final num total;final String currency;final String? createdAt;factory OrderSummary.fromJson(Map<String,dynamic> j)=>OrderSummary(id:int.tryParse('${j['id']??0}')??0,number:'${j['order_number']??j['number']??j['id']}',status:'${j['status']??''}',total:num.tryParse('${j['total']??0}')??0,currency:'${j['currency']??'YER'}',createdAt:'${j['created_at']??''}'.isEmpty?null:'${j['created_at']}');}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
