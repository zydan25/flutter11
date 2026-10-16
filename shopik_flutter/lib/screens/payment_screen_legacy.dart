import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'screen_common.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PackageItem {
  final int id;
  final String name;
  final String category;
  final String subTitle;
  final double price;
  final String days;
  final String calls;
  final String sms;
  final String internet;
  final double? netDiscountPrice;
  final String code;
  final int serviceId;
  final String subCategory;
  final String description;
  final Map<String, dynamic>? rawItem;

  const _PackageItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subTitle,
    required this.price,
    required this.days,
    this.calls = '',
    this.sms = '',
    this.internet = '',
    this.netDiscountPrice,
    this.code = '',
    this.serviceId = 0,
    this.subCategory = 'دفع مسبق',
    this.description = '',
    this.rawItem,
  });
}

class _DenominationItem {
  final int? id;
  final String? name;
  final int tier;
  final double price;
  final String days;
  final String itemType;
  const _DenominationItem({
    this.id,
    this.name,
    required this.tier,
    required this.price,
    required this.days,
    this.itemType = '',
  });
}

class _ActiveSubItem {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String type;
  const _ActiveSubItem({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
  });
}

class _OperatorSpec {
  final String id;
  final String name;
  final String shortName;
  final Color headerColor;
  final Color activeTabColor;
  final String prefix;
  final bool hasUnits;
  final bool hasInquiryInBalance;
  final List<String> mainTabs;

  const _OperatorSpec({
    required this.id,
    required this.name,
    required this.shortName,
    required this.headerColor,
    required this.activeTabColor,
    required this.prefix,
    required this.hasUnits,
    required this.hasInquiryInBalance,
    required this.mainTabs,
  });
}

class _PaymentScreenState extends State<PaymentScreen> {
  final phone = TextEditingController(text: '');
  final phoneFocusNode = FocusNode();
  final rechargeAmount = TextEditingController(text: '100');
  final unitsCount = TextEditingController(text: '10');

  String currentOpId = '';
  String activeMainTab = '';
  String billingFilter = 'الكل';
  String packageKindFilter = 'الكل';
  String sabafonRegion = 'شمال';
  bool youSmartCharger = false;
  String netTab = 'adsl';
  bool userBalanceHidden = false;
  String? operatorRestrictedToast;
  String? balanceInquiryBanner;

  // Inquiry states (Loaded dynamically via live server inquiry)
  String ymPhoneBalance = '---';
  String ymPhoneType = '---';
  String ymLoanStatus = 'unknown';
  double ymLoanAmount = 0.0;

  Map<String, dynamic>? fourGInquiryData;
  Map<String, dynamic>? netInquiryData;

  static const _nativeChannel = MethodChannel('com.shopik.app/heads_up_notifications');
  bool _isSyncing = false;
  bool _paymentInProgress = false;
  Timer? _offersInquiryDebounce;
  String? _lastOffersInquiryPhone;

  // Accordion state
  final Map<String, bool> expandedCategories = {
    'باقات مزايا': true,
    'باقات فورجي 4G': true,
    'باقات فولتي VoLTE': true,
    'باقات الإنترنت': true,
    'باقات هدايا وتوفير': false,
    'باقات 4G سبأفون': true,
    'باقات يابلاش ومكالمات': true,
    'باقات سوبرنت والإنترنت': false,
    'باقات سوى': true,
    'باقات التواصل الاجتماعية': false,
  };

  // Active subscriptions (Loaded dynamically from live server inquiry)
  List<_ActiveSubItem> activeSubscriptions = [];

  static const List<_OperatorSpec> operators = [
    _OperatorSpec(
      id: 'yemen_mobile',
      name: 'يمن موبايل',
      shortName: 'يم',
      headerColor: Color(0xFF8B1D3B),
      activeTabColor: Color(0xFF8B1D3B),
      prefix: '77',
      hasUnits: false,
      hasInquiryInBalance: true,
      mainTabs: ['رصيد', 'فوري', 'باقات', 'جملة', 'ريال'],
    ),
    _OperatorSpec(
      id: 'sabafon',
      name: 'سبأفون',
      shortName: 'سبأ',
      headerColor: Color(0xFF1E88E5),
      activeTabColor: Color(0xFF1E88E5),
      prefix: '71',
      hasUnits: true,
      hasInquiryInBalance: false,
      mainTabs: ['رصيد', 'فوري', 'باقات', 'جملة', 'ريال'],
    ),
    _OperatorSpec(
      id: 'you',
      name: 'YOU عمانتل',
      shortName: 'يو',
      headerColor: Color(0xFFD97706),
      activeTabColor: Color(0xFFD97706),
      prefix: '73',
      hasUnits: false,
      hasInquiryInBalance: false,
      mainTabs: ['رصيد', 'فوري', 'باقات', 'جملة', 'فوترة'],
    ),
    _OperatorSpec(
      id: 'y',
      name: 'شركة واي Y',
      shortName: 'واي',
      headerColor: Color(0xFFDC2626),
      activeTabColor: Color(0xFFDC2626),
      prefix: '79',
      hasUnits: false,
      hasInquiryInBalance: false,
      mainTabs: ['رصيد', 'فوري', 'باقات'],
    ),
    _OperatorSpec(
      id: 'yemen4g',
      name: 'يمن فورجي 4G',
      shortName: '4G',
      headerColor: Color(0xFF0284C7),
      activeTabColor: Color(0xFF0284C7),
      prefix: '10',
      hasUnits: false,
      hasInquiryInBalance: true,
      mainTabs: ['باقة يمن 4G', 'رصيد يمن 4G', 'تغيير الباقة', 'فايبر'],
    ),
    _OperatorSpec(
      id: 'yemen_net',
      name: 'يمن نت ADSL',
      shortName: 'نت',
      headerColor: Color(0xFF283593),
      activeTabColor: Color(0xFF283593),
      prefix: '01',
      hasUnits: false,
      hasInquiryInBalance: true,
      mainTabs: ['الانترنت الارضي', 'الهاتف الثابت'],
    ),
  ];

  _OperatorSpec get currentOp => operators.firstWhere((o) => o.id == currentOpId, orElse: () => operators.first);

  ({int id, String name}) _resolveServiceForCurrentAction({
    required String actionType,
    AppController? appInstance,
  }) {
    final app = appInstance ?? context.read<AppController>();
    if (actionType == 'fourg_pay' && currentOpId == 'yemen4g') {
      final id = app.getServiceId('yemen4g_packages_pay', fallbacks: ['yemen4g_packages_list'], defaultId: 20)!;
      final name = app.getServiceName('yemen4g_packages_pay', fallbacks: ['yemen4g_packages_list'], serviceId: id, defaultName: 'يمن فورجي - سداد باقة');
      return (id: id, name: name);
    } else if (actionType == 'packages') {
      if (currentOpId == 'yemen_mobile') {
        final id = app.getServiceId('bagatmobileget', fallbacks: ['yemen_mobile_packages_list', 'yemen_mobile_package_pay_activate', 'yemen_mobile_packages_query', 'yemen_mobile_packages_legacy'], defaultId: 4)!;
        final name = app.getServiceName('bagatmobileget', fallbacks: ['yemen_mobile_packages_list'], serviceId: id, defaultName: 'Yemen Mobile - تفعيل باقة');
        return (id: id, name: name);
      } else if (currentOpId == 'sabafon') {
        final id = app.getServiceId('bagatsabafonget', fallbacks: ['sabafon_north_packages_list', 'sabafon_packages_legacy', 'sabafon_packages'], defaultId: 9)!;
        final name = app.getServiceName('bagatsabafonget', fallbacks: ['sabafon_north_packages_list', 'sabafon_packages_legacy'], serviceId: id, defaultName: 'سبأفون - باقات');
        return (id: id, name: name);
      } else if (currentOpId == 'you') {
        final id = app.getServiceId('bagatyouget', fallbacks: ['bagatyou', 'you_packages_list', 'you_packages_legacy'], defaultId: 15)!;
        final name = app.getServiceName('bagatyouget', fallbacks: ['bagatyou', 'you_packages_list'], serviceId: id, defaultName: 'يو - باقات');
        return (id: id, name: name);
      } else if (currentOpId == 'y') {
        final id = app.getServiceId('bagatwayget', fallbacks: ['bagat_way', 'wai_packages_list', 'wai_package_pay_activate'], defaultId: 18)!;
        final name = app.getServiceName('bagatwayget', fallbacks: ['bagat_way', 'wai_packages_list'], serviceId: id, defaultName: 'واي - باقات');
        return (id: id, name: name);
      } else if (currentOpId == 'yemen4g') {
        final id = app.getServiceId('yemen4g_packages_list', fallbacks: ['yemen4g_packages_pay', 'yemen4g'], defaultId: 19)!;
        final name = app.getServiceName('yemen4g_packages_list', fallbacks: ['yemen4g_packages_pay'], serviceId: id, defaultName: 'يمن فورجي - باقة');
        return (id: id, name: name);
      } else if (currentOpId == 'yemen_net') {
        final id = app.getServiceId('yemen_net_packages_list', fallbacks: ['yemen_net_package_pay'], defaultId: 23)!;
        final name = app.getServiceName('yemen_net_packages_list', fallbacks: ['yemen_net_package_pay'], serviceId: id, defaultName: 'يمن نت - ADSL');
        return (id: id, name: name);
      }
    } else if (actionType == 'instant') {
      if (currentOpId == 'yemen_mobile') {
        final id = app.getServiceId('featmobile', fallbacks: ['yemen_mobile_denominations_list', 'yemen_mobile_instant_recharge', 'yemen_mobile_recharge'], defaultId: 2)!;
        final name = app.getServiceName('featmobile', fallbacks: ['yemen_mobile_denominations_list'], serviceId: id, defaultName: 'Yemen Mobile - فئات');
        return (id: id, name: name);
      } else if (currentOpId == 'sabafon') {
        final id = app.getServiceId('featsabafon', fallbacks: ['sabafon_north_denominations_list', 'sabafon_denominations', 'sabafon_instant_recharge'], defaultId: 8)!;
        final name = app.getServiceName('featsabafon', fallbacks: ['sabafon_north_denominations_list'], serviceId: id, defaultName: 'سبأفون - فئات');
        return (id: id, name: name);
      } else if (currentOpId == 'you') {
        final id = app.getServiceId('featyou', fallbacks: ['feat_you', 'you_denominations_list', 'you_denominations_recharge', 'you_instant_recharge_legacy'], defaultId: 14)!;
        final name = app.getServiceName('featyou', fallbacks: ['feat_you', 'you_denominations_list'], serviceId: id, defaultName: 'يو - فئات شحن');
        return (id: id, name: name);
      } else if (currentOpId == 'y') {
        final id = app.getServiceId('featway', fallbacks: ['feat_way', 'wai_denominations_list', 'wai_instant_recharge'], defaultId: 16)!;
        final name = app.getServiceName('featway', fallbacks: ['feat_way', 'wai_denominations_list'], serviceId: id, defaultName: 'واي - فئات');
        return (id: id, name: name);
      }
    } else if (actionType == 'balance') {
      if (currentOpId == 'yemen_mobile') {
        final id = app.getServiceId('yemen_mobile_recharge', defaultId: 1)!;
        final name = app.getServiceName('yemen_mobile_recharge', serviceId: id, defaultName: 'Yemen Mobile - رصيد');
        return (id: id, name: name);
      } else if (currentOpId == 'sabafon') {
        final id = app.getServiceId('sabafon_instant_recharge', fallbacks: ['sabafon_units_legacy', 'sabafon_north_units_pay'], defaultId: 12)!;
        final name = app.getServiceName('sabafon_instant_recharge', serviceId: id, defaultName: 'سبأفون - وحدات');
        return (id: id, name: name);
      } else if (currentOpId == 'you') {
        final id = app.getServiceId('you_instant_recharge_legacy', fallbacks: ['you_balance_recharge'], defaultId: 13)!;
        final name = app.getServiceName('you_instant_recharge_legacy', serviceId: id, defaultName: 'يو - رصيد مفتوح');
        return (id: id, name: name);
      } else if (currentOpId == 'y') {
        final id = app.getServiceId('wai_recharge', fallbacks: ['wai_instant_recharge'], defaultId: 17)!;
        final name = app.getServiceName('wai_recharge', serviceId: id, defaultName: 'واي - رصيد');
        return (id: id, name: name);
      } else if (currentOpId == 'yemen4g') {
        final id = app.getServiceId('yemen4g_recharge', fallbacks: ['yemen4g_balance'], defaultId: 20)!;
        final name = app.getServiceName('yemen4g_recharge', serviceId: id, defaultName: 'يمن فورجي - رصيد');
        return (id: id, name: name);
      }
    } else if (actionType == 'change_package') {
      final id = app.getServiceId('yemen4g_package_change', fallbacks: ['yem4g-change'], defaultId: 21)!;
      final name = app.getServiceName('yemen4g_package_change', serviceId: id, defaultName: 'يمن فورجي - تغيير باقة');
      return (id: id, name: name);
    } else if (actionType == 'net_adsl') {
      final id = app.getServiceId('yemen_net_package_pay', fallbacks: ['yemen_net_packages_list', 'post-adsl'], defaultId: 24)!;
      final name = app.getServiceName('yemen_net_package_pay', fallbacks: ['yemen_net_packages_list', 'post-adsl'], serviceId: id, defaultName: 'يمن نت - سداد ADSL');
      return (id: id, name: name);
    } else if (actionType == 'net_line') {
      final id = app.getServiceId('yemen_net_landline_pay', fallbacks: ['fixed_phone_service', 'post-line'], defaultId: 24)!;
      final name = app.getServiceName('yemen_net_landline_pay', serviceId: id, defaultName: 'يمن نت - خط');
      return (id: id, name: name);
    }

    final fallbackId = app.getServiceId(currentOpId, defaultId: 1)!;
    final fallbackName = app.getServiceName(currentOpId, serviceId: fallbackId, defaultName: '${currentOp.name} - خدمة سداد');
    return (id: fallbackId, name: fallbackName);
  }

  String _extractMinutes(String text) {
    final m = RegExp(r'(\d+)\s*(دقيقة|دقيقه|دقائق|د\b)').firstMatch(text);
    if (m != null) return '${m.group(1)} دقيقة';
    if (text.contains('مزايا ماكس')) return '400 دقيقة';
    if (text.contains('مزايا سوبر')) return '300 دقيقة';
    if (text.contains('مزايا أسبوعي') || text.contains('اسبوعي')) return '100 دقيقة';
    if (text.contains('مكالمات غير محدودة') || text.contains('بلا حدود')) return 'بلا حدود';
    return 'رصيد اتصال';
  }

