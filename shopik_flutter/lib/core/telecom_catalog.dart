class TelecomPackageInfo {
  const TelecomPackageInfo({
    required this.id,
    required this.name,
    required this.operatorId,
    required this.category,
    required this.price,
    this.currency = 'YER',
    required this.validity,
    required this.calls,
    required this.internet,
    required this.sms,
    this.lineType = 'دفع مسبق',
    this.code = '',
    this.serviceId = 4,
    this.description = '',
  });

  final String id;
  final String name;
  final String operatorId;
  final String category;
  final num price;
  final String currency;
  final String validity;
  final String calls;
  final String internet;
  final String sms;
  final String lineType;
  final String code;
  final int serviceId;
  final String description;

  static TelecomPackageInfo fromRaw({
    required dynamic raw,
    required String operatorId,
    int defaultServiceId = 4,
  }) {
    final map = raw is Map ? raw : <String, dynamic>{};
    final name = '${map['name'] ?? map['title'] ?? map['package_name'] ?? map['offerName'] ?? ''}'.trim();
    final desc = '${map['description'] ?? map['details'] ?? ''}'.trim();
    final price = num.tryParse('${map['price'] ?? map['amount'] ?? map['cost'] ?? 0}') ?? 0;
    final code = '${map['code'] ?? map['offerId'] ?? map['id'] ?? ''}';
    final parsed = parseTelecomDetails('$name $desc');

    return TelecomPackageInfo(
      id: '${map['id'] ?? (code.isNotEmpty ? code : name)}',
      name: name.isNotEmpty ? name : 'باقة اتصالات معتمدة',
      operatorId: operatorId,
      category: parsed['category'] ?? 'باقات متنوعة',
      price: price > 0 ? price : (parsed['inferredPrice'] ?? 0),
      currency: '${map['currency'] ?? 'YER'}',
      validity: parsed['validity'] ?? '30 يوم',
      calls: parsed['calls'] ?? '—',
      internet: parsed['internet'] ?? '—',
      sms: parsed['sms'] ?? '—',
      lineType: parsed['lineType'] ?? 'دفع مسبق',
      code: code,
      serviceId: defaultServiceId,
      description: desc,
    );
  }

  static Map<String, dynamic> parseTelecomDetails(String text) {
    String validity = '30 يوم';
    String calls = '—';
    String internet = '—';
    String sms = '—';
    String lineType = 'دفع مسبق';
    String category = 'باقات وعروض';
    num inferredPrice = 0;

    // Line type
    if (text.contains('فوترة') || text.contains('بوست بايد') || text.contains('Post')) {
      lineType = 'فوترة';
    } else {
      lineType = 'دفع مسبق';
    }

    // Validity
    if (text.contains('48 ساعة') || text.contains('48 Hours') || text.contains('يومين')) {
      validity = '48 ساعة';
    } else if (text.contains('24 ساعة') || text.contains('يومية') || text.contains('Daily')) {
      validity = '24 ساعة';
    } else if (text.contains('أسبوعية') || text.contains('اسبوعية') || text.contains('7 أيام') || text.contains('Weekly')) {
      validity = '7 أيام';
    } else if (text.contains('10 أيام') || text.contains('10 ايام')) {
      validity = '10 أيام';
    } else if (text.contains('شهرية') || text.contains('شهري') || text.contains('30 يوم') || text.contains('Monthly')) {
      validity = '30 يوم';
    } else if (text.contains('3 أشهر') || text.contains('90 يوم')) {
      validity = '90 يوم';
    }

    // Calls (Minutes)
    final callsMatch = RegExp(r'(\d+)\s*(?:دقيقة|دقيقه|دقائق|دقايق|Min)', caseSensitive: false).firstMatch(text);
    if (callsMatch != null) {
      calls = '${callsMatch.group(1)} دقيقة';
    } else if (text.contains('تواصل')) {
      calls = '600 دقيقة';
    }

    // Internet (GB / MB)
    final gbMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:جيجا|جيجابايت|GB|G\b)', caseSensitive: false).firstMatch(text);
    final mbMatch = RegExp(r'(\d+)\s*(?:ميجا|ميجابايت|MB)', caseSensitive: false).firstMatch(text);
    if (gbMatch != null) {
      internet = '${gbMatch.group(1)} جيجا';
    } else if (mbMatch != null) {
      internet = '${mbMatch.group(1)} ميجا';
    }

    // SMS (Messages)
    final smsMatch = RegExp(r'(\d+)\s*(?:رسالة|رساله|رسائل|SMS)', caseSensitive: false).firstMatch(text);
    if (smsMatch != null) {
      sms = '${smsMatch.group(1)} رسالة';
    }

    // Category
    if (text.contains('مزايا')) {
      category = 'باقات مزايا';
    } else if (text.contains('فولتي') || text.contains('VoLTE')) {
      category = 'باقات فولتي';
    } else if (text.contains('فورجي') || text.contains('4G') || text.contains('سوبر فورجي')) {
      category = 'باقات فورجي 4G';
    } else if (text.contains('يابلاش') || text.contains('سوا') || text.contains('سمارت')) {
      category = 'باقات توفير';
    } else if (text.contains('نت') || text.contains('إنترنت') || text.contains('انترنت')) {
      category = 'باقات الإنترنت';
    }

    return {
      'validity': validity,
      'calls': calls,
      'internet': internet,
      'sms': sms,
      'lineType': lineType,
      'category': category,
      'inferredPrice': inferredPrice,
    };
  }
}

