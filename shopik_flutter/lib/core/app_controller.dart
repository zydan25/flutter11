import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'api_client.dart';

enum AppTab { home, payment, store, operations, settings }

class AppController extends ChangeNotifier {
  AppController(this.api);
  final ApiClient api;
  UserProfile? user;
  num walletBalance = 0;
  num get balance => walletBalance;
  String get balanceFormatted => money(walletBalance);
  int selectedTab = 0;
  void setTab(dynamic tab) {
    if (tab is AppTab) {
      selectedTab = tab.index;
    } else if (tab is int) {
      selectedTab = tab;
    }
    notifyListeners();
  }
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> operations = [];
  List<Map<String, dynamic>> statement = [];
  List<Map<String, dynamic>> notifications = [];
  List<Product> products = [];
  List<Map<String, dynamic>> vendors = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> addresses = [];
  List<OrderSummary> orders = [];
  List<Map<String, dynamic>> wifi = [];
  List<Map<String, dynamic>> wifiCards = [];
  List<Map<String, dynamic>> serviceCatalogRoots = [];
  Map<String, int> serviceSettingsMap = {};
  Map<String, Map<String, dynamic>> serviceSettingsObjectMap = {};
  Map<String, List<Map<String, dynamic>>> serviceGroupMap = {};
  Map<int, Map<String, dynamic>> serviceDetailsCache = {};
  List<Map<String, dynamic>> serviceSettingsRaw = [];
  Timer? _poller;

  // Global Cart State
  Map<int, int> cart = {};
  int get totalCartCount => cart.values.fold<int>(0, (sum, val) => sum + val);

  void addToCart(Product product, [int quantity = 1]) {
    cart[product.id] = (cart[product.id] ?? 0) + quantity;
    notifyListeners();
  }

  void removeFromCart(int productId) {
    cart.remove(productId);
    notifyListeners();
  }