  String _extractInternet(String text) {
    final gb = RegExp(r'(\d+(?:\.\d+)?)\s*(جيجا|جيجابايت|GB|G\b)', caseSensitive: false).firstMatch(text);
    if (gb != null) return '${gb.group(1)} جيجابايت';
    final mb = RegExp(r'(\d+)\s*(ميجا|ميجابايت|MB|M\b)', caseSensitive: false).firstMatch(text);
    if (mb != null) return '${mb.group(1)} ميجابايت';
    if (text.contains('نت بلا حدود') || text.contains('انترنت غير محدود')) return 'نت مفتوح';
    return 'بيانات انترنت';
  }

  String _extractSms(String text) {
    final s = RegExp(r'(\d+)\s*(رسالة|رسائل|رساله|SMS)', caseSensitive: false).firstMatch(text);
    if (s != null) return '${s.group(1)} رسالة';
    if (text.contains('مزايا الشهرية') || text.contains('مزايا الشهريه')) return '150 رسالة';
    if (text.contains('مزايا الاسبوعية') || text.contains('مزايا الأسبوعية')) return '30 رسالة';
    return 'رسائل';
  }

  String _extractDays(String text) {
    final d = RegExp(r'(\d+)\s*(يوم|ايام|أيام)').firstMatch(text);
    if (d != null) return '${d.group(1)} يوم';
    final h = RegExp(r'(\d+)\s*(ساعة|ساعه|ساعات)').firstMatch(text);
    if (h != null) return '${h.group(1)} ساعة';
    if (text.contains('شهر') || text.contains('الشهرية') || text.contains('شهرية')) return '30 يوم';
    if (text.contains('أسبوع') || text.contains('اسبوع') || text.contains('الاسبوعية')) return '7 أيام';
    if (text.contains('48 ساعة') || text.contains('48 ساعه')) return '2 يوم';
    if (text.contains('24 ساعة') || text.contains('24 ساعه') || text.contains('يومي') || text.contains('يومية')) return '1 يوم';
    return 'صلاحية الباقة';
  }

  List<int> _getOperatorTargetServiceIds(_OperatorSpec op, AppController app) {
    final ids = <int>{};
    switch (op.id) {
      case 'yemen_mobile':
        final s3 = app.getServiceId('bagatmobileget', defaultId: 3);
        final s4 = app.getServiceId('yemen_mobile_packages_list', defaultId: 4);
        if (s3 != null) ids.add(s3);
        if (s4 != null) ids.add(s4);
        ids.addAll([3, 4]);
        break;
      case 'sabafon':
        final s9 = app.getServiceId('bagatsabafonget', fallbacks: ['sabafon_packages_legacy'], defaultId: 9);
        final s8 = app.getServiceId('sabafon_north_packages_list', defaultId: 8);
        if (s9 != null) ids.add(s9);
        if (s8 != null) ids.add(s8);
        ids.addAll([9, 8]);
        break;
      case 'you':
        final s15 = app.getServiceId('bagatyouget', fallbacks: ['you_packages_list'], defaultId: 15);
        final s14 = app.getServiceId('featyou', defaultId: 14);
        if (s15 != null) ids.add(s15);
        if (s14 != null) ids.add(s14);
        ids.addAll([15, 14]);
        break;
      case 'y':
        final s18 = app.getServiceId('bagatwayget', fallbacks: ['wai_packages_list'], defaultId: 18);
        if (s18 != null) ids.add(s18);
        ids.add(18);
        break;
      case 'yemen4g':
        final s19 = app.getServiceId('yemen4g_packages_list', defaultId: 19);
        final s20 = app.getServiceId('yemen4g_packages_pay', defaultId: 20);
        if (s19 != null) ids.add(s19);
        if (s20 != null) ids.add(s20);
        ids.addAll([19, 20]);
        break;
      case 'yemen_net':
        final s23 = app.getServiceId('yemen_net_packages_list', defaultId: 23);
        final s24 = app.getServiceId('yemen_net_package_pay', defaultId: 24);
        if (s23 != null) ids.add(s23);
        if (s24 != null) ids.add(s24);
        ids.addAll([23, 24]);
        break;
    }
    return ids.toList();
  }

  String _resolveMainCategory(String opId, String text) {
    final lower = text.toLowerCase();
    switch (opId) {
      case 'yemen_mobile':
        if (lower.contains('volte') || text.contains('فولتي') || text.contains('فولت')) {
          return 'باقات فولتي VoLTE';
        }
        if (lower.contains('4g') || text.contains('فورجي') || text.contains('فور جي') || text.contains('4-جي')) {
          return 'باقات فورجي 4G';
        }
        if (text.contains('مزايا') || text.contains('ماكس') || text.contains('سوبر')) {
          return 'باقات مزايا';
        }
        if (text.contains('نت') || text.contains('انترنت') || text.contains('جيجا') || text.contains('ميجا') || lower.contains('evdo') || text.contains('مودم')) {
          return 'باقات الإنترنت';
        }
        if (text.contains('هدايا') || text.contains('توفير') || text.contains('سلفني') || text.contains('تواصل')) {
          return 'باقات هدايا وتوفير';
        }
        return 'باقات أخرى';

      case 'sabafon':
        if (lower.contains('4g') || text.contains('فورجي') || text.contains('فور جي')) {
          return 'باقات 4G سبأفون';
        }
        if (text.contains('يابلاش') || text.contains('يابالش') || text.contains('كلام') || text.contains('دقيقة') || text.contains('سوا')) {
          return 'باقات يابلاش ومكالمات';
        }
        if (text.contains('سوبرنت') || text.contains('نت') || text.contains('جيجا') || text.contains('ميجا')) {
          return 'باقات سوبرنت والإنترنت';
        }
        if (text.contains('واتساب') || text.contains('فيسبوك') || text.contains('تواصل')) {
          return 'باقات تواصل واجتماعية';
        }
        return 'باقات أخرى';

      case 'you':
        if (lower.contains('4g') || text.contains('فورجي') || text.contains('فور جي')) {
          return 'باقات فورجي 4G';
        }
        if (text.contains('مكس') || text.contains('توفير') || text.contains('سوبر')) {
          return 'باقات مكس وتوفير';
        }
        if (text.contains('سوى') || text.contains('سوا')) {
          return 'باقات سوى';
        }
        if (text.contains('مكالمات') || text.contains('دقيقة') || text.contains('رسائل') || text.contains('رسايل')) {
          return 'باقات مكالمات ورسائل';
        }
        if (text.contains('نت') || text.contains('انترنت') || text.contains('جيجا') || text.contains('فواصل')) {
          return 'باقات الإنترنت';
        }
        return 'باقات أخرى';

      case 'y':
        if (lower.contains('4g') || text.contains('فورجي')) {
          return 'باقات فورجي 4G';
        }
        if (text.contains('نت') || text.contains('جيجا')) {
          return 'باقات الإنترنت';
        }
        return 'باقات أخرى';

      case 'yemen4g':
        if (text.contains('شهر') || text.contains('30')) {
          return 'باقات يمن فورجي الشهرية';
        }
        return 'باقات يمن فورجي المتنوعة';

      case 'yemen_net':
        if (text.contains('فايبر') || lower.contains('ftth') || text.contains('الياف') || text.contains('ألياف')) {
          return 'باقات فايبر FTTH';
        }
        if (text.contains('سوبر') || text.contains('ذهبي') || text.contains('فضي')) {
          return 'باقات سوبر نت';
        }
        return 'باقات ADSL العادية';

      default:
        return 'باقات متنوعة';
    }
  }

  String _resolveSubCategory(String text) {
    final lower = text.toLowerCase();
    if (text.contains('فوتر') || text.contains('فوترة') || lower.contains('postpaid') || lower.contains('post_paid')) return 'فوترة';
    if (text.contains('دفع مسبق') || lower.contains('prepaid') || lower.contains('pre_paid')) return 'دفع مسبق';
    return _serverMobileBillingType({'mobileType': ymPhoneType}) ?? 'غير محدد';
  }

  String _buildSubTitle(Map<String, dynamic> it, Map<String, dynamic> meta, String text, _OperatorSpec op) {
    final sub = _resolveSubCategory(text);
    final medium = (text.contains('شريحة') || text.contains('شريحه'))
        ? 'شريحة'
        : (text.contains('برمجة') || text.contains('برمجه'))
            ? 'برمجة'
            : (op.id == 'yemen_mobile' ? 'شريحة + برمجة' : '');
    final parts = [sub];
    if (medium.isNotEmpty) parts.add(medium);
    final code = '${meta['provider_offer_code'] ?? meta['exact_api_code'] ?? it['code'] ?? ''}'.trim();
    if (code.isNotEmpty) parts.add('كود: $code');
    return parts.join(' | ');
  }

  Map<String, List<_PackageItem>> _getPackagesForOp(_OperatorSpec op, AppController app) {
    final sids = _getOperatorTargetServiceIds(op, app);
    final allItems = <Map<String, dynamic>>[];
    final seenItemIds = <dynamic>{};

    for (final sid in sids) {
      final cached = app.serviceDetailsCache[sid];
      if (cached == null) {
        app.loadServiceContract(sid);
      } else {
        if (cached['items'] is List) {
          for (final it in (cached['items'] as List).whereType<Map>()) {
            final rawId = it['id'];
            if (rawId != null && !seenItemIds.contains(rawId)) {
              seenItemIds.add(rawId);
              final mapCopy = Map<String, dynamic>.from(it);
              mapCopy['__resolvedServiceId'] = sid;
              allItems.add(mapCopy);
            }
          }
        }
      }
    }

    if (allItems.isNotEmpty) {
      final dynMap = <String, List<_PackageItem>>{};

      for (final it in allItems) {
        final id = int.tryParse('${it['id']}') ?? 0;
        final name = '${it['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        final pr = double.tryParse('${it['price'] ?? 0}') ?? 0;
        final meta = it['metadata'] is Map ? Map<String, dynamic>.from(it['metadata']) : <String, dynamic>{};
        final code = '${meta['provider_offer_code'] ?? meta['exact_api_code'] ?? meta['package_code'] ?? it['code'] ?? it['provider_offer_code'] ?? ''}'.trim();
        final desc = '${it['description'] ?? meta['description'] ?? ''}'.trim();
        final textCombined = '$name $desc ${it['category'] ?? ''}';

        final cat = _resolveMainCategory(op.id, textCombined);
        final subCat = _resolveSubCategory(textCombined);
        final subTitle = _buildSubTitle(it, meta, textCombined, op);

        final pkgItem = _PackageItem(
          id: id,
          name: name,
          category: cat,
          subTitle: subTitle,
          price: pr,
          days: _extractDays(textCombined),
          calls: _extractMinutes(textCombined),
          sms: _extractSms(textCombined),
          internet: _extractInternet(textCombined),
          code: code,
          serviceId: it['__resolvedServiceId'] as int? ?? (it['service'] is int ? it['service'] as int : sids.first),
          subCategory: subCat,
          description: desc,
          rawItem: it,
        );

        dynMap.putIfAbsent(cat, () => []).add(pkgItem);
      }

      // Sort categories logically: 4G / VoLTE first, Mazaya, Internet, then others
      final orderedMap = <String, List<_PackageItem>>{};
      final priority = [
        'باقات فورجي 4G',
        'باقات فولتي VoLTE',
        'باقات 4G سبأفون',
        'باقات مزايا',
        'باقات يابلاش ومكالمات',
        'باقات مكس وتوفير',
        'باقات سوى',
        'باقات الإنترنت',
        'باقات سوبرنت والإنترنت',
        'باقات فايبر FTTH',
        'باقات تواصل واجتماعية',
        'باقات هدايا وتوفير',
        'باقات أخرى',
      ];
      for (final p in priority) {
        if (dynMap.containsKey(p) && dynMap[p]!.isNotEmpty) {
          orderedMap[p] = dynMap[p]!;
        }
      }
      dynMap.forEach((k, v) {
        if (!orderedMap.containsKey(k) && v.isNotEmpty) {
          orderedMap[k] = v;
        }
      });

      if (orderedMap.isNotEmpty) {
        return orderedMap;
      }
    }

    final Map<String, List<_PackageItem>> base = op.id == 'yemen_mobile'
        ? yemenMobilePackages
        : op.id == 'sabafon'
            ? sabafonPackages
            : youPackages;
    return base;
  }

  // Pre-configured packages matching production
  final Map<String, List<_PackageItem>> yemenMobilePackages = const {
    'باقات مزايا': [
      _PackageItem(
        id: 101,
        name: 'مزايا الاسبوعية',
        category: 'باقات مزايا',
        subTitle: 'دفع مسبق\nشريحة + برمجة',
        price: 485,
        days: '7 أيام',
        calls: '100 دقيقة',
        sms: '30 رساله',
        internet: '90 ميجا',
        netDiscountPrice: 400.83,
      ),
      _PackageItem(
        id: 102,
        name: 'مزايا الشهريه - 350 دقيقه 150 رساله 250 ميجا',
        category: 'باقات مزايا',
        subTitle: 'دفع مسبق\nشريحة + برمجة',
        price: 1210,
        days: '30 يوم',
        calls: '350 دقيقة',
        sms: '150 رساله',
        internet: '250 ميجا',
        netDiscountPrice: 1000.0,
      ),
      _PackageItem(
        id: 103,
        name: 'مزايا الشهرية الكبرى 700 دقيقة',
        category: 'باقات مزايا',
        subTitle: 'دفع مسبق',
        price: 2420,
        days: '30 يوم',
        calls: '700 دقيقة',
        sms: '300 رساله',
        internet: '600 ميجا',
      ),
    ],
    'باقات فورجي': [
      _PackageItem(
        id: 201,
        name: 'باقة سوبر فورجي الشهرية دفع مسبق',
        category: 'باقات فورجي',
        subTitle: 'دفع مسبق\nشريحه',
        price: 2000,
        days: '30 يوم',
        calls: '250 دقيقة',
        sms: '250 رساله',
        internet: '2 جيجا',
        netDiscountPrice: 1652.0,
      ),
      _PackageItem(
        id: 202,
        name: 'باقة مزايا فورجي الشهرية 4 جيجا',
        category: 'باقات فورجي',
        subTitle: 'دفع مسبق\nشريحه',
        price: 2900,
        days: '30 يوم',
        calls: '400 دقيقة',
        sms: '400 رساله',
        internet: '4 جيجا',
      ),
      _PackageItem(
        id: 203,
        name: 'باقة تواصل فورجي الشهرية',
        category: 'باقات فورجي',
        subTitle: 'دفع مسبق\nشريحة',
        price: 1500,
        days: '30 يوم',
        calls: '600 دقيقة',
        sms: '600 رسالة',
        internet: 'لا يوجد',
      ),
    ],
    'باقات فولتي VoLTE': [
      _PackageItem(
        id: 301,
        name: 'باقة مزايا فولتي 48 ساعة',
        category: 'باقات فولتي VoLTE',
        subTitle: 'دفع مسبق',
        price: 600,
        days: '48 ساعة',
        calls: '120 دقيقة',
        sms: '50 رسالة',
        internet: '500 ميجا',
      ),
      _PackageItem(
        id: 302,
        name: 'باقة مزايا فولتي الشهرية',
        category: 'باقات فولتي VoLTE',
        subTitle: 'دفع مسبق',
        price: 1800,
        days: '30 يوم',
        calls: '300 دقيقة',
        sms: '200 رسالة',
        internet: '1.5 جيجا',
      ),
    ],
    'باقات الإنترنت الشهرية': [
      _PackageItem(
        id: 401,
        name: 'باقة 3 جيجا إنترنت شهرية',
        category: 'باقات الإنترنت الشهرية',
        subTitle: 'دفع مسبق',
        price: 2400,
        days: '30 يوم',
        calls: '-',
        sms: '-',
        internet: '3 جيجا',
      ),
    ],
    'باقات الإنترنت 10 ايام': [
      _PackageItem(
        id: 501,
        name: 'باقة 1 جيجا 10 أيام',
        category: 'باقات الإنترنت 10 ايام',
        subTitle: 'دفع مسبق',
        price: 900,
        days: '10 أيام',
        calls: '-',
        sms: '-',
        internet: '1 جيجا',
      ),
    ],
  };