class TelecomCatalog {
  static const List<TelecomPackageInfo> yemenMobilePackages = [
    TelecomPackageInfo(
      id: 'ym_mazaya_week',
      name: 'باقة مزايا الأسبوعية',
      operatorId: 'yemen_mobile',
      category: 'باقات مزايا',
      price: 485,
      validity: '7 أيام',
      calls: '100 دقيقة',
      internet: '90 ميجا',
      sms: '30 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4990001',
      serviceId: 4,
      description: '100 دقيقة اتصال داخل الشبكة + 90 ميجا إنترنت + 30 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_mazaya_month',
      name: 'باقة مزايا الشهرية (350 دقيقة)',
      operatorId: 'yemen_mobile',
      category: 'باقات مزايا',
      price: 1300,
      validity: '30 يوم',
      calls: '350 دقيقة',
      internet: '250 ميجا',
      sms: '150 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4990002',
      serviceId: 4,
      description: '350 دقيقة اتصال + 250 ميجا نت + 150 رسالة صالحة لشهر كامل',
    ),
    TelecomPackageInfo(
      id: 'ym_mazaya_big_month',
      name: 'باقة مزايا الشهرية الكبرى',
      operatorId: 'yemen_mobile',
      category: 'باقات مزايا',
      price: 2600,
      validity: '30 يوم',
      calls: '700 دقيقة',
      internet: '600 ميجا',
      sms: '300 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4990003',
      serviceId: 4,
      description: '700 دقيقة اتصال داخل الشبكة + 600 ميجا نت + 300 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_4g_super_month',
      name: 'باقة سوبر 4G الشهرية (2 جيجا)',
      operatorId: 'yemen_mobile',
      category: 'باقات فورجي 4G',
      price: 1400,
      validity: '30 يوم',
      calls: '250 دقيقة',
      internet: '2 جيجا',
      sms: '250 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4820',
      serviceId: 4,
      description: '2 جيجابايت إنترنت 4G فائق السرعة + 250 دقيقة + 250 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_4g_mazaya_4gb',
      name: 'باقة مزايا 4G الشهرية (4 جيجا)',
      operatorId: 'yemen_mobile',
      category: 'باقات فورجي 4G',
      price: 2400,
      validity: '30 يوم',
      calls: '400 دقيقة',
      internet: '4 جيجا',
      sms: '400 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4821',
      serviceId: 4,
      description: '4 جيجابايت نت فورجي + 400 دقيقة اتصال + 400 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_4g_tawasol_month',
      name: 'باقة تواصل فورجي الشهرية',
      operatorId: 'yemen_mobile',
      category: 'باقات فورجي 4G',
      price: 2100,
      validity: '30 يوم',
      calls: '600 دقيقة',
      internet: '1 جيجا',
      sms: '600 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4822',
      serviceId: 4,
      description: '600 دقيقة اتصال تواصل + 1 جيجابايت نت + 600 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_volte_48h',
      name: 'باقة مزايا VoLTE (48 ساعة)',
      operatorId: 'yemen_mobile',
      category: 'باقات فولتي',
      price: 450,
      validity: '48 ساعة',
      calls: '150 دقيقة',
      internet: '600 ميجا',
      sms: '100 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4990004',
      serviceId: 4,
      description: '150 دقيقة تقنية VoLTE عالية الدقة + 600 ميجا نت لمدة يومين',
    ),
    TelecomPackageInfo(
      id: 'ym_volte_month',
      name: 'باقة مزايا VoLTE الشهرية',
      operatorId: 'yemen_mobile',
      category: 'باقات فولتي',
      price: 2300,
      validity: '30 يوم',
      calls: '350 دقيقة',
      internet: '3 جيجا',
      sms: '250 رسالة',
      lineType: 'دفع مسبق',
      code: 'A4990006',
      serviceId: 4,
      description: '350 دقيقة فولتي نقية + 3 جيجا فورجي + 250 رسالة',
    ),
    TelecomPackageInfo(
      id: 'ym_net_3gb',
      name: 'باقة 3 جيجا إنترنت شهرية',
      operatorId: 'yemen_mobile',
      category: 'باقات الإنترنت',
      price: 2000,
      validity: '30 يوم',
      calls: '—',
      internet: '3 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'A4990008',
      serviceId: 4,
      description: '3 جيجابايت صافية مخصصة لتصفح الإنترنت وتطبيقات التواصل',
    ),
  ];