  void updateCartQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      cart.remove(productId);
    } else {
      cart[productId] = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
  void notifyStateChanged() => notifyListeners();

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString('cached_user_json', jsonEncode({
          'id': user!.id,
          'phone': user!.phone,
          'first_name': user!.firstName,
          'middle_name': user!.middleName,
          'third_name': user!.thirdName,
          'last_name': user!.lastName,
          'governorate': user!.governorate,
          'account_type': user!.accountType,
          'avatar': user!.avatar,
          'city_id': user!.cityId,
        }));
      }
      await prefs.setDouble('cached_wallet_balance', walletBalance.toDouble());
      if (products.isNotEmpty) {
        await prefs.setString('cached_products_json', jsonEncode(products.map((p) => {
          'id': p.id,
          'name': p.name,
          'brand': p.brand,
          'description': p.description,
          'price': p.price,
          'sale_price': p.salePrice,
          'currency': p.currency,
          'stock': p.stock,
          'image': p.image,
          'gallery': p.gallery,
          'categories': p.categories,
          'vendor_name': p.vendorName,
          'rating': p.rating,
          'reviews_count': p.reviewsCount,
        }).toList()));
      }
      if (categories.isNotEmpty) {
        await prefs.setString('cached_categories_json', jsonEncode(categories));
      }
      if (vendors.isNotEmpty) {
        await prefs.setString('cached_vendors_json', jsonEncode(vendors));
      }
      if (operations.isNotEmpty) {
        await prefs.setString('cached_operations_json', jsonEncode(operations.take(30).toList()));
      }
      if (serviceCatalogRoots.isNotEmpty) {
        await prefs.setString('cached_catalog_json', jsonEncode(serviceCatalogRoots));
      }
      if (serviceDetailsCache.isNotEmpty) {
        final cacheToSave = <String, dynamic>{};
        serviceDetailsCache.forEach((k, v) {
          cacheToSave['$k'] = v;
        });
        await prefs.setString('cached_service_details_json', jsonEncode(cacheToSave));
      }
      if (serviceSettingsRaw.isNotEmpty) {
        await prefs.setString('cached_service_settings_json', jsonEncode(serviceSettingsRaw));
      }
    } catch (_) {}
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Instant local cache hydration
    final cachedUserJson = prefs.getString('cached_user_json');
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedUserJson);
        user = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }
    final cachedBal = prefs.getDouble('cached_wallet_balance');
    if (cachedBal != null) walletBalance = cachedBal;

    final cachedProd = prefs.getString('cached_products_json');
    if (cachedProd != null && cachedProd.isNotEmpty) {
      try {
        final list = jsonDecode(cachedProd);
        if (list is List) products = list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }
    final cachedCat = prefs.getString('cached_categories_json');
    if (cachedCat != null && cachedCat.isNotEmpty) {
      try {
        final list = jsonDecode(cachedCat);
        if (list is List) categories = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    final cachedOps = prefs.getString('cached_operations_json');
    if (cachedOps != null && cachedOps.isNotEmpty) {
      try {
        final list = jsonDecode(cachedOps);
        if (list is List) operations = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    final cachedCatTree = prefs.getString('cached_catalog_json');
    if (cachedCatTree != null && cachedCatTree.isNotEmpty) {
      try {
        final list = jsonDecode(cachedCatTree);
        if (list is List) serviceCatalogRoots = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    final cachedServices = prefs.getString('cached_service_details_json');
    if (cachedServices != null && cachedServices.isNotEmpty) {
      try {
        final map = jsonDecode(cachedServices);
        if (map is Map) {
          map.forEach((k, v) {
            final sid = int.tryParse('$k');
            if (sid != null && v is Map) {
              serviceDetailsCache[sid] = Map<String, dynamic>.from(v);
            }
          });
        }
      } catch (_) {}
    }
    final cachedSettings = prefs.getString('cached_service_settings_json');
    if (cachedSettings != null && cachedSettings.isNotEmpty) {
      try {
        final list = jsonDecode(cachedSettings);
        if (list is List) {
          serviceSettingsRaw = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _populateServiceSettingsMaps(serviceSettingsRaw);
        }
      } catch (_) {}
    }

    if (user != null || prefs.getBool('logged_in') == true) {
      notifyListeners();
      _startPolling();
      unawaited(_backgroundRefresh());
    }
  }

  Future<void> _backgroundRefresh() async {
    try {
      final profile = await api.me();
      final rawUser = profile['user'];
      user = UserProfile.fromJson(rawUser is Map ? Map<String, dynamic>.from(rawUser) : profile);
      await refreshAll(quiet: true);
      await _saveLocalCache();
    } catch (_) {
      // Keep cached data when offline or server unreachable
    }
  }

  Future<bool> biometricQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setBool('logged_in', true);
      _startPolling();
      unawaited(_backgroundRefresh());
      notifyListeners();
      return true;
    }

    final cachedUserJson = prefs.getString('cached_user_json');
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedUserJson);
        user = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
        await prefs.setBool('logged_in', true);
        _startPolling();
        unawaited(_backgroundRefresh());
        notifyListeners();
        return true;
      } catch (_) {}
    }

    try {
      final profile = await api.me();
      final rawUser = profile['user'];
      user = UserProfile.fromJson(rawUser is Map ? Map<String, dynamic>.from(rawUser) : profile);
      await prefs.setBool('logged_in', true);
      _startPolling();
      unawaited(_backgroundRefresh());
      notifyListeners();
      return true;
    } catch (_) {}

    final savedPhone = prefs.getString('saved_phone');
    if (savedPhone != null && savedPhone.isNotEmpty) {
      user = UserProfile(
        id: 1,
        phone: savedPhone,
        fullName: 'مستخدم شبيك',
        governorate: 'صنعاء',
        accountType: 'مستخدم معتمد',
      );
      await prefs.setBool('logged_in', true);
      await _saveLocalCache();
      _startPolling();
      unawaited(_backgroundRefresh());
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String identifier, String password) async {
    loading = true; error = null; notifyListeners();
    try {
      final data = await api.login(identifier, password);
      final rawUser = data['user'];
      user = UserProfile.fromJson(rawUser is Map ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('saved_phone', identifier);
      await _saveLocalCache();
      await refreshAll(quiet: true); _startPolling(); return true;
    } catch (e) { error = e.toString(); return false; }
    finally { loading = false; notifyListeners(); }
  }

  Future<bool> register({required String phone, required String password, required String fullName, required String governorate}) async {
    loading = true; error = null; notifyListeners();
    try {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      final data = await api.register(phone: phone, password: password, firstName: parts.isNotEmpty ? parts.first : '', middleName: parts.length > 1 ? parts[1] : '', thirdName: parts.length > 2 ? parts[2] : '', lastName: parts.length > 3 ? parts.sublist(3).join(' ') : '', governorate: governorate);
      final rawUser = data['user'];
      user = UserProfile.fromJson(rawUser is Map ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('saved_phone', phone);
      await _saveLocalCache();
      await refreshAll(quiet: true); _startPolling(); return true;
    } catch (e) { error = e.toString(); return false; }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> logout({bool localOnly = false}) async {
    _poller?.cancel(); if (!localOnly) await api.logout();
    user = null; walletBalance = 0; operations = []; statement = []; notifications = []; products = []; vendors = []; categories = []; addresses = []; orders = []; wifi = []; wifiCards = []; serviceCatalogRoots = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
    await prefs.remove('cached_user_json');
    await prefs.remove('cached_wallet_balance');
    notifyListeners();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 15), (_) async { try { await refreshWalletAndReports(); } catch (_) {} });
  }

  static const _headsUpChannel = MethodChannel('com.shopik.app/heads_up_notifications');

  Future<void> showHeadsUpNotification({required String title, required String body, int? id}) async {
    final notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
    notifications.insert(0, {
      'id': notifId,
      'title': title,
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });
    notifyListeners();
    try {
      await _headsUpChannel.invokeMethod('showHeadsUpNotification', {
        'title': title,
        'body': body,
        'id': notifId,
      });
    } catch (_) {}
  }

  Future<void> refreshWalletAndReports() async {
    final balance = await api.walletBalance();
    final rawAvailable = balance['customer'] is Map ? (balance['customer'] as Map)['available'] : balance['available'];
    if (rawAvailable != null) walletBalance = num.tryParse('$rawAvailable') ?? walletBalance;
    try { final rawStatement = await api.walletStatement(); final value = rawStatement['statement']; statement = value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : []; } catch (_) {}
    try {
      final rawOps = await api.serviceReports();
      // Filter strictly to non-inquiry operations (exclude check, inquiry, query, loan inquiry)
      operations = rawOps.where((op) {
        final text = '${op['service'] ?? op['packageName'] ?? op['item_name'] ?? op['notes'] ?? op['type'] ?? ''}'.toLowerCase();
        final isExcluded = ['inquiry', 'check', 'query', 'استعلام', 'فحص', 'سلفة', 'معاينة'].any((w) => text.contains(w));
        return !isExcluded;
      }).toList();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> deductBalance(double amount, String note) async {
    if (walletBalance < amount) return false;
    walletBalance -= amount;
    notifyListeners();
    try { await refreshWalletAndReports(); } catch (_) {}
    return true;
  }

  Future<void> refreshCatalog() async {
    try {
      final data = await api.serviceCatalog();
      final raw = data['categories'];
      serviceCatalogRoots = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (_) {}

    try {
      final sData = await api.serviceSettings();
      final list = sData['settings'];
      if (list is List) {
        serviceSettingsRaw = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _populateServiceSettingsMaps(serviceSettingsRaw);
      }
    } catch (_) {}

    // Pre-load active service contracts in the background (Yemen Mobile, Sabafon, YOU, Way, Yemen4G, YemenNet)
    _preloadCoreServices();

    notifyListeners();
  }

  void _populateServiceSettingsMaps(List<Map<String, dynamic>> rawList) {
    serviceSettingsMap.clear();
    serviceSettingsObjectMap.clear();
    serviceGroupMap.clear();
    for (final item in rawList) {
      final key = '${item['key'] ?? ''}'.trim();
      final svcId = int.tryParse('${item['service_id'] ?? ''}');
      final group = '${item['group'] ?? ''}'.trim();
      if (key.isNotEmpty) {
        serviceSettingsObjectMap[key] = item;
        if (svcId != null && svcId > 0) {
          serviceSettingsMap[key] = svcId;
        }
      }
      if (group.isNotEmpty) {
        serviceGroupMap.putIfAbsent(group, () => []).add(item);
      }
    }
  }

  Future<void> syncTelecomData({bool force = true}) async {
    try {
      final sData = await api.serviceSettings();
      final list = sData['settings'];
      if (list is List) {
        serviceSettingsRaw = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _populateServiceSettingsMaps(serviceSettingsRaw);
      }
    } catch (_) {}

    final targetIds = <int>{1, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 60, 61};
    final settingKeys = [
      'bagatmobileget', 'yemen_mobile_packages_list', 'featmobile', 'yemen_mobile_denominations_list', 'yemen_mobile_recharge',
      'bagatsabafonget', 'sabafon_packages_legacy', 'sabafon_north_packages_list', 'featsabafon', 'sabafon_north_denominations_list',
      'bagatyouget', 'bagatyou', 'you_packages_list', 'featyou', 'you_denominations_list',
      'bagatwayget', 'wai_packages_list', 'featway', 'wai_denominations_list',
      'yemen4g_packages_list', 'yemen4g_packages_pay', 'yemen4g_package_change', 'yemen4g_recharge',
      'yemen_net_packages_list', 'yemen_net_package_pay', 'yemen_net_landline_pay',
    ];
    for (final k in settingKeys) {
      final sid = getServiceId(k);
      if (sid != null && sid > 0) targetIds.add(sid);
    }

    final futures = targetIds.map((sid) async {
      try {
        final res = await api.serviceDetail(sid);
        if (res.isNotEmpty) {
          serviceDetailsCache[sid] = res;
        }
      } catch (_) {}
    });

    await Future.wait(futures);
    await _saveLocalCache();
    notifyListeners();
  }

  void _preloadCoreServices() {
    final idsToPreload = <int>{};
    // Extract configured IDs or default to primary telecom service IDs
    final keys = [
      'bagatmobileget', 'yemen_mobile_packages_list', 'featmobile', 'yemen_mobile_denominations_list', 'yemen_mobile_recharge',
      'bagatsabafonget', 'sabafon_packages_legacy', 'sabafon_north_packages_list', 'featsabafon', 'sabafon_north_denominations_list', 'sabafon_instant_recharge',
      'bagatyouget', 'bagatyou', 'you_packages_list', 'featyou', 'you_denominations_list', 'you_instant_recharge_legacy',
      'bagatwayget', 'wai_packages_list', 'featway', 'wai_denominations_list',
      'yemen4g_packages_list', 'yemen4g_packages_pay', 'yemen4g_package_change', 'yemen4g_recharge',
      'yemen_net_packages_list', 'yemen_net_package_pay', 'yemen_net_landline_pay',
    ];
    for (final k in keys) {
      final id = getServiceId(k);
      if (id != null && id > 0) idsToPreload.add(id);
    }
    // Baseline IDs if not yet loaded from settings
    idsToPreload.addAll([1, 2, 3, 4, 7, 8, 9, 13, 14, 15, 16, 18, 19, 20, 21, 23, 24]);

    for (final sid in idsToPreload) {
      if (!serviceDetailsCache.containsKey(sid)) {
        loadServiceContract(sid);
      }
    }
  }

  Future<Map<String, dynamic>?> loadServiceContract(int serviceId, {bool force = false}) async {
    if (!force && serviceDetailsCache.containsKey(serviceId)) {
      return serviceDetailsCache[serviceId];
    }
    try {
      final res = await api.serviceDetail(serviceId);
      if (res.isNotEmpty) {
        serviceDetailsCache[serviceId] = res;
        notifyListeners();
        return res;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? getSetting(String key, {List<String> fallbacks = const []}) {
    if (serviceSettingsObjectMap.containsKey(key)) return serviceSettingsObjectMap[key];
    for (final f in fallbacks) {
      if (serviceSettingsObjectMap.containsKey(f)) return serviceSettingsObjectMap[f];
    }
    return null;
  }

  int? getServiceId(String key, {List<String> fallbacks = const [], int? defaultId}) {
    if (serviceSettingsMap.containsKey(key)) return serviceSettingsMap[key];
    for (final f in fallbacks) {
      if (serviceSettingsMap.containsKey(f)) return serviceSettingsMap[f];
    }
    return defaultId;
  }

  String getServiceName(String key, {List<String> fallbacks = const [], String? defaultName, int? serviceId}) {
    final setting = getSetting(key, fallbacks: fallbacks);
    if (setting != null && setting['service'] is Map && setting['service']['name'] != null) {
      return '${setting['service']['name']}';
    }
    if (serviceId != null && serviceDetailsCache.containsKey(serviceId)) {
      final name = '${serviceDetailsCache[serviceId]!['name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    if (setting != null && setting['name'] != null) {
      return '${setting['name']}';
    }
    return defaultName ?? 'خدمة السداد المباشر';
  }

  Future<Map<String, dynamic>?> resolveSettingServiceContract(String key, {List<String> fallbacks = const [], int? fallbackId}) async {
    final sid = getServiceId(key, fallbacks: fallbacks, defaultId: fallbackId);
    if (sid != null && sid > 0) {
      return await loadServiceContract(sid);
    }
    return null;
  }

  Future<void> refreshOptional() async {
    Future<void> safe(Future<void> Function() action) async { try { await action(); } catch (_) {} }
    await Future.wait([
      safe(() async => notifications = await api.notifications()),
      safe(() async => products = (await api.products()).map(Product.fromJson).toList()),
      safe(() async => vendors = await api.vendors()),
      safe(() async => categories = await api.categories()),
      safe(() async => addresses = await api.addresses()),
      safe(() async => orders = (await api.orders()).map(OrderSummary.fromJson).toList()),
      safe(() async => wifi = await api.wifiNetworks()),
      safe(() async => wifiCards = await api.wifiCards()),
      safe(refreshCatalog),
    ]);
    notifyListeners();
  }

  Future<void> refreshAll({bool quiet = false}) async {
    if (!quiet) { loading = true; error = null; notifyListeners(); }
    try { await refreshWalletAndReports(); await refreshOptional(); } catch (e) { error = e.toString(); }
    finally { if (!quiet) { loading = false; notifyListeners(); } }
  }

  List<Map<String, dynamic>> get catalogServices {
    final out = <Map<String, dynamic>>[];
    void walk(dynamic node) {
      if (node is! Map) return;
      final services = node['services']; if (services is List) { for (final entry in services) { if (entry is Map) out.add(Map<String, dynamic>.from(entry)); } }
      final children = node['children']; if (children is List) { for (final entry in children) { walk(entry); } }
      final categories = node['categories']; if (categories is List) { for (final entry in categories) { walk(entry); } }
    }
    for (final root in serviceCatalogRoots) { walk(root); }
    return out;
  }

  List<Map<String, dynamic>> servicesFor(String operatorKey) {
    final keys = <String, List<String>>{
      'yemen_mobile': ['yemen_mobile', 'يمن موبايل'], 'you': ['you', 'يو'], 'sabafon': ['sabafon', 'سبأفون'], 'y': [' y ', ' y_', 'واي', 'واي موبايل'], 'yemen4g': ['4g', 'فورجي', 'يمن 4g'], 'yemen_net': ['yemen_net', 'يمن نت', 'adsl'], 'aden_net': ['aden_net', 'عدن نت']
    };
    final needles = keys[operatorKey] ?? [];
    return catalogServices.where((s) { final haystack = '${s['code'] ?? ''} ${s['name'] ?? ''} ${s['description'] ?? ''}'.toLowerCase(); return needles.any((k) => haystack.contains(k.toLowerCase())); }).toList();
  }

  Future<Map<String, dynamic>> requestService({required int serviceId, required Map<String, dynamic> payload, String? itemType, int? itemId, String? idempotencyKey}) async {
    final tx = await api.serviceRequest(serviceId: serviceId, payload: payload, itemType: itemType, itemId: itemId, idempotencyKey: idempotencyKey);
    var latest = tx; final id = tx['id']?.toString();
    if (id != null && ['accepted', 'queued', 'pending', 'pending_provider', 'processing'].contains('${tx['status']}')) {
      for (var i = 0; i < 20; i++) { await Future.delayed(const Duration(milliseconds: 1200)); latest = await api.serviceTransaction(id); if (['success', 'failed', 'refunded', 'manual_review'].contains('${latest['status']}')) break; }
    }
    return latest;
  }
  Future<Map<String, dynamic>> recipientLookup(String phone) => api.giftLookup(phone);
  @override void dispose() { _poller?.cancel(); super.dispose(); }
}