  final Map<String, List<_PackageItem>> sabafonPackages = const {
    'باقات يابلاش + واحد': [
      _PackageItem(
        id: 601,
        name: 'يابلاش الاسبوعية',
        category: 'باقات يابلاش + واحد',
        subTitle: 'دفع مسبق',
        price: 484,
        days: '7 أيام',
        calls: '100 دقيقة',
        sms: '100 رسالة',
        internet: '100 ميجا',
      ),
      _PackageItem(
        id: 602,
        name: 'يابلاش الشهرية',
        category: 'باقات يابلاش + واحد',
        subTitle: 'دفع مسبق',
        price: 1210,
        days: '30 يوم',
        calls: '300 دقيقة',
        sms: '300 رسالة',
        internet: '100 ميجا',
      ),
    ],
    'باقات 4G-فورجي': [
      _PackageItem(
        id: 603,
        name: 'سبأفون 4G سوبر 6 جيجا',
        category: 'باقات 4G-فورجي',
        subTitle: 'دفع مسبق فورجي',
        price: 3000,
        days: '30 يوم',
        calls: '200 دقيقة',
        sms: '200 رسالة',
        internet: '6 جيجا',
      ),
    ],
  };

  final Map<String, List<_PackageItem>> youPackages = const {
    'باقات سوى': [
      _PackageItem(
        id: 701,
        name: 'سوا 250 دقيقة 300 رسالة الشهرية',
        category: 'باقات سوى',
        subTitle: 'دفع مسبق',
        price: 1815,
        days: '30 يوم',
        calls: '250 دقيقة',
        sms: '300 رسالة',
        internet: '1 جيجا',
      ),
      _PackageItem(
        id: 702,
        name: 'باقة سوا 73 - الاسبوعية',
        category: 'باقات سوى',
        subTitle: 'دفع مسبق',
        price: 500,
        days: '7 أيام',
        calls: '73 دقيقة',
        sms: '73 رسالة',
        internet: '150 ميجا',
      ),
    ],
  };

  // Denominations for Instant Recharge (فوري)
  final List<_DenominationItem> yemenMobileDenominations = const [
    _DenominationItem(tier: 200, price: 242, days: '8 أيام'),
    _DenominationItem(tier: 400, price: 484, days: '16 يوم'),
    _DenominationItem(tier: 600, price: 726, days: '24 يوم'),
    _DenominationItem(tier: 800, price: 968, days: '32 يوم'),
    _DenominationItem(tier: 1000, price: 1210, days: '40 يوم'),
    _DenominationItem(tier: 1200, price: 1452, days: '48 يوم'),
    _DenominationItem(tier: 2200, price: 2662, days: '88 يوم'),
  ];

  final List<_DenominationItem> sabafonDenominations = const [
    _DenominationItem(tier: 22, price: 273, days: '5 أيام'),
    _DenominationItem(tier: 40, price: 484, days: '8 أيام'),
    _DenominationItem(tier: 45, price: 545, days: '8 أيام'),
    _DenominationItem(tier: 60, price: 726, days: '14 يوم'),
    _DenominationItem(tier: 85, price: 1029, days: '40 يوم'),
    _DenominationItem(tier: 100, price: 1210, days: '50 يوم'),
    _DenominationItem(tier: 125, price: 1513, days: '60 يوم'),
    _DenominationItem(tier: 150, price: 1815, days: '60 يوم'),
    _DenominationItem(tier: 209, price: 2529, days: '180 يوم'),
  ];

  final List<_DenominationItem> youDenominations = const [
    _DenominationItem(tier: 410, price: 496, days: '7 أيام'),
    _DenominationItem(tier: 830, price: 1004, days: '30 يوم'),
    _DenominationItem(tier: 1000, price: 1210, days: '30 يوم'),
    _DenominationItem(tier: 1250, price: 1513, days: '40 يوم'),
    _DenominationItem(tier: 2500, price: 3025, days: '60 يوم'),
    _DenominationItem(tier: 5000, price: 6050, days: '90 يوم'),
    _DenominationItem(tier: 7500, price: 9075, days: '90 يوم'),
  ];

  final List<_DenominationItem> yDenominations = const [
    _DenominationItem(tier: 200, price: 242, days: '7 أيام'),
    _DenominationItem(tier: 400, price: 484, days: '15 يوم'),
    _DenominationItem(tier: 800, price: 968, days: '30 يوم'),
    _DenominationItem(tier: 1200, price: 1452, days: '45 يوم'),
  ];

  final List<Map<String, dynamic>> fourGDenominations = const [
    {'label': 'باقة G 15', 'price': 2400.0},
    {'label': 'باقة G 25', 'price': 4000.0},
    {'label': 'باقة G 60', 'price': 8000.0},
    {'label': 'باقة G 130', 'price': 16000.0},
    {'label': 'باقة G 250', 'price': 26000.0},
    {'label': 'باقة G 500', 'price': 46000.0},
  ];

  final List<Map<String, dynamic>> yemenNetDenominations = const [
    {'label': '10G 1M', 'price': 1575.0},
    {'label': '24G 1M', 'price': 3150.0},
    {'label': '24G 2M', 'price': 2520.0},
    {'label': '50G 2M', 'price': 4725.0},
    {'label': '66G 4M', 'price': 6930.0},
    {'label': '100G 1M', 'price': 10500.0},
  ];