  static const List<TelecomPackageInfo> youPackages = [
    TelecomPackageInfo(
      id: 'you_smart_week',
      name: 'باقة يو سمارت الأسبوعية',
      operatorId: 'you',
      category: 'باقات توفير',
      price: 500,
      validity: '7 أيام',
      calls: '100 دقيقة',
      internet: '150 ميجا',
      sms: '100 رسالة',
      lineType: 'دفع مسبق',
      code: 'YOU_SMART_W',
      serviceId: 15,
      description: '100 دقيقة داخل شبكة يو + 150 ميجا + 100 رسالة',
    ),
    TelecomPackageInfo(
      id: 'you_smart_month',
      name: 'باقة يو سمارت الشهرية',
      operatorId: 'you',
      category: 'باقات توفير',
      price: 1500,
      validity: '30 يوم',
      calls: '350 دقيقة',
      internet: '500 ميجا',
      sms: '350 رسالة',
      lineType: 'دفع مسبق',
      code: 'YOU_SMART_M',
      serviceId: 15,
      description: '350 دقيقة اتصال + 500 ميجا إنترنت + 350 رسالة',
    ),
    TelecomPackageInfo(
      id: 'you_4g_super',
      name: 'باقة يو 4G سوبر الشهرية (5 جيجا)',
      operatorId: 'you',
      category: 'باقات فورجي 4G',
      price: 2500,
      validity: '30 يوم',
      calls: '250 دقيقة',
      internet: '5 جيجا',
      sms: '250 رسالة',
      lineType: 'دفع مسبق',
      code: 'YOU_4G_5GB',
      serviceId: 15,
      description: '5 جيجابايت نت فورجي سريع + 250 دقيقة اتصال + 250 رسالة',
    ),
    TelecomPackageInfo(
      id: 'you_net_10gb',
      name: 'باقة يو نت الشهرية (10 جيجا)',
      operatorId: 'you',
      category: 'باقات الإنترنت',
      price: 4500,
      validity: '30 يوم',
      calls: '—',
      internet: '10 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'YOU_NET_10GB',
      serviceId: 15,
      description: '10 جيجابايت إنترنت شهري مخصصة لشرائح بيانات وهواتف 4G',
    ),
  ];

