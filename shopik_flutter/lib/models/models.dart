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
  Product({required this.id,required this.name,this.slug='',this.description='',this.brand='',this.price=0.0,this.salePrice,this.currency='YER',this.stock=0,this.image,this.gallery=const[],this.vendorName='',this.vendorId,this.categories=const[],this.variants=const[],this.rating=0.0,this.reviewsCount=0,this.soldCount=0});
  final int id; final String name; final String slug; final String description; final String brand; final double price; final num? salePrice; final String currency; final int stock; final String? image; final List<String> gallery; final String vendorName; final int? vendorId; final List<String> categories; final List<Map<String,dynamic>> variants; final double rating; final int reviewsCount; final num soldCount;
  factory Product.fromJson(Map<String,dynamic> j){final gallery=<String>[];final rawGallery=j['gallery']??j['images'];if(rawGallery is List){for(final g in rawGallery){if(g is String)gallery.add(g);else if(g is Map&&g['url']!=null)gallery.add(g['url'].toString());}}final cats=<String>[];final rc=j['categories'];if(rc is List){for(final c in rc){if(c is Map&&c['name']!=null)cats.add(c['name'].toString());else if(c is String)cats.add(c);}}final vars=<Map<String,dynamic>>[];if(j['variants'] is List)vars.addAll((j['variants'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)));return Product(id:int.tryParse('${j['id']??0}')??0,name:'${j['name']??''}',slug:'${j['slug']??''}',description:'${j['description']??''}',brand:'${j['brand']??''}',price:double.tryParse('${j['price']??j['effective_price']??0}')??0.0,salePrice:j['sale_price']==null?null:num.tryParse('${j['sale_price']}'),currency:'${j['currency']??'YER'}',stock:int.tryParse('${j['available_stock']??j['stock']??0}')??0,image:j['main_image_url']??j['main_image']??j['image'],gallery:gallery,vendorName:'${(j['vendor'] is Map?(j['vendor'] as Map)['store_name']:j['vendor_name'])??''}',vendorId:j['vendor'] is Map?int.tryParse('${(j['vendor'] as Map)['id']??''}'):int.tryParse('${j['vendor_id']??''}'),categories:cats,variants:vars,rating:double.tryParse('${j['rating']??0}')??0.0,reviewsCount:int.tryParse('${j['reviews_count']??0}')??0,soldCount:num.tryParse('${j['sold_count']??0}')??0);}
}
class OrderSummary{OrderSummary({required this.id,required this.number,required this.status,required this.total,this.currency='YER',this.createdAt});final int id;final String number;final String status;final num total;final String currency;final String? createdAt;factory OrderSummary.fromJson(Map<String,dynamic> j)=>OrderSummary(id:int.tryParse('${j['id']??0}')??0,number:'${j['order_number']??j['number']??j['id']}',status:'${j['status']??''}',total:num.tryParse('${j['total']??0}')??0,currency:'${j['currency']??'YER'}',createdAt:'${j['created_at']??''}'.isEmpty?null:'${j['created_at']}');}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