  @override
  void initState() {
    super.initState();
    _handlePhoneChange(phone.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = Provider.of<AppController>(context, listen: false);
      // Pre-load all operator package services so data is instantly available
      app.loadServiceContract(3);
      app.loadServiceContract(4);
      app.loadServiceContract(9);
      app.loadServiceContract(15);
      app.loadServiceContract(19);
      app.loadServiceContract(23);
      if (currentOpId == 'yemen_mobile' && activeMainTab == 'باقات') {
        _runInquiry('offers', quiet: true);
      }
    });
  }

  @override
  void dispose() {
    _offersInquiryDebounce?.cancel();
    phoneFocusNode.dispose();
    phone.dispose();
    rechargeAmount.dispose();
    unitsCount.dispose();
    super.dispose();
  }

  Future<void> _pickContactFromDevice() async {
    try {
      final result = await _nativeChannel.invokeMethod<dynamic>('pickContact');
      if (result != null && result is Map) {
        final rawPhone = '${result['phone'] ?? ''}';
        String cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
        if (cleaned.startsWith('967') && cleaned.length > 9) {
          cleaned = cleaned.substring(3);
        } else if (cleaned.startsWith('00967') && cleaned.length > 9) {
          cleaned = cleaned.substring(5);
        } else if (cleaned.startsWith('0') && cleaned.length == 10) {
          cleaned = cleaned.substring(1);
        }
        if (cleaned.length > 9) {
          cleaned = cleaned.substring(cleaned.length - 9);
        }

        if (cleaned.isNotEmpty) {
          setState(() {
            phone.text = cleaned;
          });
          _handlePhoneChange(cleaned);
          if (mounted) {
            final contactName = result['name']?.toString() ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(contactName.isNotEmpty
                    ? 'تم اختيار الرقم من جهات الاتصال: $cleaned ($contactName)'
                    : 'تم اختيار الرقم من جهات الاتصال: $cleaned'),
                backgroundColor: AppColors.emerald,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      final uPhone = context.read<AppController>().user?.phone;
      if (uPhone != null && uPhone.isNotEmpty) {
        setState(() {
          phone.text = uPhone;
        });
        _handlePhoneChange(uPhone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد رقم حسابك: $uPhone')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى كتابة رقم الهاتف المطلوب أو منح الإذن لجهات الاتصال')),
        );
      }
    }
  }

  Future<void> _syncTelecomPackages() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final app = context.read<AppController>();
    try {
      await app.syncTelecomData(force: true);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت مزامنة الباقات والخدمات مع الخادم بنجاح'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر مزامنة الباقات: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _handlePhoneChange(String val) {
    final clean = val.replaceAll(RegExp(r'\D'), '');
    String? matchedOpId;
    if (clean.startsWith('77') || clean.startsWith('78')) {
      matchedOpId = 'yemen_mobile';
    } else if (clean.startsWith('71') || clean.startsWith('70')) {
      matchedOpId = 'sabafon';
    } else if (clean.startsWith('73')) {
      matchedOpId = 'you';
    } else if (clean.startsWith('79')) {
      matchedOpId = 'y';
    } else if (clean.startsWith('10')) {
      matchedOpId = 'yemen4g';
    } else if (clean.startsWith('01') || clean.startsWith('02') || clean.startsWith('03') || clean.startsWith('04')) {
      matchedOpId = 'yemen_net';
    }

    final previousOpId = currentOpId;
    final keepPhoneFocus = phoneFocusNode.hasFocus;
    if (matchedOpId != null) {
      final op = operators.firstWhere((o) => o.id == matchedOpId);
      if (matchedOpId != currentOpId) {
        setState(() {
          currentOpId = matchedOpId!;
          activeMainTab = op.mainTabs.contains('باقات') ? 'باقات' : op.mainTabs.first;
          billingFilter = 'الكل';
          packageKindFilter = 'شريحة';
          operatorRestrictedToast = null;
          balanceInquiryBanner = null;
          activeSubscriptions = [];
          ymPhoneBalance = '---';
          ymPhoneType = '---';
          ymLoanStatus = 'unknown';
          ymLoanAmount = 0;
          fourGInquiryData = null;
          netInquiryData = null;
        });
        if (keepPhoneFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && phoneFocusNode.canRequestFocus) phoneFocusNode.requestFocus();
          });
        }
      } else {
        setState(() {});
      }
    } else {
      _offersInquiryDebounce?.cancel();
      if (previousOpId.isNotEmpty || activeMainTab.isNotEmpty || operatorRestrictedToast != null) {
        setState(() {
          currentOpId = '';
          activeMainTab = '';
          billingFilter = 'الكل';
          packageKindFilter = 'الكل';
          operatorRestrictedToast = null;
          balanceInquiryBanner = null;
          activeSubscriptions = [];
          ymPhoneBalance = '---';
          ymPhoneType = '---';
          ymLoanStatus = 'unknown';
          ymLoanAmount = 0;
          fourGInquiryData = null;
          netInquiryData = null;
        });
        if (keepPhoneFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && phoneFocusNode.canRequestFocus) phoneFocusNode.requestFocus();
          });
        }
      } else {
        setState(() {});
      }
    }

    if (currentOpId == 'yemen_mobile' &&
        activeMainTab == 'باقات' &&
        clean.length == 9 &&
        (clean.startsWith('77') || clean.startsWith('78'))) {
      if (_lastOffersInquiryPhone == clean) return;
      _offersInquiryDebounce?.cancel();
      _offersInquiryDebounce = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || phone.text.replaceAll(RegExp(r'\D'), '') != clean) return;
        _lastOffersInquiryPhone = clean;
        _runInquiry('offers', quiet: false);
      });
    } else {
      _offersInquiryDebounce?.cancel();
      if (clean.length < 9 || clean != _lastOffersInquiryPhone) {
        _lastOffersInquiryPhone = null;
      }
    }
  }

  void _selectOperator(_OperatorSpec op) {
    setState(() {
      currentOpId = op.id;
      if (!op.mainTabs.contains(activeMainTab)) {
        activeMainTab = op.mainTabs.first;
      }
      balanceInquiryBanner = null;
    });
    if (currentOpId == 'yemen_mobile' && activeMainTab == 'باقات') {
      _lastOffersInquiryPhone = null;
      if (phone.text.replaceAll(RegExp(r'\D'), '').length == 9) {
        _runInquiry('offers', quiet: false);
      } else {
        _showInquiryNotice('أدخل رقم يمن موبايل كاملًا ليتم استعلام الباقات من الخادم.');
      }
    }
  }
  void _selectMainTab(String t) {
    setState(() => activeMainTab = t);
    balanceInquiryBanner = null;
    if (currentOpId == 'yemen_mobile' && t == 'باقات') {
      _lastOffersInquiryPhone = null;
      if (phone.text.replaceAll(RegExp(r'\D'), '').length == 9) {
        _runInquiry('offers', quiet: false);
      } else {
        _showInquiryNotice('أدخل رقم يمن موبايل كاملًا ليتم استعلام الباقات من الخادم.');
      }
    }
  }
  String _transactionStatus(Map<String, dynamic> tx) =>
      '${tx['status'] ?? ''}'.trim().toLowerCase();

  bool _isTransactionSuccess(Map<String, dynamic> tx) =>
      const {'success', 'completed', 'done', 'executed'}.contains(_transactionStatus(tx));

  bool _isTransactionFailure(Map<String, dynamic> tx) =>
      const {'failed', 'error', 'rejected', 'refunded'}.contains(_transactionStatus(tx));

  bool _isTransactionPending(Map<String, dynamic> tx) =>
      const {'accepted', 'queued', 'pending', 'pending_provider', 'processing', 'manual_review'}.contains(_transactionStatus(tx)) ||
      tx['_client_wait_timed_out'] == true;

  String _transactionMessage(Map<String, dynamic> tx) =>
      '${tx['error_message'] ?? tx['message'] ?? tx['detail'] ?? tx['error'] ?? ''}'.trim();

  String? _serverMobileBillingType(Map<String, dynamic> data) {
    final raw = data['mobileType'] ??
        data['mobile_type'] ??
        data['mobileTypeName'] ??
        data['mobile_type_name'] ??
        data['subscriber_type'] ??
        data['billing_type'];
    final value = '${raw ?? ''}'.trim().toLowerCase();
    if (value.isEmpty) return null;
    if (const {'1', 'prepaid', 'pre_paid', 'pre paid', 'pre-paid'}.contains(value) ||
        value.contains('دفع مسبق') ||
        value.contains('مسبق')) {
      return 'دفع مسبق';
    }
    if (const {'2', 'postpaid', 'post_paid', 'post paid', 'post-paid', 'billing'}.contains(value) ||
        value.contains('فوترة') ||
        value.contains('فوتر')) {
      return 'فوترة';
    }
    return null;
  }

  double _serverLoanAmount(Map<String, dynamic> data) {
    for (final key in const [
      'loan_amount', 'loanAmount', 'loan_balance', 'loanBalance',
      'sulfa_amount', 'sulfaAmount', 'loan_due', 'loanDue',
    ]) {
      if (data.containsKey(key) && data[key] != null) {
        final value = double.tryParse('${data[key]}'.trim());
        if (value != null && value >= 0) return value;
      }
    }
    return 0;
  }

  bool? _serverHasLoan(Map<String, dynamic> data) {
    for (final key in const [
      'loan', 'has_loan', 'hasLoan', 'is_loan', 'isLoan',
      'sulfa', 'has_sulfa', 'hasSulfa', 'loan_status',
    ]) {
      if (!data.containsKey(key) || data[key] == null) continue;
      final raw = data[key];
      if (raw is bool) return raw;
      final value = '$raw'.trim().toLowerCase();
      if (const {'1', 'true', 'yes', 'yes loan', 'loan', 'متسلف', 'نعم'}.contains(value)) return true;
      if (const {'0', 'false', 'no', 'none', 'no loan', 'غير متسلف', 'لا'}.contains(value)) return false;
      if (value.contains('متسلف') && !value.contains('غير متسلف')) return true;
      if (value.contains('غير متسلف')) return false;
    }
    final amountKeys = const [
      'loan_amount', 'loanAmount', 'loan_balance', 'loanBalance',
      'sulfa_amount', 'sulfaAmount', 'loan_due', 'loanDue',
    ];
    if (amountKeys.any(data.containsKey)) return _serverLoanAmount(data) > 0;
    return null;
  }

  String _phoneInquiryTypeLabel(Map<String, dynamic> result) {
    final billing = _serverMobileBillingType(result);
    if (billing == 'فوترة') return 'فوترة | شريحة';
    if (billing == 'دفع مسبق') return 'دفع مسبق | شريحة';
    return 'نوع الشريحة غير محدد من الخادم';
  }

  void _showInquiryNotice(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() => operatorRestrictedToast = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.burgundy,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _runInquiry(String type, {bool quiet = false}) async {
    final currentPhone = phone.text.trim();
    final normalizedPhone = currentPhone.replaceAll(RegExp(r'\D'), '');
    if (currentPhone.isEmpty ||
        normalizedPhone.length < 7 ||
        (currentOpId == 'yemen_mobile' && normalizedPhone.length != 9)) {
      if (!quiet) {
        _showInquiryNotice(
          currentOpId == 'yemen_mobile'
              ? 'أدخل رقم يمن موبايل كاملًا (9 أرقام) قبل الاستعلام.'
              : 'أدخل رقم الهاتف أو الحساب كاملًا قبل الاستعلام.',
          isError: true,
        );
      }
      return;
    }

    final loadingDialogShown = !quiet;
    if (loadingDialogShown) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.burgundy),
              SizedBox(width: 16),
              Expanded(child: Text('جاري الاستعلام من الخادم وانتظار رد المشغل...', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      );
    }

    try {
      final app = Provider.of<AppController>(context, listen: false);
      if (mounted) {
        setState(() {
          operatorRestrictedToast = null;
          if (type == 'balance') {
            balanceInquiryBanner = null;
            if (currentOpId == 'yemen_mobile') {
              ymPhoneBalance = '---';
              ymPhoneType = '---';
            }
          }
          if (type == 'offers') {
            // Clear number-specific results while a new number is being queried;
            // do not show a previous subscriber's offers as though they were current.
            activeSubscriptions = [];
            ymPhoneBalance = '---';
            ymPhoneType = '---';
            ymLoanStatus = 'none';
            ymLoanAmount = 0;
          }
        });
      }

      if (currentOpId == 'yemen_mobile' && type == 'balance') {
        final tx = await app.api.queryYemenMobileBalance(normalizedPhone);
        if (!_isTransactionSuccess(tx)) {
          if (_isTransactionPending(tx)) {
            _showInquiryNotice('تم إرسال استعلام الرصيد إلى الخادم، وما زلنا ننتظر الرد. أعد الفحص بعد قليل.');
            return;
          }
          throw Exception(_transactionMessage(tx).isNotEmpty ? _transactionMessage(tx) : 'لم يؤكد الخادم نجاح استعلام الرصيد.');
        }
        final rawResult = tx['result'];
        if (rawResult is! Map || rawResult.isEmpty) throw Exception('اكتمل الطلب دون تفاصيل رصيد قابلة للعرض من الخادم.');
        final res = Map<String, dynamic>.from(rawResult);
        final balance = '${res['balance'] ?? ''}'.trim();
        if (balance.isEmpty) throw Exception('لم يتضمن رد الخادم قيمة رصيد الهاتف.');
        final billing = _serverMobileBillingType(res);
        final mobileType = _phoneInquiryTypeLabel(res);
        final loanAmount = _serverLoanAmount(res);
        final hasLoan = _serverHasLoan(res);
        try { unawaited(app.refreshWalletAndReports().catchError((_) {})); } catch (_) {}
        if (mounted) {
          setState(() {
            ymPhoneBalance = '$balance ر.ي';
            ymPhoneType = mobileType;
            ymLoanAmount = loanAmount;
            ymLoanStatus = hasLoan == null ? 'unknown' : (hasLoan ? 'loan' : 'none');
            if (billing != null) billingFilter = billing;
            final loanText = hasLoan == true
                ? '$loanAmount ر.ي'
                : hasLoan == false
                    ? 'لا توجد سلفة'
                    : 'غير مفحوصة';
            balanceInquiryBanner = 'رصيد الهاتف: $balance ر.ي • $mobileType • السلفة: $loanText';
          });
        }
      } else if (currentOpId == 'yemen_mobile' && type == 'offers') {
        final tx = await app.api.queryYemenMobileOffers(normalizedPhone);
        if (!_isTransactionSuccess(tx)) {
          if (_isTransactionPending(tx)) {
            _showInquiryNotice('تم إرسال استعلام باقات يمن موبايل إلى الخادم، وما زلنا ننتظر النتيجة. لا تكرر الاستعلام الآن.');
            return;
          }
          throw Exception(_transactionMessage(tx).isNotEmpty ? _transactionMessage(tx) : 'لم يؤكد الخادم نجاح استعلام الباقات.');
        }
        final rawResult = tx['result'];
        if (rawResult is! Map || rawResult.isEmpty) throw Exception('لم يرجع الخادم تفاصيل باقات قابلة للعرض.');
        final res = Map<String, dynamic>.from(rawResult);

        String? liveBalance = '${res['balance'] ?? ''}'.trim();
        // Offers responses can omit subscriber type and loan details; use the dedicated balance inquiry.
        final missingBilling = _serverMobileBillingType(res) == null;
        final missingLoan = _serverHasLoan(res) == null;
        if (liveBalance.isEmpty || missingBilling || missingLoan) {
          try {
            final balanceTx = await app.api.queryYemenMobileBalance(normalizedPhone);
            if (_isTransactionSuccess(balanceTx) && balanceTx['result'] is Map) {
              final balanceResult = Map<String, dynamic>.from(balanceTx['result'] as Map);
              for (final key in const [
                'balance', 'mobileType', 'mobile_type', 'mobileTypeName',
                'mobile_type_name', 'subscriber_type', 'billing_type',
                'loan', 'has_loan', 'hasLoan', 'is_loan', 'isLoan',
                'sulfa', 'has_sulfa', 'hasSulfa', 'loan_status',
                'loan_amount', 'loanAmount', 'loan_balance', 'loanBalance',
                'sulfa_amount', 'sulfaAmount', 'loan_due', 'loanDue',
              ]) {
                final current = res[key];
                if (current == null || '$current'.trim().isEmpty) {
                  if (balanceResult.containsKey(key) && balanceResult[key] != null) {
                    res[key] = balanceResult[key];
                  }
                }
              }
              final fetchedBalance = '${balanceResult['balance'] ?? ''}'.trim();
              if ((liveBalance == null || liveBalance!.isEmpty) && fetchedBalance.isNotEmpty) {
                liveBalance = fetchedBalance;
              }
            }
          } catch (_) {
            // Keep the type/loan unknown if the secondary inquiry fails.
          }
        }

        final subscriptions = <_ActiveSubItem>[];
        final rawOffers = res['offers'];
        if (rawOffers is List) {
          for (final item in rawOffers.whereType<Map>()) {
            final offer = Map<String, dynamic>.from(item);
            final offerName = '${offer['offerName'] ?? offer['name'] ?? 'اشتراك نشط'}';
            subscriptions.add(_ActiveSubItem(
              id: '${offer['offerId'] ?? offer['id'] ?? 'sub-$offerName'}',
              name: offerName,
              startDate: '${offer['offerStartDate'] ?? offer['startDate'] ?? ''}',
              endDate: '${offer['offerEndDate'] ?? offer['endDate'] ?? ''}',
              type: offerName.contains('4G') ? '4G' : 'باقة',
            ));
          }
        }

        final loanAmount = _serverLoanAmount(res);
        final hasLoan = _serverHasLoan(res);
        final billing = _serverMobileBillingType(res);
        final mobileType = _phoneInquiryTypeLabel(res);
        if (mounted) {
          setState(() {
            activeSubscriptions = subscriptions;
            ymLoanStatus = hasLoan == null ? 'unknown' : (hasLoan ? 'loan' : 'none');
            ymLoanAmount = loanAmount;
            ymPhoneType = mobileType;
            if (billing != null) billingFilter = billing;
            if (liveBalance != null && liveBalance!.isNotEmpty) ymPhoneBalance = '$liveBalance ر.ي';
          });
        }
        if (rawOffers is! List) {
          _showInquiryNotice('وصل رد الخادم، لكنه لم يتضمن قائمة الباقات المتوقعة. تحقق من إعدادات خدمة الباقات.', isError: true);
        }
      } else if (currentOpId == 'yemen4g') {
        final tx = await app.api.queryYemen4g(normalizedPhone);
        if (!_isTransactionSuccess(tx)) {
          if (_isTransactionPending(tx)) {
            _showInquiryNotice('تم إرسال استعلام يمن فورجي إلى الخادم، وما زلنا ننتظر الرد.');
            return;
          }
          throw Exception(_transactionMessage(tx).isNotEmpty ? _transactionMessage(tx) : 'تعذر تأكيد استعلام يمن فورجي من الخادم.');
        }
        final rawResult = tx['result'];
        if (rawResult is! Map || rawResult.isEmpty) throw Exception('لم يرجع الخادم تفاصيل يمن فورجي.');
        final res = Map<String, dynamic>.from(rawResult);
        if (mounted) {
          setState(() {
            fourGInquiryData = {
              'balance': '${res['avblnce'] ?? res['balance'] ?? 'غير متوفر من الخادم'}',
              'packagePrice': res['baga_amount'] == null ? 'غير متوفر من الخادم' : '${res['baga_amount']} ر.ي (أقل مبلغ سداد: ${res['minamtobill'] ?? res['baga_amount']})',
              'speed': '${res['size'] ?? ''}${res['speed'] == null ? '' : ' سرعة: ${res['speed']}'}'.trim(),
              'expiry': '${res['expdate'] ?? 'غير متوفر من الخادم'}',
            };
          });
        }
      } else if (currentOpId == 'yemen_net') {
        final typeParam = netTab == 'phone' ? 'phone' : 'adsl';
        final tx = await app.api.queryYemenNet(normalizedPhone, type: typeParam);
        if (!_isTransactionSuccess(tx)) {
          if (_isTransactionPending(tx)) {
            _showInquiryNotice('تم إرسال استعلام يمن نت إلى الخادم، وما زلنا ننتظر الرد.');
            return;
          }
          throw Exception(_transactionMessage(tx).isNotEmpty ? _transactionMessage(tx) : 'تعذر تأكيد استعلام يمن نت من الخادم.');
        }
        final rawResult = tx['result'];
        if (rawResult is! Map || rawResult.isEmpty) throw Exception('لم يرجع الخادم تفاصيل يمن نت.');
        final res = Map<String, dynamic>.from(rawResult);
        if (mounted) {
          setState(() {
            netInquiryData = {
              'balance': '${res['balance'] ?? 'غير متوفر من الخادم'}',
              'packagePrice': '${res['package_price'] ?? 'غير متوفر من الخادم'}',
              'speed': '${res['speed'] ?? 'غير متوفر من الخادم'}',
              'expiry': '${res['expiry'] ?? 'غير متوفر من الخادم'}',
            };
          });
        }
      } else if (type == 'sulfa') {
        // The live balance inquiry is the source of truth for loan status and amount.
        final tx = await app.api.queryYemenMobileBalance(normalizedPhone);
        if (!_isTransactionSuccess(tx)) {
          if (_isTransactionPending(tx)) {
            _showInquiryNotice('تم إرسال فحص السلفة إلى الخادم، وما زلنا ننتظر الرد.');
            return;
          }
          throw Exception(_transactionMessage(tx).isNotEmpty ? _transactionMessage(tx) : 'تعذر تأكيد فحص السلفة من الخادم.');
        }
        final rawResult = tx['result'];
        if (rawResult is! Map) throw Exception('لم يرجع الخادم تفاصيل السلفة.');
        final res = Map<String, dynamic>.from(rawResult);
        final loanAmount = _serverLoanAmount(res);
        final hasLoan = _serverHasLoan(res);
        final billing = _serverMobileBillingType(res);
        if (mounted) {
          setState(() {
            ymLoanAmount = loanAmount;
            ymLoanStatus = hasLoan == null ? 'unknown' : (hasLoan ? 'loan' : 'none');
            ymPhoneType = _phoneInquiryTypeLabel(res);
            if (billing != null) billingFilter = billing;
            final balance = '${res['balance'] ?? ''}'.trim();
            if (balance.isNotEmpty) ymPhoneBalance = '$balance ر.ي';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        final message = 'تعذر الاستعلام من الخادم: ${error.toString().replaceFirst('Exception: ', '')}';
        setState(() {
          operatorRestrictedToast = message;
          if (type == 'balance') balanceInquiryBanner = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red.shade700, duration: const Duration(seconds: 6)),
        );
      }
    } finally {
      if (loadingDialogShown && mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }


  String _getArabicAmountWords(double num) {
    final int val = num.toInt();
    if (val == 0) return 'صفر ريال';
    if (val == 600) return 'ستمائة ريال';
    if (val == 485) return 'أربعمائة وخمسة وثمانون ريالاً';
    if (val == 1210) return 'ألف ومائتان وعشرة ريالات';
    if (val == 2420) return 'ألفان وأربعمائة وعشرون ريالاً';
    if (val == 2000) return 'ألفان ريال';
    if (val == 2900) return 'ألفان وتسعمائة ريال';
    if (val == 1500) return 'ألف وخمسمائة ريال';
    if (val == 1800) return 'ألف وثمانمائة ريال';
    if (val == 2400) return 'ألفان وأربعمائة ريال';
    if (val == 900) return 'تسعمائة ريال';
    if (val == 484) return 'أربعمائة وأربعة وثمانون ريالاً';
    if (val == 3000) return 'ثلاثة آلاف ريال';
    if (val == 1815) return 'ألف وثمانمائة وخمسة عشر ريالاً';
    if (val == 500) return 'خمسمائة ريال';

    final ones = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'];
    final tens = ['', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
    final hundreds = ['', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'];

    if (val < 20) return '${ones[val]} ريال';
    if (val < 100) {
      final o = val % 10;
      final t = val ~/ 10;
      return o == 0 ? '${tens[t]} ريال' : '${ones[o]} و${tens[t]} ريال';
    }
    if (val < 1000) {
      final h = val ~/ 100;
      final rem = val % 100;
      if (rem == 0) return '${hundreds[h]} ريال';
      return '${hundreds[h]} و${_getArabicAmountWords(rem.toDouble())}';
    }
    if (val < 1000000) {
      final th = val ~/ 1000;
      final rem = val % 1000;
      String thWord = th == 1 ? 'ألف' : (th == 2 ? 'ألفان' : (th <= 10 ? '${ones[th]} آلاف' : '${_getArabicAmountWords(th.toDouble()).replaceAll(' ريال', '')} ألف'));
      if (rem == 0) return '$thWord ريال';
      return '$thWord و${_getArabicAmountWords(rem.toDouble())}';
    }
    return '$val ريال يمني';
  }


  bool _serverSupportsLoanAddition(_PackageItem pkg, AppController app) {
    final serviceId = pkg.serviceId > 0
        ? pkg.serviceId
        : _resolveServiceForCurrentAction(actionType: 'packages', appInstance: app).id;
    final contract = app.serviceDetailsCache[serviceId];
    if (contract == null || '${contract['pricing_mode'] ?? ''}'.toLowerCase() != 'amount') return false;
    final fields = contract['fields'];
    if (fields is! List) return false;
    const loanKeys = {
      'loan', 'has_loan', 'hasloan', 'repay_loan', 'repayloan',
      'include_loan', 'includeloan', 'pay_loan', 'settle_loan',
      'loan_amount', 'loanamount', 'sulfa_amount', 'sulfaamount',
    };
    final keys = fields.whereType<Map>()
        .map((field) => '${field['key'] ?? ''}'.trim().toLowerCase().replaceAll('-', '_'))
        .toSet();
    final hasAmountField = keys.any((key) => const {'amount', 'value', 'payment_amount'}.contains(key));
    final hasLoanField = keys.any((key) => loanKeys.contains(key));
    return hasAmountField && hasLoanField;
  }

  Future<void> _submitYemenMobileBalanceForPackage(_PackageItem pkg, BuildContext sheetContext) async {
    final app = context.read<AppController>();
    final serviceId = app.getServiceId('yemen_mobile_recharge', defaultId: 1) ?? 1;
    Map<String, dynamic>? contract;
    try {
      contract = await app.loadServiceContract(serviceId, force: true);
    } catch (_) {}
    if (!mounted) return;
    final pricingMode = '${contract?['pricing_mode'] ?? ''}'.trim().toLowerCase();
    final kind = '${contract?['service_kind'] ?? ''}'.trim().toLowerCase();
    if (contract == null || pricingMode != 'amount' || (kind.isNotEmpty && kind != 'purchase')) {
      Navigator.of(sheetContext).pop();
      _showInquiryNotice('خدمة «تسديد الرصيد» غير مهيأة كخدمة مبلغ قابل للإدخال في الخادم؛ لم يتم إرسال أي طلب.', isError: true);
      return;
    }
    final serviceName = '${contract['name'] ?? app.getServiceName('yemen_mobile_recharge', serviceId: serviceId, defaultName: 'تسديد رصيد يمن موبايل')}';
    Navigator.of(sheetContext).pop();
    _openConfirmPaymentDialog(
      itemName: 'تسديد رصيد يمن موبايل',
      amount: pkg.price,
      serviceId: serviceId,
      serviceName: serviceName,
    );
  }

  Future<void> _submitYemenMobileActivationOnly(_PackageItem pkg, BuildContext sheetContext) async {
    final app = context.read<AppController>();
    final serviceId = app.getServiceId(
      'yemen_mobile_package_activate_only',
      fallbacks: ['yemen_mobile_activate_package', 'yemen_mobile_packages_activate_only'],
    );
    if (serviceId == null || serviceId <= 0) {
      Navigator.of(sheetContext).pop();
      _showInquiryNotice('خدمة «تفعيل فقط» غير مرتبطة بخدمة مستقلة في إعدادات الخادم. لم يتم إرسال أي طلب لتجنب تنفيذ تسديد + تفعيل بدلًا منها.', isError: true);
      return;
    }

    Map<String, dynamic>? contract;
    try {
      contract = await app.loadServiceContract(serviceId, force: true);
    } catch (_) {}
    if (!mounted) return;
    final items = contract?['items'];
    if (contract == null || items is! List) {
      Navigator.of(sheetContext).pop();
      _showInquiryNotice('تعذر تحميل كتالوج خدمة «تفعيل فقط» من الخادم.', isError: true);
      return;
    }
    final wantedCode = pkg.code.trim().toLowerCase();
    final wantedName = pkg.name.trim().toLowerCase();
    Map<String, dynamic>? match;
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final metadata = item['metadata'] is Map ? Map<String, dynamic>.from(item['metadata'] as Map) : <String, dynamic>{};
      final code = '${metadata['provider_offer_code'] ?? metadata['exact_api_code'] ?? metadata['package_code'] ?? item['code'] ?? item['external_code'] ?? ''}'.trim().toLowerCase();
      final name = '${item['name'] ?? ''}'.trim().toLowerCase();
      if ((wantedCode.isNotEmpty && code == wantedCode) || name == wantedName) {
        match = item;
        break;
      }
    }
    final matched = match;
    if (matched == null) {
      Navigator.of(sheetContext).pop();
      _showInquiryNotice('الخادم لم يوفر الباقة «${pkg.name}» ضمن كتالوج «تفعيل فقط». لم ننفذ أي عملية.', isError: true);
      return;
    }
    final itemId = int.tryParse('${matched['id'] ?? ''}') ?? 0;
    final itemType = '${matched['type'] ?? ''}'.trim();
    if (itemId <= 0 || itemType.isEmpty) {
      Navigator.of(sheetContext).pop();
      _showInquiryNotice('بيانات الباقة في خدمة «تفعيل فقط» غير مكتملة في الخادم.', isError: true);
      return;
    }
    final amount = double.tryParse('${matched['price'] ?? ''}') ?? pkg.price;
    final name = '${contract['name'] ?? app.getServiceName('yemen_mobile_package_activate_only', serviceId: serviceId, defaultName: 'يمن موبايل - تفعيل فقط')}';
    Navigator.of(sheetContext).pop();
    _openConfirmPaymentDialog(
      itemName: 'تفعيل فقط - ${pkg.name}',
      amount: amount,
      serviceId: serviceId,
      serviceName: name,
      itemId: itemId,
      itemType: itemType,
      itemCode: wantedCode,
    );
  }

  void _openPackageModal(_PackageItem pkg) {
    bool includeLoan = false;
    final app = context.read<AppController>();
    final resolvedService = _resolveServiceForCurrentAction(actionType: 'packages', appInstance: app);
    final packageServiceId = pkg.serviceId > 0 ? pkg.serviceId : resolvedService.id;
    final packageContract = app.serviceDetailsCache[packageServiceId];
    final packageServiceName = '${packageContract?['name'] ?? resolvedService.name}';
    final loanAdditionSupported = _serverSupportsLoanAddition(pkg, app);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final effectivePrice = includeLoan ? pkg.price + ymLoanAmount : pkg.price;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pkg.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          Text(pkg.subTitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const Divider(height: 12),
                // Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    children: [
                      _rowKV('المشغل', currentOp.name),
                      const SizedBox(height: 6),
                      _rowKV('الخدمة البرمجية (API)', resolvedService.name, color: currentOp.headerColor),
                      const SizedBox(height: 6),
                      _rowKV('معرف الخدمة (Service ID)', '${pkg.serviceId > 0 ? pkg.serviceId : resolvedService.id}'),
                      if (pkg.code.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _rowKV('كود الباقة للارسال', pkg.code, color: const Color(0xFF0284C7)),
                      ],
                      const SizedBox(height: 6),
                      _rowKV('معرف الباقة في الخادم', '#${pkg.id}'),
                      const SizedBox(height: 6),
                      _rowKV('الرقم المستهدف', phone.text.trim()),
                      const SizedBox(height: 6),
                      _rowKV('سعر الباقة الأساسي', money(pkg.price)),
                      if (pkg.netDiscountPrice != null) ...[
                        const SizedBox(height: 6),
                        _rowKV('صافي السعر بعد الخصم', money(pkg.netDiscountPrice!), color: AppColors.emerald),
                      ],
                      const SizedBox(height: 6),
                      _rowKV('الصلاحية', pkg.days),
                      const SizedBox(height: 6),
                      _rowKV('المكالمات', pkg.calls),
                      const SizedBox(height: 6),
                      _rowKV('الرسائل', pkg.sms),
                      const SizedBox(height: 6),
                      _rowKV('الإنترنت', pkg.internet),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Loan Toggle
                if (currentOp.id == 'yemen_mobile')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                        child: Text(
                          ymLoanStatus == 'loan' && ymLoanAmount > 0
                              ? 'تسديد مبلغ السلفة (${money(ymLoanAmount)})'
                              : ymLoanStatus == 'none'
                                  ? 'لا توجد سلفة حسب رد الخادم'
                                  : 'افحص السلفة أولاً',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ),
                        Switch(
                          value: includeLoan,
                          activeThumbColor: const Color(0xFFD97706),
                          onChanged: ymLoanStatus == 'loan' && ymLoanAmount > 0 && loanAdditionSupported
                              ? (v) => setSheetState(() => includeLoan = v)
                              : null,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                // Total and Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المبلغ الإجمالي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(money(effectivePrice), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: currentOp.headerColor)),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final catalogItemType = '${pkg.rawItem?['type'] ?? ''}'.trim();
                    if (pkg.rawItem == null || pkg.id <= 0 || catalogItemType.isEmpty) {
                      Navigator.pop(ctx);
                      _showInquiryNotice('هذه الباقة ليست مرتبطة بكتالوج الخادم الحالي. حدّث خدمات الاتصالات قبل السداد.', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    _openConfirmPaymentDialog(
                      itemName: pkg.name + (includeLoan ? ' + سداد السلفة' : ''),
                      amount: effectivePrice,
                      serviceId: packageServiceId,
                      serviceName: packageServiceName,
                      itemId: pkg.id,
                      itemCode: pkg.code,
                      itemType: catalogItemType,
                      repayLoan: includeLoan,
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: currentOp.headerColor, minimumSize: const Size(double.infinity, 44)),
                  child: const Text('تسديد + تفعيل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                ),
                if (currentOp.id == 'yemen_mobile') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _submitYemenMobileBalanceForPackage(pkg, ctx),
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 17),
                          label: const Text('تسديد الرصيد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          style: OutlinedButton.styleFrom(foregroundColor: currentOp.headerColor, side: BorderSide(color: currentOp.headerColor.withOpacity(0.5))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _submitYemenMobileActivationOnly(pkg, ctx),
                          icon: const Icon(Icons.bolt_rounded, size: 17),
                          label: const Text('تفعيل فقط', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          style: OutlinedButton.styleFrom(foregroundColor: currentOp.headerColor, side: BorderSide(color: currentOp.headerColor.withOpacity(0.5))),
                        ),
                      ),
                    ],
                  ),
                  if (ymLoanStatus == 'loan' && ymLoanAmount > 0 && !loanAdditionSupported) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'يعرض الخادم مبلغ السلفة، لكن خدمة الباقة الحالية لا تتيح إضافته إلى مبلغ الخصم. لم نفعّل الخيار لتجنب خصم غير صحيح.',
                      style: TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openConfirmPaymentDialog({
    required String itemName,
    required double amount,
    int? serviceId,
    String? serviceName,
    int? itemId,
    String? itemType,
    String? itemCode,
    bool repayLoan = false,
  }) {
    final targetPhone = phone.text.trim();
    if (targetPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الهاتف / الحساب أولاً قبل تأكيد السداد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final app = context.read<AppController>();
    final hasPrevious = app.operations.any((o) {
      final phone = '${o['account'] ?? o['phone'] ?? o['recipient'] ?? ''}';
      final title = '${o['title'] ?? o['service'] ?? o['packageName'] ?? o['name'] ?? ''}';
      return phone.contains(targetPhone) || title.contains(targetPhone);
    });

    if (hasPrevious) {
      _showRepeatPaymentWarningDialog(
        targetPhone: targetPhone,
        onConfirm: () {
          _showOrderConfirmationDialog(
            itemName: itemName,
            amount: amount,
            serviceId: serviceId,
            serviceName: serviceName,
            itemId: itemId,
            itemType: itemType,
            itemCode: itemCode,
            repayLoan: repayLoan,
          );
        },
      );
    } else {
      _showOrderConfirmationDialog(
        itemName: itemName,
        amount: amount,
        serviceId: serviceId,
        serviceName: serviceName,
        itemId: itemId,
        itemType: itemType,
        itemCode: itemCode,
        repayLoan: repayLoan,
      );
    }
  }

  // DIALOG 1: Repeat Payment Warning (مطابقة تامة للصورة 4)
  // "لديك عملية تسديد سابقة لهذا الرقم، اذا تريد تكرار السداد اضغط موافق، او الغاء لعدم التكرار"
  void _showRepeatPaymentWarningDialog({
    required String targetPhone,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amber circle (i)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 3.5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'i',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'لديك عملية تسديد سابقة لهذا الرقم، اذا تريد تكرار السداد اضغط موافق، او الغاء لعدم التكرار',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('الغاء', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('موافق', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DIALOG 2: ORDER CONFIRMATION (مطابقة تامة للصورة 1)
  // (i) + تأكيد الطلب + جدول تفاصيل الطلب + جدول تفاصيل التكلفة + بطاقة آخر عملية + كيبورد المبلغ المستلم + 3 أزرار
  void _showOrderConfirmationDialog({
    required String itemName,
    required double amount,
    int? serviceId,
    String? serviceName,
    int? itemId,
    String? itemType,
    String? itemCode,
    bool repayLoan = false,
  }) {
    final targetPhone = phone.text.trim();
    final fallbackSpec = _resolveServiceForCurrentAction(
      actionType: activeMainTab == 'باقات'
          ? 'packages'
          : (activeMainTab == 'فوري'
              ? 'instant'
              : (activeMainTab == 'تغيير الباقة'
                  ? 'change_package'
                  : (activeMainTab == 'الانترنت الارضي'
                      ? 'net_adsl'
                      : (activeMainTab == 'الهاتف الثابت'
                          ? 'net_line'
                          : 'balance')))),
    );
    final resolvedServiceId = serviceId ?? fallbackSpec.id;
    final resolvedServiceName = serviceName ?? fallbackSpec.name;

    String receivedValStr = '${amount.toInt()}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Top left close button (Pink circle with X)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE4E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFE11D48), size: 18),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Yellow circle (i)
                        Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'i',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title with amber divider lines: "تأكيد الطلب"
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFFFBBF24), thickness: 1.5)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'تأكيد الطلب',
                                style: TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Color(0xFFFBBF24), thickness: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Table 1: تفاصيل الطلب
                        const Text('تفاصيل الطلب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                child: const Row(
                                  children: [
                                    Expanded(child: Text('الخدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                    Expanded(child: Text('الصنف', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                    Expanded(child: Text('رقم الهاتف', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFCBD5E1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(resolvedServiceName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                    Expanded(child: Text(itemName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                    Expanded(child: Text(targetPhone, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                                  ],
                                ),
                              ),
                              if (itemCode != null && itemCode.isNotEmpty) ...[
                                const Divider(height: 1, color: Color(0xFFCBD5E1)),
                                Container(
                                  color: const Color(0xFFEFF6FF),
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('كود الباقة للارسال: ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                      Text(itemCode, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Table 2: تفاصيل التكلفة
                        const Text('تفاصيل التكلفة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                child: const Row(
                                  children: [
                                    Expanded(child: Text('المبلغ', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                    Expanded(child: Text('النسبة', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                    Expanded(child: Text('التكلفة', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF334155)))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFCBD5E1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(child: Text('${amount.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                                    const Expanded(child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                    Expanded(child: Text('${amount.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Arabic amount words below table
                        Text(
                          '* اجمالي التكلفة : ${_getArabicAmountWords(amount)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),

                        // Yellow notification alert box
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.notifications_active_rounded, size: 14, color: Color(0xFFD97706)),
                                      SizedBox(width: 4),
                                      Text('آخر عملية لهذا الرقم', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                                    ],
                                  ),
                                  Text(
                                    '${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 9.5, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(itemName, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF78350F))),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('عملية جديدة لأول مرة', style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                                  Text('${amount.toInt()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                                  const Text('فحص الجاهزية', style: TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Received Amount Keypad Field
                        Row(
                          children: [
                            const Text('المبلغ المستلم:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  receivedValStr.isEmpty ? '0' : receivedValStr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Interactive Numeric Keypad (2 rows matching Screenshot 1)
                        // Row 1: 1 2 3 4 5 6
                        Row(
                          children: ['1', '2', '3', '4', '5', '6'].map((k) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      receivedValStr += k;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        // Row 2: 7 8 9 0 x (backspace)
                        Row(
                          children: ['7', '8', '9', '0', '⌫'].map((k) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      if (k == '⌫') {
                                        if (receivedValStr.isNotEmpty) {
                                          receivedValStr = receivedValStr.substring(0, receivedValStr.length - 1);
                                        }
                                      } else {
                                        receivedValStr += k;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: k == '⌫' ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: k == '⌫' ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: k == '⌫' ? const Color(0xFFE11D48) : const Color(0xFF334155))),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Bottom 3 Action Buttons (موافق (أخضر), عبر الرسائل (أزرق), عبر الواتس (سماوي))
                        Row(
                          children: [
                            // موافق (Green)
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _executePaymentWithWaitingDialog(
                                    itemName: itemName,
                                    amount: amount,
                                    targetPhone: targetPhone,
                                    resolvedServiceId: resolvedServiceId,
                                    resolvedServiceName: resolvedServiceName,
                                    itemId: itemId,
                                    itemType: itemType,
                                    itemCode: itemCode,
                                    repayLoan: repayLoan,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text('موافق', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // عبر الرسائل (Blue)
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: 'طلب سداد $itemName للرقم $targetPhone بمبلغ $amount ر.ي'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ تفاصيل الطلب لإرسالها بالرسائل')),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                                label: const Text('عبر الرسائل', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // عبر الواتس (Cyan)
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: 'طلب سداد $itemName للرقم $targetPhone بمبلغ $amount ر.ي عبر تطبيق شبيك'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ تفاصيل الطلب للمشاركة عبر الواتساب')),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF00ACC1),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                label: const Text('عبر الواتس', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
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
    );
  }

  String _paymentStorageKey(AppController app) =>
      'shopik_active_payment_-${app.user?.id ?? 0}';

  String _paymentFingerprint({
    required AppController app,
    required int serviceId,
    required String targetPhone,
    required double amount,
    int? itemId,
    String? itemType,
  }) {
    final source = '${app.user?.id ?? 0}|$serviceId|$targetPhone|${amount.toStringAsFixed(2)}|${itemId ?? ''}|${itemType ?? ''}';
    var hash = 0x811c9dc5;
    for (final byte in source.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  Future<Map<String, dynamic>?> _readActivePayment(AppController app) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_paymentStorageKey(app));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveActivePayment(
    AppController app, {
    required String fingerprint,
    required String idempotencyKey,
    String? transactionId,
    String? status,
    required int serviceId,
    required String serviceName,
    required String targetPhone,
    required double amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_paymentStorageKey(app), jsonEncode({
        'fingerprint': fingerprint,
        'idempotency_key': idempotencyKey,
        'transaction_id': transactionId,
        'status': status ?? 'submitting',
        'service_id': serviceId,
        'service_name': serviceName,
        'target_phone': targetPhone,
        'amount': amount,
        'updated_at': DateTime.now().toIso8601String(),
      }));
    } catch (_) {
      // The server transaction remains authoritative if local recovery storage fails.
    }
  }

  Future<void> _clearActivePayment(AppController app) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_paymentStorageKey(app));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _buildServerPaymentPayload({
    required AppController app,
    required int serviceId,
    required String targetPhone,
    required double amount,
    required String itemName,
    required int? itemId,
    required String? itemType,
    required String? itemCode,
    bool repayLoan = false,
  }) async {
    final loaded = await app.loadServiceContract(serviceId, force: true);
    final contract = loaded ?? app.serviceDetailsCache[serviceId];
    if (contract == null) {
      throw Exception('تعذر تحميل تعريف الخدمة من الخادم. أعد مزامنة خدمات الاتصالات ثم حاول مرة أخرى.');
    }
    final rawFields = contract['fields'];
    final hasCatalogItem = itemId != null && itemId > 0 && itemType != null && itemType.isNotEmpty;
    if (rawFields is! List || rawFields.isEmpty) {
      throw Exception('لم يُرجع الخادم حقول الطلب لهذه الخدمة؛ أوقفنا الإرسال لتجنب عملية غير مكتملة.');
    }

    final payload = <String, dynamic>{};
    final pricingMode = '${contract['pricing_mode'] ?? ''}'.trim().toLowerCase();
    final requiresBalance = contract['requires_balance'] == true;
    if (requiresBalance && pricingMode == 'item' && !hasCatalogItem) {
      throw Exception('هذه الخدمة مسعّرة بحسب الباقة. اختر عنصرًا من كتالوج الخادم بدل استخدام فئة ثابتة قديمة.');
    }
    if (pricingMode == 'fixed') {
      final serverPrice = num.tryParse('${contract['price'] ?? ''}');
      if (serverPrice != null && (serverPrice - amount).abs() > 0.009) {
        throw Exception('السعر المعروض ${amount.toStringAsFixed(2)} ر.ي لا يطابق السعر الثابت المسجل في الخادم (${serverPrice.toStringAsFixed(2)} ر.ي). لم نرسل الطلب لتجنب خصم مبلغ مختلف.');
      }
    }
    for (final rawField in rawFields.whereType<Map>()) {
      final field = Map<String, dynamic>.from(rawField);
      final key = '${field['key'] ?? ''}'.trim();
      if (key.isEmpty) continue;
      final normalizedKey = key.toLowerCase();
      final required = field['required'] == true;
      final defaultValue = field['default'];
      dynamic value;

      if (repayLoan && const {'loan_amount', 'loanamount', 'sulfa_amount', 'sulfaamount'}.contains(normalizedKey)) {
        value = ymLoanAmount;
      } else if (repayLoan && const {'loan', 'has_loan', 'hasloan', 'is_loan', 'isloan', 'repay_loan', 'repayloan', 'include_loan', 'includeloan', 'pay_loan', 'settle_loan', 'sulfa', 'has_sulfa', 'hassulfa'}.contains(normalizedKey)) {
        value = true;
      } else if (const {
        'mobile', 'phone', 'msisdn', 'mobile_number', 'phone_number',
        'subscriber_number', 'account_number', 'line_number', 'recipient_number',
        'target_phone', 'number',
      }.contains(normalizedKey)) {
        value = targetPhone;
      } else if (const {'amount', 'value', 'payment_amount'}.contains(normalizedKey)) {
        if (itemId == null || pricingMode != 'item') value = amount;
      } else if (normalizedKey == 'type' && currentOpId == 'yemen_net') {
        value = netTab == 'phone' ? 'phone' : 'adsl';
      } else if (const {'operator', 'network', 'carrier', 'service_operator'}.contains(normalizedKey)) {
        final choices = field['choices'];
        final allowed = <String>{};
        if (choices is List) {
          for (final choice in choices) {
            if (choice is Map) {
              allowed.add('${choice['value'] ?? choice['key'] ?? choice['id'] ?? ''}');
            } else if (choice != null) {
              allowed.add('$choice');
            }
          }
        }
        if (allowed.isEmpty || allowed.contains(currentOpId)) {
          value = currentOpId;
        } else if (allowed.contains(currentOp.name)) {
          value = currentOp.name;
        }
      } else if (const {'package', 'package_name', 'plan', 'plan_name'}.contains(normalizedKey)) {
        if (itemId == null) value = itemName;
      } else if (const {'code', 'package_code', 'provider_offer_code', 'external_code'}.contains(normalizedKey)) {
        if (itemId == null && itemCode != null && itemCode.isNotEmpty) value = itemCode;
      } else if (defaultValue != null && '$defaultValue'.trim().isNotEmpty) {
        value = defaultValue;
      }

      if (value != null && '$value'.trim().isNotEmpty) {
        payload[key] = value;
      } else if (required &&
          !(itemId != null &&
            const {'amount', 'external_code', 'num', 'packageid', 'uniqcode'}.contains(normalizedKey))) {
        final label = '${field['label'] ?? key}';
        throw Exception('يتطلب الخادم الحقل «$label»، ولا يمكن تعبئته بأمان من الشاشة الحالية.');
      }
    }
    return payload;
  }

  Future<void> _showPendingPaymentDialog({
    required Map<String, dynamic> transaction,
    required String itemName,
    required String targetPhone,
    required double amount,
    bool unknownReference = false,
  }) async {
    final transactionId = '${transaction['id'] ?? transaction['transaction_id'] ?? ''}'.trim();
    final message = unknownReference || transactionId.isEmpty
        ? 'لم يصل تأكيد نهائي أو رقم مرجع من الخادم. قد يكون الطلب قد استُلم بالفعل. لا تعاود السداد الآن؛ افتح سجل العمليات وافحص الخادم أولًا.'
        : 'استلم الخادم طلب «$itemName» للرقم $targetPhone بمبلغ ${amount.toStringAsFixed(2)} ر.ي، لكنه لم يُرجع نتيجة نهائية بعد. لا تكرر السداد؛ استخدم المرجع لفحص الحالة من سجل العمليات.';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(color: Color(0xFFFFF7E6), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 32),
              ),
              const SizedBox(height: 10),
              const Text('تم إرسال العملية وجاري انتظار الرد', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, height: 1.6, color: Color(0xFF334155))),
              if (transactionId.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SelectableText(
                    'مرجع العملية: $transactionId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy, minimumSize: const Size(double.infinity, 42)),
                  child: const Text('حسنًا، سأفحص سجل العمليات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Preserve the original payment panel and confirmation UI. Only request
  // validation, server polling, and transaction outcome handling are changed.
  void _executePaymentWithWaitingDialog({
    required String itemName,
    required double amount,
    required String targetPhone,
    required int resolvedServiceId,
    required String resolvedServiceName,
    int? itemId,
    String? itemType,
    String? itemCode,
    bool repayLoan = false,
  }) async {
    if (_paymentInProgress) {
      _showInquiryNotice('يوجد طلب سداد قيد المعالجة. انتظر نتيجته قبل إرسال طلب آخر.', isError: true);
      return;
    }
    if (targetPhone.trim().isEmpty || amount <= 0 || resolvedServiceId <= 0) {
      _showInquiryNotice('بيانات السداد غير مكتملة. تحقق من الرقم والمبلغ والخدمة.', isError: true);
      return;
    }

    final app = context.read<AppController>();
    final fingerprint = _paymentFingerprint(
      app: app,
      serviceId: resolvedServiceId,
      targetPhone: targetPhone,
      amount: amount,
      itemId: itemId,
      itemType: itemType,
    );
    var idempotencyKey = '';
    var requestSent = false;
    _paymentInProgress = true;
    bool waitingDialogOpen = true;
    void closeWaitingDialog() {
      if (!waitingDialogOpen) return;
      waitingDialogOpen = false;
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MultiColorDotsSpinner(size: 52),
              SizedBox(height: 18),
              Text('الرجاء الانتظار قليلًا...', textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text('جاري إرسال طلب السداد والتحقق من نتيجته لدى الخادم (حتى 40 ثانية)',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    try {
      final active = await _readActivePayment(app);
      if (active != null) {
        final activeId = '${active['transaction_id'] ?? ''}'.trim();
        final previousFingerprint = '${active['fingerprint'] ?? ''}';
        final previousKey = '${active['idempotency_key'] ?? ''}'.trim();
        if (activeId.isNotEmpty) {
          Map<String, dynamic>? existingTx;
          try {
            existingTx = await app.api.serviceTransaction(activeId);
          } catch (_) {}
          if (existingTx != null && _isTransactionPending(existingTx)) {
            existingTx = await app.api.waitForServiceTransaction(
              activeId,
              initial: existingTx,
              maxWait: const Duration(seconds: 30),
              pollInterval: const Duration(seconds: 2),
            );
          }
          if (existingTx != null && _isTransactionSuccess(existingTx)) {
            await _clearActivePayment(app);
            if (!mounted) return;
            closeWaitingDialog();
            unawaited(app.refreshWalletAndReports().catchError((_) {}));
            _showSuccessDialog(
              res: existingTx,
              itemName: '${active['service_name'] ?? itemName}',
              targetPhone: targetPhone,
              amount: double.tryParse('${existingTx['amount'] ?? active['amount'] ?? amount}') ?? amount,
              serviceId: resolvedServiceId,
              serviceName: resolvedServiceName,
            );
            return;
          }
          if (existingTx != null && _isTransactionFailure(existingTx)) {
            await _clearActivePayment(app);
          } else {
            if (!mounted) return;
            closeWaitingDialog();
            await _showPendingPaymentDialog(
              transaction: existingTx ?? active,
              itemName: itemName,
              targetPhone: targetPhone,
              amount: amount,
              unknownReference: existingTx == null,
            );
            return;
          }
        } else if (previousFingerprint != fingerprint) {
          closeWaitingDialog();
          await _showPendingPaymentDialog(
            transaction: active,
            itemName: itemName,
            targetPhone: targetPhone,
            amount: amount,
            unknownReference: true,
          );
          return;
        } else {
          idempotencyKey = previousKey;
        }
      }

      if (idempotencyKey.isEmpty) {
        idempotencyKey = 'shopik-pay-${app.user?.id ?? 0}-${DateTime.now().microsecondsSinceEpoch}-$fingerprint';
      }
      await _saveActivePayment(
        app,
        fingerprint: fingerprint,
        idempotencyKey: idempotencyKey,
        serviceId: resolvedServiceId,
        serviceName: resolvedServiceName,
        targetPhone: targetPhone,
        amount: amount,
      );

      final payload = await _buildServerPaymentPayload(
        app: app,
        serviceId: resolvedServiceId,
        targetPhone: targetPhone,
        amount: amount,
        itemName: itemName,
        itemId: itemId,
        itemType: itemType,
        itemCode: itemCode,
        repayLoan: repayLoan,
      );
      requestSent = true;
      final res = await app.api.submitAndPollServiceRequest(
        serviceId: resolvedServiceId,
        itemType: itemType,
        itemId: itemId,
        idempotencyKey: idempotencyKey,
        payload: payload,
        maxWait: const Duration(seconds: 40),
        pollInterval: const Duration(seconds: 2),
      );

      if (!mounted) return;
      closeWaitingDialog();
      final status = _transactionStatus(res);
      final transactionId = '${res['id'] ?? ''}'.trim();
      await _saveActivePayment(
        app,
        fingerprint: fingerprint,
        idempotencyKey: idempotencyKey,
        transactionId: transactionId.isEmpty ? null : transactionId,
        status: status,
        serviceId: resolvedServiceId,
        serviceName: resolvedServiceName,
        targetPhone: targetPhone,
        amount: amount,
      );
      unawaited(app.refreshWalletAndReports().catchError((_) {}));

      if (_isTransactionSuccess(res) && transactionId.isNotEmpty) {
        await _clearActivePayment(app);
        _showSuccessDialog(
          res: res,
          itemName: itemName,
          targetPhone: targetPhone,
          amount: double.tryParse('${res['amount'] ?? ''}') ?? amount,
          serviceId: resolvedServiceId,
          serviceName: resolvedServiceName,
        );
      } else if (const {'failed', 'error', 'rejected', 'refunded'}.contains(status)) {
        await _clearActivePayment(app);
        final reason = _transactionMessage(res).isNotEmpty
            ? _transactionMessage(res)
            : (status == 'refunded' ? 'أعاد الخادم حالة استرداد الرصيد.' : 'أعاد الخادم حالة فشل للعملية.');
        _showFailureDialog(errorReason: reason);
      } else {
        await _showPendingPaymentDialog(
          transaction: res,
          itemName: itemName,
          targetPhone: targetPhone,
          amount: amount,
          unknownReference: transactionId.isEmpty,
        );
      }
    } catch (error) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        closeWaitingDialog();
      }
      final apiRejected = error is ApiException &&
          const {400, 401, 403, 404, 405, 422}.contains(error.statusCode);
      if (apiRejected || !requestSent) {
        await _clearActivePayment(app);
        if (mounted) {
          _showFailureDialog(
            errorReason: 'رفض الخادم الطلب أو لم تكتمل بياناته: ${error.toString().replaceFirst('Exception: ', '')}',
          );
        }
      } else {
        // A timeout/5xx can happen after the backend has accepted the POST.
        // Keep the idempotency key and block duplicate payment until reconciled.
        final active = await _readActivePayment(app);
        final storedKey = '${active?['idempotency_key'] ?? idempotencyKey}';
        await _saveActivePayment(
          app,
          fingerprint: fingerprint,
          idempotencyKey: storedKey,
          transactionId: active?['transaction_id']?.toString(),
          status: 'unknown',
          serviceId: resolvedServiceId,
          serviceName: resolvedServiceName,
          targetPhone: targetPhone,
          amount: amount,
        );
        if (mounted) {
          await _showPendingPaymentDialog(
            transaction: active ?? <String, dynamic>{},
            itemName: itemName,
            targetPhone: targetPhone,
            amount: amount,
            unknownReference: true,
          );
        }
      }
    } finally {
      _paymentInProgress = false;
    }
  }

  // DIALOG 4: SUCCESS DIALOG (مطابقة تامة للصورة 2)
  // دائرة خضراء بصح + "جاهز" بخط كبير + "تم تسديد المبلغ بنجاح!" + "تم تسديد الرقم ... بمبلغ ... ريال" + نسخ ومشاركة + إضافة للتطبيق المحاسبي + عداد النسبة 86% ورصيدك الحالي + 3 أزرار: رجوع / العمليات / اغلاق
  void _showSuccessDialog({
    required Map<String, dynamic> res,
    required String itemName,
    required String targetPhone,
    required double amount,
    int? serviceId,
    String? serviceName,
  }) {
    final app = context.read<AppController>();
    final ref = res['id'] ?? res['reference'] ?? res['transaction_id'] ?? 'غير متوفر من الخادم';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Green checkmark circle
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 8),

              // Title "جاهز" (Green & bold)
              const Center(
                child: Text(
                  'جاهز',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 2),

              // "تم تسديد المبلغ بنجاح!"
              const Center(
                child: Text(
                  'تم تسديد المبلغ بنجاح!',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // "تم تسديد الرقم ... بمبلغ ... ريال"
              Center(
                child: Text(
                  'تم تسديد الرقم $targetPhone بمبلغ ${amount.toStringAsFixed(2)} ريال',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // Row with "نسخ" and "مشاركة"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'سند سداد شبيك: $itemName للرقم $targetPhone بمبلغ $amount ر.ي مرجع: $ref'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ تفاصيل السند بنجاح')));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text('نسخ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'تم تسديد $itemName للرقم $targetPhone بمبلغ $amount ر.ي بنجاح عبر تطبيق شبيك'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز نص المشاركة')));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, size: 14, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text('مشاركة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // "اضافة للتطبيق المحاسبي" card with cloud icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Text('اضافة للتطبيق المحاسبي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Circular Percentage Gauge (86% + رصيدك الحالي)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: CircularProgressIndicator(
                            value: 0.86,
                            strokeWidth: 4.5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                        const Text('86%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('رصيدك الحالي', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('${app.balanceFormatted} ر.ي', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom 3 Buttons: رجوع (برتقالي) / العمليات (أزرق) / اغلاق (أحمر)
              Row(
                children: [
                  // رجوع (Orange)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text('رجوع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // العمليات (Blue)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        app.setTab(AppTab.operations);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                      label: const Text('العمليات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // اغلاق (Red)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('اغلاق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DIALOG 5: FAILURE DIALOG
  // دائرة برتقالية (i) + "فشل اثناء تنفيذ عملية التسديد! السبب/" + السبب + زر موافق
  void _showFailureDialog({required String errorReason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF59E0B), width: 3.5),
                ),
                alignment: Alignment.center,
                child: const Text('i', style: TextStyle(fontFamily: 'serif', fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
              ),
              const SizedBox(height: 12),
              const Text('فشل اثناء تنفيذ عملية التسديد! السبب/', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(errorReason, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('موافق', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowKV(String k, String v, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Text(v, style: TextStyle(fontSize: 11.5, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color ?? const Color(0xFF1E293B))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final op = currentOp;

    return ScreenFrame(
      title: 'شبكة السداد',
      color: op.headerColor,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => userBalanceHidden = !userBalanceHidden),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('الرصيد', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(
                      userBalanceHidden ? '••••' : money(app.walletBalance),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _syncTelecomPackages(),
              icon: _isSyncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث الرصيد والباقات من الخادم',
            ),
          ],
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        children: [
          // Wallet balance and refresh are shown in the app header; do not repeat them here.

                    // Operator Restriction Toast Banner
          if (operatorRestrictedToast != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B))),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Text(operatorRestrictedToast!, style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Phone Input Card (with contacts picker, clear X, and operator badge)
          PageCard(
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickContactFromDevice,
                  icon: const Icon(Icons.contacts_rounded, color: Color(0xFF64748B)),
                  tooltip: 'اختيار من جهات الاتصال',
                ),
                const SizedBox(width: 4),
                const Text('+967', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: phone,
                    focusNode: phoneFocusNode,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _handlePhoneChange,
                    decoration: InputDecoration(
                      hintText: op.prefix == '01' ? 'رقم الهاتف الأرضي' : 'أدخل 9 أرقام...',
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                if (phone.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      phone.clear();
                      _handlePhoneChange('');
                    },
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ),
                if (currentOpId.isNotEmpty)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: op.headerColor),
                    alignment: Alignment.center,
                    child: Text(op.shortName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (currentOpId.isNotEmpty) ...[
            // Dynamic Main Tabs Bar
            _buildMainTabsBar(op),
            const SizedBox(height: 12),
            // TAB CONTENT
            if (activeMainTab == 'باقات') ...[
              _buildPackagesTab(op),
            ] else if (activeMainTab == 'رصيد' || activeMainTab == 'رصيد يمن 4G') ...[
              _buildBalanceTab(op),
            ] else if (activeMainTab == 'فوري') ...[
              _buildInstantTab(op),
            ] else if (activeMainTab == 'باقة يمن 4G') ...[
              _buildFourGTab(op),
            ] else if (activeMainTab == 'الانترنت الارضي' || activeMainTab == 'الهاتف الثابت') ...[
              _buildNetTab(op),
            ] else ...[
              PageCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const Text('اختر نوع الخدمة بعد إدخال الرقم', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],        ],
      ),
    );
  }

  Widget _buildMainTabsBar(_OperatorSpec op) {
    if (op.id == 'yemen4g') {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFFBAE6FD), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: ['باقة يمن 4G', 'رصيد يمن 4G', 'تغيير الباقة', 'فايبر'].map((t) {
            final active = t == activeMainTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => activeMainTab = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: active ? const Color(0xFF0284C7) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: active ? Colors.white : const Color(0xFF0369A1))),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else if (op.id == 'yemen_net') {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFFC7D2FE), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: ['الانترنت الارضي', 'الهاتف الثابت'].map((t) {
            final active = t == activeMainTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  activeMainTab = t;
                  netTab = t == 'الانترنت الارضي' ? 'adsl' : 'phone';
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: active ? const Color(0xFF283593) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? Colors.white : const Color(0xFF1E1B4B))),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Standard Orange / Peach Tab Bar
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFFFED7AA), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: op.mainTabs.map((t) {
            final active = t == activeMainTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectMainTab(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: active ? op.activeTabColor : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? Colors.white : const Color(0xFF7C2D12))),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }


  bool _packageMatchesBillingFilter(_PackageItem pkg) {
    if (billingFilter == 'الكل') return true;
    final metadata = pkg.rawItem?['metadata'] is Map
        ? Map<String, dynamic>.from(pkg.rawItem!['metadata'] as Map)
        : <String, dynamic>{};
    final text = '${pkg.name} ${pkg.subTitle} ${pkg.description} ${metadata['billing_type'] ?? ''} ${metadata['mobile_type'] ?? ''}'.toLowerCase();
    final isPostpaid = text.contains('فوترة') || text.contains('فوتر') || text.contains('postpaid') || text.contains('post_paid');
    final isPrepaid = text.contains('دفع مسبق') || text.contains('prepaid') || text.contains('pre_paid');
    if (isPostpaid) return billingFilter == 'فوترة';
    if (isPrepaid) return billingFilter == 'دفع مسبق';
    final serverBilling = _serverMobileBillingType({'mobileType': ymPhoneType});
    return serverBilling == null || serverBilling == billingFilter;
  }

  bool _packageMatchesKindFilter(_PackageItem pkg) {
    if (packageKindFilter == 'الكل') return true;
    final metadata = pkg.rawItem?['metadata'] is Map
        ? Map<String, dynamic>.from(pkg.rawItem!['metadata'] as Map)
        : <String, dynamic>{};
    final text = '${pkg.name} ${pkg.subTitle} ${pkg.description} '
        '${metadata['package_kind'] ?? metadata['chip_type'] ?? metadata['activation_type'] ?? metadata['medium'] ?? ''}'.toLowerCase();
    final hasSim = text.contains('شريحة') || text.contains('شريحه') || text.contains('sim');
    final hasProgramming = text.contains('برمجة') || text.contains('برمجه') || text.contains('program');
    if (hasSim && hasProgramming) return true;
    if (packageKindFilter == 'شريحة') return hasSim || !hasProgramming;
    if (packageKindFilter == 'برمجة') return hasProgramming || !hasSim;
    return true;
  }

  Widget _buildPackageFilterRow(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
    Color activeColor,
  ) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((option) {
          final isSelected = selected == option;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor,
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? activeColor : const Color(0xFFCBD5E1)),
              onSelected: (_) => onSelected(isSelected ? 'الكل' : option),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackagesTab(_OperatorSpec op) {
    final app = context.watch<AppController>();
    final Map<String, List<_PackageItem>> pkgMap = _getPackagesForOp(op, app);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3-Column Inquiry Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              // Col 1: رصيد الرقم
              Expanded(
                child: Column(
                  children: [
                    const Text('رصيد الرقم', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(ymPhoneBalance, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              // Col 2: نوع الرقم
              Expanded(
                child: Column(
                  children: [
                    const Text('نوع الرقم', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(ymPhoneType, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
              // Col 3: فحص السلفة
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _runInquiry('sulfa'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                        child: const Text('فحص السلفة', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ymLoanStatus == 'loan'
                          ? 'متسلف ${ymLoanAmount.toStringAsFixed(2)} ر.ي ⚠️'
                          : ymLoanStatus == 'none'
                              ? 'غير متسلف'
                              : 'السلفة غير مفحوصة',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ymLoanStatus == 'none' ? AppColors.emerald : Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Active Subscriptions Card// Active Subscriptions Card (الاشتراكات الحالية)
        if (op.id == 'yemen_mobile' && activeSubscriptions.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: op.headerColor,
                  width: double.infinity,
                  child: const Text('الاشتراكات الحالية', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
                Container(
                  color: const Color(0xFFFFF8F0),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: activeSubscriptions.map((sub) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFED7AA))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sub.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                  Text('الإشتراك: ${sub.startDate}', style: const TextStyle(fontSize: 9, color: AppColors.emerald, fontWeight: FontWeight.bold)),
                                  Text('الإنتهاء: ${sub.endDate}', style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () => _openConfirmPaymentDialog(itemName: 'تجديد ${sub.name}', amount: 600.0),
                              style: FilledButton.styleFrom(backgroundColor: op.headerColor, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: const Size(60, 28)),
                              child: const Text('تجديد', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Independent filters: billing type AND SIM/programming.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackageFilterRow(
              ['دفع مسبق', 'فوترة'],
              billingFilter,
              (v) => setState(() => billingFilter = v),
              op.headerColor,
            ),
            const SizedBox(height: 4),
            _buildPackageFilterRow(
              ['شريحة', 'برمجة'],
              packageKindFilter,
              (v) => setState(() => packageKindFilter = v),
              op.headerColor,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Accordion Package Categories
        ...pkgMap.entries.map((entry) {
          final catTitle = entry.key;
          final allPkgs = entry.value;

          // Both filters apply together; unknown catalog metadata remains visible.
          final pkgs = allPkgs.where((pkg) =>
              _packageMatchesBillingFilter(pkg) && _packageMatchesKindFilter(pkg)).toList();

          if (pkgs.isEmpty && (billingFilter != 'الكل' || packageKindFilter != 'الكل')) {
            return const SizedBox.shrink();
          }

          final isExpanded = expandedCategories[catTitle] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Accordion Header
                InkWell(
                  onTap: () => setState(() => expandedCategories[catTitle] = !isExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: op.headerColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                              child: Text(catTitle.contains('فورجي') || catTitle.contains('4G') ? '4G' : '3G', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            ),
                            const SizedBox(width: 8),
                            Text('$catTitle (${pkgs.length})', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // Package Cards List (مطابقة تامة لكروت الباقات)
                if (isExpanded)
                  Container(
                    color: const Color(0xFFFDFBF7),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: pkgs.map((pkg) => _buildPackageCard(pkg, op)).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPackageCard(_PackageItem pkg, _OperatorSpec op) {
    Color cardBg;
    Color cardBorder;
    Color dividerColor;
    switch (op.id) {
      case 'yemen_mobile':
        cardBg = const Color(0xFFFFF1F2);
        cardBorder = const Color(0xFFFECDD3);
        dividerColor = const Color(0xFFFECDD3);
        break;
      case 'sabafon':
        cardBg = const Color(0xFFEFF6FF);
        cardBorder = const Color(0xFFBFDBFE);
        dividerColor = const Color(0xFFBFDBFE);
        break;
      case 'you':
        cardBg = const Color(0xFFFFFBEB);
        cardBorder = const Color(0xFFFDE68A);
        dividerColor = const Color(0xFFFDE68A);
        break;
      case 'y':
        cardBg = const Color(0xFFFEF2F2);
        cardBorder = const Color(0xFFFECACA);
        dividerColor = const Color(0xFFFECACA);
        break;
      case 'yemen4g':
        cardBg = const Color(0xFFF0F9FF);
        cardBorder = const Color(0xFFBAE6FD);
        dividerColor = const Color(0xFFBAE6FD);
        break;
      case 'yemen_net':
      default:
        cardBg = const Color(0xFFEEF2FF);
        cardBorder = const Color(0xFFC7D2FE);
        dividerColor = const Color(0xFFC7D2FE);
        break;
    }

    return InkWell(
      onTap: () => _openPackageModal(pkg),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Top: Name, subtitle, and circle avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: op.headerColor)),
                      const SizedBox(height: 2),
                      Text(pkg.subTitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: op.headerColor),
                  alignment: Alignment.center,
                  child: Text(op.shortName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // Center: Big 3D Bold Price (السعر بخط بارز جداً بالمنتصف)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${pkg.price.toInt()}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
              ),
            ),

            Divider(height: 12, color: dividerColor),

            // Bottom 4-Columns: Days, Calls, SMS, Internet
            Row(
              children: [
                _buildPkgMetric(Icons.access_time_rounded, pkg.days),
                Container(width: 1, height: 26, color: dividerColor),
                _buildPkgMetric(Icons.phone_in_talk_rounded, pkg.calls),
                Container(width: 1, height: 26, color: dividerColor),
                _buildPkgMetric(Icons.mail_outline_rounded, pkg.sms),
                Container(width: 1, height: 26, color: dividerColor),
                _buildPkgMetric(Icons.language_rounded, pkg.internet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPkgMetric(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(height: 2),
          Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildBalanceTab(_OperatorSpec op) {
    final amt = double.tryParse(rechargeAmount.text) ?? 0;
    final netTax = amt * 0.829;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (balanceInquiryBanner != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF26C6DA), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(balanceInquiryBanner!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (op.hasUnits) ...[
                const Text('*ادخل عدد الوحدات', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                TextField(
                  controller: unitsCount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'عدد الوحدات', suffixText: '\$', isDense: true),
                ),
                const SizedBox(height: 6),
                Builder(builder: (_) {
                  final u = double.tryParse(unitsCount.text) ?? 0;
                  final total = u * 12.1;
                  return Text('إجمالي المبلغ: ${total.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5)));
                }),
              ] else ...[
                const Text('*ادخل المبلغ بالريال اليمني', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                TextField(
                  controller: rechargeAmount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'ر.ي', isDense: true),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('صافي الرصيد بعد خصم الضريبة:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      Text('${netTax.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick recharge amounts
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [100, 200, 300, 500, 1000, 2000, 5000].map((quick) {
            return ActionChip(
              label: Text('$quick ر.ي', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() => rechargeAmount.text = '$quick');
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final finalAmt = op.hasUnits ? (double.tryParse(unitsCount.text) ?? 0) * 12.1 : (double.tryParse(rechargeAmount.text) ?? 0);
                  if (finalAmt <= 0) return;
                  final resolvedBal = _resolveServiceForCurrentAction(actionType: 'balance');
                  _openConfirmPaymentDialog(
                    itemName: 'شحن رصيد ${op.name}',
                    amount: finalAmt,
                    serviceId: resolvedBal.id,
                    serviceName: resolvedBal.name,
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: op.activeTabColor, minimumSize: const Size(0, 44)),
                child: const Text('تسديد الرصيد', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            if (op.hasInquiryInBalance) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _runInquiry('balance'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(90, 44)),
                child: const Text('استعلام', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInstantTab(_OperatorSpec op) {
    final app = context.watch<AppController>();
    final resolvedInstant = _resolveServiceForCurrentAction(actionType: 'instant', appInstance: app);
    final cachedContract = app.serviceDetailsCache[resolvedInstant.id];
    if (cachedContract == null) {
      app.loadServiceContract(resolvedInstant.id);
    }

    List<_DenominationItem> list = op.id == 'yemen_mobile'
        ? yemenMobileDenominations
        : op.id == 'sabafon'
            ? sabafonDenominations
            : op.id == 'y'
                ? yDenominations
                : youDenominations;

    if (cachedContract != null && cachedContract['items'] is List && (cachedContract['items'] as List).isNotEmpty) {
      final dynList = <_DenominationItem>[];
      for (final it in (cachedContract['items'] as List).whereType<Map>()) {
        final id = int.tryParse('${it['id']}');
        final name = '${it['name'] ?? ''}';
        final price = double.tryParse('${it['price'] ?? 0}') ?? 0;
        final tier = int.tryParse('${it['tier'] ?? it['value'] ?? it['id']}') ?? price.toInt();
        dynList.add(_DenominationItem(
          id: id,
          name: name,
          tier: tier > 0 ? tier : price.toInt(),
          price: price > 0 ? price : tier.toDouble(),
          days: '${it['validity_days'] ?? it['days'] ?? 'صلاحية الفئة'}',
          itemType: '${it['type'] ?? ''}',
        ));
      }
      if (dynList.isNotEmpty) {
        list = dynList;
      }
    }

    final Color durationBg = op.id == 'yemen_mobile'
        ? const Color(0xFFFFE4E6)
        : op.id == 'sabafon'
            ? const Color(0xFFDBEAFE)
            : op.id == 'you'
                ? const Color(0xFFFEF3C7)
                : op.id == 'y'
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFED7AA);

    final Color durationText = op.id == 'yemen_mobile'
        ? const Color(0xFF8B1D3B)
        : op.id == 'sabafon'
            ? const Color(0xFF1E88E5)
            : op.id == 'you'
                ? const Color(0xFFB45309)
                : op.id == 'y'
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF7C2D12);

    final Color cardBorder = op.id == 'yemen_mobile'
        ? const Color(0xFFFECDD3)
        : op.id == 'sabafon'
            ? const Color(0xFFBFDBFE)
            : op.id == 'you'
                ? const Color(0xFFFDE68A)
                : op.id == 'y'
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFE2E8F0);

    return Column(
      children: [
        if (op.id == 'sabafon')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(value: 'شمال', groupValue: sabafonRegion, onChanged: (v) => setState(() => sabafonRegion = v!)),
                const Text('شمال', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                Radio<String>(value: 'جنوب', groupValue: sabafonRegion, onChanged: (v) => setState(() => sabafonRegion = v!)),
                const Text('جنوب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

        if (op.id == 'you')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الشاحن الذكي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Switch(value: youSmartCharger, onChanged: (v) => setState(() => youSmartCharger = v)),
              ],
            ),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .88),
          itemBuilder: (_, i) {
            final d = list[i];
            return InkWell(
              onTap: () {
                if (d.id == null || d.itemType.isEmpty) {
                  _showInquiryNotice('هذه الفئة ليست مرتبطة بكتالوج الخادم الحالي. حدّث خدمات الاتصالات ثم أعد المحاولة.', isError: true);
                  return;
                }
                _openConfirmPaymentDialog(
                  itemName: d.name != null && d.name!.isNotEmpty ? d.name! : 'فئة ${d.tier}',
                  amount: d.price,
                  serviceId: resolvedInstant.id,
                  serviceName: resolvedInstant.name,
                  itemId: d.id,
                  itemType: d.itemType,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: op.headerColor,
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Text('فئة', style: TextStyle(color: Colors.white70, fontSize: 8)),
                          Text('${d.tier}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${d.price.toInt()} ر.ي', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      color: durationBg,
                      width: double.infinity,
                      child: Text(d.days, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: durationText)),
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

  Widget _buildFourGTab(_OperatorSpec op) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سداد باقات يمن فورجي 4G السريعة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fourGDenominations.map((item) {
                  return InkWell(
                    onTap: () {
                      final resolved4g = _resolveServiceForCurrentAction(actionType: 'fourg_pay');
                      _openConfirmPaymentDialog(
                        itemName: item['label'],
                        amount: item['price'],
                        serviceId: resolved4g.id,
                        serviceName: resolved4g.name,
                      );
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                      child: Column(
                        children: [
                          Text(item['label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                          const SizedBox(height: 4),
                          Text(money(item['price']), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.burgundy)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () => _runInquiry('4g'),
          icon: const Icon(Icons.search_rounded),
          label: const Text('استعلام رصيد وصلاحية خط 4G', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        if (fourGInquiryData != null) ...[
          const SizedBox(height: 10),
          PageCard(
            child: Column(
              children: [
                _rowKV('الرصيد المتبقي', fourGInquiryData!['balance'], color: AppColors.emerald, isBold: true),
                const Divider(height: 12),
                _rowKV('باقة الخط', fourGInquiryData!['packagePrice']),
                const Divider(height: 12),
                _rowKV('سرعة الخط', fourGInquiryData!['speed']),
                const Divider(height: 12),
                _rowKV('تاريخ الانتهاء', fourGInquiryData!['expiry'], color: Colors.red, isBold: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNetTab(_OperatorSpec op) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(netTab == 'adsl' ? 'سداد باقات يمن نت ADSL' : 'سداد فواتير الهاتف الثابت', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: yemenNetDenominations.map((item) {
                  return InkWell(
                    onTap: () {
                      final resolvedNet = _resolveServiceForCurrentAction(actionType: netTab == 'adsl' ? 'net_adsl' : 'net_line');
                      _openConfirmPaymentDialog(
                        itemName: item['label'],
                        amount: item['price'],
                        serviceId: resolvedNet.id,
                        serviceName: resolvedNet.name,
                      );
                    },
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7D2FE))),
                      child: Column(
                        children: [
                          Text(item['label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF3730A3))),
                          const SizedBox(height: 4),
                          Text(money(item['price']), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.burgundy)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () => _runInquiry('net'),
          icon: const Icon(Icons.search_rounded),
          label: const Text('استعلام رصيد يمن نت والهاتف الثابت', style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        if (netInquiryData != null) ...[
          const SizedBox(height: 10),
          PageCard(
            child: Column(
              children: [
                _rowKV('الرصيد المتبقي', netInquiryData!['balance'], color: AppColors.emerald, isBold: true),
                const Divider(height: 12),
                _rowKV('الباقة والحد الأدنى', netInquiryData!['packagePrice']),
                const Divider(height: 12),
                _rowKV('السرعة', netInquiryData!['speed']),
                const Divider(height: 12),
                _rowKV('تاريخ الانتهاء', netInquiryData!['expiry'], color: Colors.red, isBold: true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class MultiColorDotsSpinner extends StatefulWidget {
  final double size;
  const MultiColorDotsSpinner({super.key, this.size = 50});

  @override
  State<MultiColorDotsSpinner> createState() => _MultiColorDotsSpinnerState();
}

class _MultiColorDotsSpinnerState extends State<MultiColorDotsSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const List<Color> _colors = [
    Color(0xFFE53935), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFF1E88E5), // Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF43A047), // Green
    Color(0xFFFDD835), // Yellow
    Color(0xFFFB8C00), // Orange
    Color(0xFFD81B60), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(8, (i) {
              final angle = (i * 45) * (math.pi / 180) + (_ctrl.value * 2 * math.pi);
              final radius = widget.size * 0.38;
              final x = radius * math.cos(angle);
              final y = radius * math.sin(angle);
              return Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: widget.size * 0.22,
                  height: widget.size * 0.22,
                  decoration: BoxDecoration(
                    color: _colors[i % _colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