  static const List<TelecomPackageInfo> sabafonPackages = [
    TelecomPackageInfo(
      id: 'saba_yabalash_week',
      name: 'باقة يابلاش الأسبوعية',
      operatorId: 'sabafon',
      category: 'باقات توفير',
      price: 450,
      validity: '7 أيام',
      calls: '120 دقيقة',
      internet: '120 ميجا',
      sms: '120 رسالة',
      lineType: 'دفع مسبق',
      code: 'SABA_YB_W',
      serviceId: 9,
      description: '120 دقيقة سبأفون + 120 ميجا نت + 120 رسالة صالحة 7 أيام',
    ),
    TelecomPackageInfo(
      id: 'saba_yabalash_month',
      name: 'باقة يابلاش الشهرية (300 دقيقة)',
      operatorId: 'sabafon',
      category: 'باقات توفير',
      price: 1350,
      validity: '30 يوم',
      calls: '300 دقيقة',
      internet: '300 ميجا',
      sms: '300 رسالة',
      lineType: 'دفع مسبق',
      code: 'SABA_YB_M',
      serviceId: 9,
      description: '300 دقيقة اتصال داخل سبأفون + 300 ميجا نت + 300 رسالة',
    ),
    TelecomPackageInfo(
      id: 'saba_4g_super',
      name: 'سبأفون 4G سوبر (6 جيجا)',
      operatorId: 'sabafon',
      category: 'باقات فورجي 4G',
      price: 2600,
      validity: '30 يوم',
      calls: '200 دقيقة',
      internet: '6 جيجا',
      sms: '200 رسالة',
      lineType: 'دفع مسبق',
      code: 'SABA_4G_6GB',
      serviceId: 9,
      description: '6 جيجابايت إنترنت 4G فائق + 200 دقيقة اتصال + 200 رسالة',
    ),
  ];

  static const List<TelecomPackageInfo> yemen4gPackages = [
    TelecomPackageInfo(
      id: 'y4g_12gb',
      name: 'باقة يمن فورجي الأساسية (12 جيجا)',
      operatorId: 'yemen_4g',
      category: 'باقات فورجي 4G',
      price: 2400,
      validity: '30 يوم',
      calls: '—',
      internet: '12 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'Y4G_12GB',
      serviceId: 20,
      description: '12 جيجابايت إنترنت مودم يمن فورجي المنزلي بسرعة تصل 25Mbps',
    ),
    TelecomPackageInfo(
      id: 'y4g_25gb',
      name: 'باقة يمن فورجي الشهرية (25 جيجا)',
      operatorId: 'yemen_4g',
      category: 'باقات فورجي 4G',
      price: 4600,
      validity: '30 يوم',
      calls: '—',
      internet: '25 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'Y4G_25GB',
      serviceId: 20,
      description: '25 جيجابايت إنترنت مودم يمن فورجي المنزلي بسرعة كاملة',
    ),
    TelecomPackageInfo(
      id: 'y4g_60gb',
      name: 'باقة يمن فورجي الذهبية (60 جيجا)',
      operatorId: 'yemen_4g',
      category: 'باقات فورجي 4G',
      price: 8000,
      validity: '30 يوم',
      calls: '—',
      internet: '60 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'Y4G_60GB',
      serviceId: 20,
      description: '60 جيجابايت للمنازل والمكاتب للاستخدام المفتوح بسرعة غير محدودة',
    ),
    TelecomPackageInfo(
      id: 'y4g_130gb',
      name: 'باقة يمن فورجي المفتوحة (130 جيجا)',
      operatorId: 'yemen_4g',
      category: 'باقات فورجي 4G',
      price: 16000,
      validity: '30 يوم',
      calls: '—',
      internet: '130 جيجا',
      sms: '—',
      lineType: 'دفع مسبق',
      code: 'Y4G_130GB',
      serviceId: 20,
      description: '130 جيجابايت فائقة للمكاتب والشركات والتحميل المستمر',
    ),
  ];

  static List<TelecomPackageInfo> getPackagesForOperator(String opId) {
    switch (opId) {
      case 'yemen_mobile':
        return yemenMobilePackages;
      case 'you':
        return youPackages;
      case 'sabafon':
        return sabafonPackages;
      case 'yemen_4g':
        return yemen4gPackages;
      default:
        return yemenMobilePackages;
    }
  }
}
