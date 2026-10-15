import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _category = 'الكل';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    final app = context.read<AppController>();
    try {
      final data = await app.api.serviceCatalog();
      final raw = data['categories'];
      if (raw is! List) throw ApiException(200, 'صيغة كتالوج الخدمات غير صحيحة.');
      app.serviceCatalogRoots = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      app.notifyStateChanged();
      if (app.serviceCatalogRoots.isEmpty) _error = 'لا توجد خدمات مفعلة في الخادم حاليًا.';
    } catch (e) {
      _error = 'تعذر تحميل الخدمات من الخادم: $e';
    }
    try { await app.refreshWalletAndReports(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _services(List<Map<String, dynamic>> roots) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    void walk(dynamic node, String main, String inherited) {
      if (node is! Map) return;
      final data = Map<String, dynamic>.from(node);
      final name = '${data['name'] ?? ''}'.trim();
      final category = name.isEmpty ? inherited : name;
      final raw = data['services'];
      if (raw is List) {
        for (final row in raw.whereType<Map>()) {
          final service = Map<String, dynamic>.from(row);
          final id = '${service['id'] ?? ''}';
          if (id.trim().isEmpty || !seen.add(id)) continue;
          service['_category'] = category;
          service['_main_category'] = main;
          result.add(service);
        }
      }
      final children = data['children'];
      if (children is List) {
        for (final child in children) { walk(child, main, category); }
      }
      final categories = data['categories'];
      if (categories is List) {
        for (final child in categories) { walk(child, main, category); }
      }
    }

    for (final root in roots) {
      final slug = '${root['slug'] ?? ''}'.toLowerCase();
      final name = '${root['name'] ?? ''}';
      if (slug == 'payments' || slug == 'payment' || name.contains('التسديد') || name.contains('السداد')) {
        walk(root, name, name);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final services = _services(app.serviceCatalogRoots);
    final categories = <String>{'الكل', ...services.map((s) => '${s['_category'] ?? ''}').where((s) => s.trim().isNotEmpty)}.toList();
    if (!categories.contains(_category)) _category = 'الكل';
    final q = _query.trim().toLowerCase();
    final visible = services.where((s) {
      if (_category != 'الكل' && '${s['_category'] ?? ''}' != _category) return false;
      if (q.isEmpty) return true;
      final rawItems = s['items'];
      final itemNames = rawItems is List ? rawItems.whereType<Map>().map((x) => '${x['name'] ?? ''}').join(' ') : '';
      return '${s['name'] ?? ''} ${s['code'] ?? ''} ${s['description'] ?? ''} ${s['_category'] ?? ''} $itemNames'.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('مركز السداد', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تحديث الخدمات',
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.burgundy,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9D2445), Color(0xFF78142F), Color(0xFF4F1026)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: const [
                  BoxShadow(color: Color(0x2478142F), blurRadius: 15, offset: Offset(0, 6)),
                ],
              ),
              child: const Row(children: [
                _HeroIcon(),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مركز السداد الموحد', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('الخدمات والنتائج من الخادم مباشرة', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.burgundy),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('الرصيد المتاح من الخادم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
                  IconButton(
                    tooltip: 'تحديث الرصيد',
                    onPressed: () async {
                      try { await app.refreshWalletAndReports(); }
                      catch (e) { if (mounted) showAppToast(context, 'تعذر تحديث الرصيد: $e', isError: true); }
                    },
                    icon: const Icon(Icons.sync_rounded, color: AppColors.burgundy),
                  ),
                ]),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(money(app.walletBalance), style: const TextStyle(fontSize: 27, color: AppColors.burgundy, fontWeight: FontWeight.w900)),
                ),
                if (app.user?.phone.isNotEmpty == true)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${app.user!.name} • ${app.user!.phone}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ),
              ]),
            ),
            const SizedBox(height: 17),
            Row(children: [
              const Expanded(child: Text('خدمات السداد المتاحة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
              Text('${services.length} خدمة', style: const TextStyle(color: AppColors.burgundy, fontSize: 10, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 9),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن شركة أو خدمة',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() => _query = ''); },
                  icon: const Icon(Icons.close),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            if (categories.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 39,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, i) {
                    final name = categories[i];
                    final active = name == _category;
                    return ChoiceChip(
                      label: Text(name),
                      selected: active,
                      onSelected: (_) => setState(() => _category = name),
                      showCheckmark: false,
                      selectedColor: AppColors.burgundy,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: active ? AppColors.burgundy : AppColors.border),
                      labelStyle: TextStyle(color: active ? Colors.white : AppColors.dark, fontSize: 10.5, fontWeight: FontWeight.w800),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (services.isEmpty && _loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.burgundy)))
            else if (services.isEmpty)
              _EmptyCatalog(message: _error ?? 'لم يرجع الخادم خدمات سداد. أعد المحاولة لاحقًا.', onRefresh: _refresh)
            else if (visible.isEmpty)
              const Padding(padding: EdgeInsets.all(25), child: EmptyState(text: 'لا توجد خدمات مطابقة للبحث.', icon: Icons.search_off_rounded))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: .93),
                itemBuilder: (_, i) => _ServiceCard(
                  service: visible[i],
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ServiceForm(app: app, service: visible[i], initialPhone: app.user?.phone ?? ''),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFBFDBFE))),
              child: const Text(
                'لا يعتبر الطلب ناجحًا إلا بعد تأكيد الحالة من الخادم. إذا استلم الخادم الطلب ولم تصل النتيجة خلال 40 ثانية، سيظهر المرجع ورسالة انتظار؛ لا تكرر إرسال العملية.',
                style: TextStyle(color: Color(0xFF1E40AF), fontSize: 10.5, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(16)),
    child: const Icon(Icons.bolt_rounded, color: Color(0xFFFFE4A3), size: 31),
  );
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.message, required this.onRefresh});
  final String message;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
      const SizedBox(height: 9),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.5)),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
    ]),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});
  final Map<String, dynamic> service;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final name = '${service['name'] ?? 'خدمة'}';
    final kind = '${service['service_kind'] ?? ''}'.toLowerCase();
    final paid = service['requires_balance'] == true;
    final rawItems = service['items'];
    final count = rawItems is List ? rawItems.length : 0;
    final color = _serviceColor(name);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(12)), child: Icon(_serviceIcon(name, kind), color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(color: paid ? const Color(0xFFFFF4D8) : const Color(0xFFE8F5EE), borderRadius: BorderRadius.circular(8)),
                child: Text(paid ? 'مدفوع' : 'استعلام', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: paid ? const Color(0xFF966100) : const Color(0xFF087443))),
              ),
            ]),
            const Spacer(),
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(count > 0 ? '$count خيار من الخادم' : '${service['_category'] ?? 'إدخال البيانات'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: Text('فتح الخدمة', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900))), Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: color)]),
          ]),
        ),
      ),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  const _ServiceForm({required this.app, required this.service, required this.initialPhone});
  final AppController app;
  final Map<String, dynamic> service;
  final String initialPhone;
  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _values = {};
  final Map<String, String?> _choices = {};
  Map<String, dynamic>? _item;
  bool _busy = false;
  Map<String, dynamic>? _pendingTransaction;
  String? _pendingKey;
  String? _lastPersistedStatus;
  bool _blockedAfterAmbiguousSubmit = false;
  int _elapsed = 0;
  String _progress = 'جاري إرسال الطلب إلى الخادم...';
  Timer? _timer;

  String get _kind => '${widget.service['service_kind'] ?? ''}'.toLowerCase();
  String get _pricing => '${widget.service['pricing_mode'] ?? ''}'.toLowerCase();
  List<Map<String, dynamic>> get _fields => widget.service['fields'] is List
      ? (widget.service['fields'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  List<Map<String, dynamic>> get _items => widget.service['items'] is List
      ? (widget.service['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  bool get _itemRequired => _pricing == 'item' && widget.service['requires_balance'] == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreUnresolvedTransaction();
    });
    for (final f in _fields) {
      final key = '${f['key'] ?? ''}'.trim();
      if (key.isEmpty) continue;
      final defaultValue = '${f['default'] ?? ''}';
      final isPhone = ['mobile', 'phone'].contains(key.toLowerCase());
      _values[key] = TextEditingController(text: defaultValue.isNotEmpty ? defaultValue : (isPhone ? widget.initialPhone : ''));
      _choices[key] = null;
    }
    if (_items.length == 1 && _available(_items.first)) _item = _items.first;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _values.values) { c.dispose(); }
    super.dispose();
  }

  bool _available(Map<String, dynamic> item) {
    final a = item['availability'];
    if (a is Map) {
      final v = a['available'];
      if (v == false || '$v'.toLowerCase() == 'false' || '$v' == '0') return false;
    }
    return item['is_active'] != false;
  }

  String? _validate(Map<String, dynamic> f, String? raw) {
    final value = raw?.trim() ?? '';
    if (f['required'] == true && value.isEmpty) return 'هذا الحقل مطلوب';
    final key = '${f['key'] ?? ''}'.toLowerCase();
    final type = '${f['type'] ?? ''}'.toLowerCase();
    if (value.isNotEmpty && (key == 'amount' || ['number','integer','decimal','amount','float'].contains(type))) {
      final n = num.tryParse(value);
      if (n == null) return 'أدخل رقمًا صحيحًا';
      final min = num.tryParse('${widget.service['min_amount'] ?? ''}');
      final max = num.tryParse('${widget.service['max_amount'] ?? ''}');
      if (key == 'amount' && min != null && n < min) return 'أقل مبلغ هو $min';
      if (key == 'amount' && max != null && n > max) return 'أعلى مبلغ هو $max';
    }
    return null;
  }

  Map<String, dynamic> _payload() {
    final payload = <String, dynamic>{};
    for (final f in _fields) {
      final key = '${f['key'] ?? ''}'.trim();
      if (key.isEmpty) continue;
      final opts = _options(f);
      final value = opts.isEmpty ? (_values[key]?.text.trim() ?? '') : (_choices[key] ?? '');
      if (value.isEmpty) continue;
      payload[key] = key.toLowerCase() == 'amount' ? (num.tryParse(value) ?? value) : value;
    }
    return payload;
  }

  String _requestFingerprint(int serviceId, Map<String, dynamic> payload) {
    final keys = payload.keys.toList()..sort();
    final canonical = <String, dynamic>{
      'user_id': widget.app.user?.id ?? 0,
      'service_id': serviceId,
      'item_id': _item?['id'],
      'item_type': _item?['type'],
      'payload': <String, dynamic>{for (final key in keys) key: payload[key]},
    };
    // Stable non-reversible fingerprint: neither phone numbers nor secrets are
    // stored in the preference key.
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(jsonEncode(canonical))) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'shopik_pending_${widget.app.user?.id ?? 0}_${serviceId}_${hash.toRadixString(16)}';
  }

  String get _activeTransactionPreferenceKey =>
      'shopik_active_transaction_${widget.app.user?.id ?? 0}';

  String get _ambiguousTransactionPreferenceKey =>
      'shopik_ambiguous_transaction_${widget.app.user?.id ?? 0}';

  Future<void> _restoreUnresolvedTransaction() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final activeRaw = preferences.getString(_activeTransactionPreferenceKey);
    if (activeRaw != null && activeRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(activeRaw);
        if (decoded is Map && decoded['transaction'] is Map) {
          final active = Map<String, dynamic>.from(decoded);
          final requestKey = '${active['request_key'] ?? ''}'.trim();
          final tx = Map<String, dynamic>.from(active['transaction'] as Map);
          final id = '${tx['id'] ?? ''}'.trim();
          final status = _statusOf(tx);
          if (requestKey.isNotEmpty && id.isNotEmpty && !_isTerminal(status)) {
            setState(() {
              _pendingKey = requestKey;
              _pendingTransaction = tx;
            });
            return;
          }
          if (requestKey.isNotEmpty && id.isNotEmpty && _isTerminal(status)) {
            await _clearPersistedTransaction(requestKey);
          }
        }
      } catch (_) {
        await preferences.remove(_activeTransactionPreferenceKey);
      }
    }

    final ambiguousKey = preferences.getString(_ambiguousTransactionPreferenceKey);
    if (ambiguousKey != null && ambiguousKey.isNotEmpty && mounted) {
      setState(() {
        _pendingKey = ambiguousKey;
        _blockedAfterAmbiguousSubmit = true;
      });
    }
  }

  Map<String, dynamic> _transactionForLocalRecovery(Map<String, dynamic> tx) {
    const safeKeys = {
      'id', 'service', 'service_kind', 'status', 'amount', 'currency',
      'provider_transid', 'provider_transaction_id', 'error_code',
      'error_message', 'created_at', 'completed_at',
    };
    return <String, dynamic>{
      for (final entry in tx.entries)
        if (safeKeys.contains(entry.key)) entry.key: entry.value,
    };
  }

  Future<void> _persistPendingTransaction(String? key, Map<String, dynamic> tx) async {
    if (key == null || key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final safeTransaction = _transactionForLocalRecovery(tx);
      await prefs.setString(key, jsonEncode(safeTransaction));
      await prefs.setString(_activeTransactionPreferenceKey, jsonEncode({
        'request_key': key,
        'transaction': safeTransaction,
      }));
    } catch (_) {
      // Persistence is a recovery aid; server state remains authoritative.
    }
  }

  Future<void> _clearPersistedTransaction(
    String? key, {
    bool clearIdempotencyKey = true,
  }) async {
    if (key == null || key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_ambiguous');
      if (clearIdempotencyKey) {
        await prefs.remove('${key}_idempotency');
      }

      final activeRaw = prefs.getString(_activeTransactionPreferenceKey);
      if (activeRaw != null) {
        try {
          final active = jsonDecode(activeRaw);
          if (active is Map && '${active['request_key'] ?? ''}' == key) {
            await prefs.remove(_activeTransactionPreferenceKey);
          }
        } catch (_) {
          await prefs.remove(_activeTransactionPreferenceKey);
        }
      }
      if (prefs.getString(_ambiguousTransactionPreferenceKey) == key) {
        await prefs.remove(_ambiguousTransactionPreferenceKey);
      }
    } catch (_) {}
  }

  Future<String> _idempotencyKeyFor(String requestKey) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = '${requestKey}_idempotency';
    final existing = prefs.getString(storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // One unique key per attempted checkout. It is reused only while this exact
    // attempt is unresolved, allowing the backend to return its existing UUID
    // after a network timeout instead of making a duplicate transaction.
    final userId = widget.app.user?.id ?? 0;
    final fingerprint = requestKey.split('_').last;
    final created = 'pay-$userId-${DateTime.now().microsecondsSinceEpoch}-$fingerprint';
    await prefs.setString(storageKey, created);
    return created;
  }

  Future<void> _clearAmbiguousMarker(String? key) async {
    if (key == null || key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${key}_ambiguous');
      if (prefs.getString(_ambiguousTransactionPreferenceKey) == key) {
        await prefs.remove(_ambiguousTransactionPreferenceKey);
      }
    } catch (_) {}
  }

  Future<void> _markAmbiguousRequest(String? key) async {
    if (key == null || key.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${key}_ambiguous', true);
      await prefs.setString(_ambiguousTransactionPreferenceKey, key);
    } catch (_) {}
  }

  Future<void> _allowRetryAfterManualCheck() async {
    if (_busy || !_blockedAfterAmbiguousSubmit) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(child: Text('إعادة المحاولة بعد التحقق')),
        ]),
        content: const Text(
          'قد يكون الخادم قد استلم الطلب السابق، لكن التطبيق لم يحصل على رقم مرجع قابل للفحص. راجع سجل العمليات لدى الخادم وتأكد من عدم وجود عملية منفذة قبل المتابعة. إعادة المحاولة قد تؤدي إلى تكرار السداد.',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
            child: const Text('تحققت وأريد المتابعة'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await _clearPersistedTransaction(_pendingKey, clearIdempotencyKey: false);
    setState(() => _blockedAfterAmbiguousSubmit = false);
  }

  Future<void> _submit() async {
    if (_pendingTransaction != null) {
      await _reviewPendingTransaction();
      return;
    }
    if (_blockedAfterAmbiguousSubmit) {
      showAppToast(context, 'تعذر التحقق من الطلب السابق. افحص سجل العمليات قبل إنشاء طلب جديد.', isError: true);
      return;
    }
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    if (_itemRequired && _item == null) {
      showAppToast(context, 'اختر الباقة أو الفئة المطلوبة أولًا.', isError: true);
      return;
    }
    final payload = _payload();
    final serviceId = int.tryParse('${widget.service['id'] ?? ''}');
    if (serviceId == null || serviceId <= 0) {
      showAppToast(context, 'معرّف الخدمة غير صالح في كتالوج الخادم.', isError: true);
      return;
    }

    final requestKey = _requestFingerprint(serviceId, payload);
    _pendingKey = requestKey;
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final activeRaw = preferences.getString(_activeTransactionPreferenceKey);
    if (activeRaw != null && activeRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(activeRaw);
        if (decoded is Map && decoded['transaction'] is Map) {
          final active = Map<String, dynamic>.from(decoded);
          final activeKey = '${active['request_key'] ?? ''}'.trim();
          final activeTx = Map<String, dynamic>.from(active['transaction'] as Map);
          final activeId = '${activeTx['id'] ?? ''}'.trim();
          final activeStatus = _statusOf(activeTx);
          if (activeKey.isNotEmpty && activeId.isNotEmpty && !_isTerminal(activeStatus)) {
            setState(() {
              _pendingKey = activeKey;
              _pendingTransaction = activeTx;
            });
            await _reviewPendingTransaction();
            return;
          }
          if (activeKey.isNotEmpty && activeId.isNotEmpty && _isTerminal(activeStatus)) {
            await _clearPersistedTransaction(activeKey);
          }
        }
      } catch (_) {
        await preferences.remove(_activeTransactionPreferenceKey);
      }
    }

    final globalAmbiguousKey = preferences.getString(_ambiguousTransactionPreferenceKey);
    if (globalAmbiguousKey != null && globalAmbiguousKey.isNotEmpty) {
      _pendingKey = globalAmbiguousKey;
      setState(() => _blockedAfterAmbiguousSubmit = true);
      return;
    }

    final storedTransaction = preferences.getString(requestKey);
    if (storedTransaction != null && storedTransaction.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedTransaction);
        if (decoded is Map) {
          final previous = Map<String, dynamic>.from(decoded);
          if ('${previous['id'] ?? ''}'.trim().isNotEmpty) {
            setState(() => _pendingTransaction = previous);
            await _reviewPendingTransaction();
            return;
          }
        }
      } catch (_) {
        await preferences.remove(requestKey);
      }
    }
    final ambiguous = preferences.getBool('${requestKey}_ambiguous') ?? false;
    if (ambiguous) {
      setState(() => _blockedAfterAmbiguousSubmit = true);
      return;
    }

    final selectedName = '${_item?['name'] ?? ''}';
    final price = _item == null ? null : num.tryParse('${_item!['price'] ?? ''}');
    final summary = _item == null
        ? 'الخدمة: ${widget.service['name']}\n${payload['amount'] != null ? 'المبلغ المدخل: ${payload['amount']} ر.ي\n' : ''}سيتم التحقق من البيانات والرصيد من الخادم.'
        : 'الخدمة: ${widget.service['name']}\nالخيار: $selectedName\nالسعر المعروض: ${price ?? 'يحدده الخادم'}\n\nالسعر والحجز النهائيان يعتمدهما الخادم.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الطلب', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(summary, style: const TextStyle(fontSize: 12, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy), child: const Text('تأكيد وإرسال')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final idempotencyKey = await _idempotencyKeyFor(requestKey);
    await _markAmbiguousRequest(requestKey);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _elapsed = 0;
      _lastPersistedStatus = null;
      _progress = 'جاري إرسال الطلب إلى الخادم...';
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted && _busy) setState(() => _elapsed++); });
    try {
      final transaction = await widget.app.requestService(
        serviceId: serviceId,
        payload: payload,
        itemType: _item == null ? null : '${_item!['type'] ?? ''}',
        itemId: _item == null ? null : int.tryParse('${_item!['id'] ?? ''}'),
        idempotencyKey: idempotencyKey,
        maxWait: const Duration(seconds: 40),
        onProgress: (tx) {
          if (!mounted) return;
          final currentStatus = '${tx['status'] ?? ''}'.trim().toLowerCase();
          setState(() => _progress = _progressText(currentStatus));
          final txId = '${tx['id'] ?? ''}'.trim();
          if (txId.isNotEmpty && _lastPersistedStatus == null) {
            _lastPersistedStatus = currentStatus;
            _persistPendingTransaction(requestKey, tx);
          }
        },
      );
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _busy = false);
      if ('${transaction['id'] ?? ''}'.trim().isEmpty) {
        await _markAmbiguousRequest(requestKey);
        if (mounted) setState(() => _blockedAfterAmbiguousSubmit = true);
        await _unknownReference();
        return;
      }
      await _persistPendingTransaction(requestKey, transaction);
      await _clearAmbiguousMarker(requestKey);
      final checked = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TransactionResultDialog(app: widget.app, transaction: transaction),
      );
      final finalTx = checked ?? transaction;
      final status = _statusOf(finalTx);
      try { await widget.app.refreshWalletAndReports(); } catch (_) {}
      if (['success','completed','done','executed'].contains(status)) {
        await _clearPersistedTransaction(requestKey);
        if (mounted) {
          setState(() => _pendingTransaction = null);
          Navigator.of(context).pop();
        }
      } else if (['failed','error','rejected','refunded'].contains(status)) {
        await _clearPersistedTransaction(requestKey);
        if (mounted) setState(() => _pendingTransaction = null);
      } else {
        // Keep the reference locally and in preferences to prevent another
        // request from being created if the sheet or app is reopened.
        await _persistPendingTransaction(requestKey, finalTx);
        if (mounted) setState(() => _pendingTransaction = Map<String, dynamic>.from(finalTx));
      }
    } catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _busy = false);
      final reject = e is ApiException && const {400, 401, 403, 404, 405, 422}.contains(e.statusCode);
      if (!reject) {
        // The service POST may have reached the backend even if the response timed out.
        // Persist an ambiguity marker because no transaction UUID was returned.
        await _markAmbiguousRequest(requestKey);
        if (mounted) setState(() => _blockedAfterAmbiguousSubmit = true);
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(reject ? 'لم يقبل الخادم الطلب' : 'تعذر تأكيد استلام الطلب'),
          content: Text(reject
            ? e.toString()
            : 'انقطع الاتصال قبل استلام تأكيد واضح من الخادم. لم نعلن نجاح العملية ولم نعد إرسالها تلقائيًا. افحص سجل العمليات قبل إعادة المحاولة.\n\nالتفاصيل: $e',
            style: const TextStyle(fontSize: 12, height: 1.55)),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا'))],
        ),
      );
    } finally {
      _timer?.cancel();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewPendingTransaction() async {
    final pending = _pendingTransaction;
    if (_busy || pending == null) return;
    final reviewed = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TransactionResultDialog(app: widget.app, transaction: pending),
    );
    final transaction = reviewed ?? pending;
    if (!mounted) return;
    final status = _statusOf(transaction);
    if (['success','completed','done','executed'].contains(status)) {
      await _clearPersistedTransaction(_pendingKey);
      setState(() => _pendingTransaction = null);
      try { await widget.app.refreshWalletAndReports(); } catch (_) {}
      if (mounted) Navigator.of(context).pop();
    } else if (['failed','error','rejected','refunded'].contains(status)) {
      await _clearPersistedTransaction(_pendingKey);
      setState(() => _pendingTransaction = null);
      try { await widget.app.refreshWalletAndReports(); } catch (_) {}
    } else {
      await _persistPendingTransaction(_pendingKey, transaction);
      setState(() => _pendingTransaction = Map<String, dynamic>.from(transaction));
    }
  }

  Future<void> _unknownReference() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('لم يصل مرجع العملية'),
        content: const Text('لم يُرجع الخادم رقمًا يمكن فحصه. لا يمكن اعتبار العملية ناجحة، ولا ينبغي إعادة إرسالها قبل مراجعة سجل العمليات.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا'))],
      ),
    );
  }

  String _progressText(String status) {
    switch (status.toLowerCase().trim()) {
      case 'accepted': return 'استلم الخادم الطلب؛ نتحقق من نتيجة التنفيذ...';
      case 'queued': return 'الطلب في قائمة التنفيذ لدى الخادم...';
      case 'processing': return 'جاري تنفيذ الطلب لدى المزود...';
      case 'pending_provider': return 'تم إرسال الطلب للمزود؛ ننتظر تأكيد النتيجة...';
      case 'success': return 'وصل تأكيد نجاح العملية من الخادم.';
      case 'failed': return 'أعاد الخادم حالة فشل؛ جارٍ عرض التفاصيل...';
      case 'refunded': return 'أعاد الخادم حالة استرداد الرصيد...';
      case 'manual_review': return 'العملية تحتاج مراجعة تشغيلية؛ لا تكرر السداد.';
      default: return 'ننتظر حالة مؤكدة من الخادم...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final kind = _kind;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .91),
        decoration: const BoxDecoration(color: Color(0xFFF7F8FC), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 9),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(5))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: AppColors.burgundy, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${widget.service['name'] ?? 'خدمة السداد'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                Text(widget.service['requires_balance'] == true ? 'تنفيذ مدفوع عبر الخادم' : 'استعلام أو خدمة غير مدفوعة', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
              ])),
              IconButton(onPressed: _busy ? null : () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(14), children: [
                if ('${widget.service['description'] ?? ''}'.trim().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${widget.service['description']}', style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.5))),
                if (items.isNotEmpty) ...[
                  const Text('اختر الباقة أو الفئة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  for (final item in items) _itemCard(item),
                  const SizedBox(height: 10),
                ],
                for (final field in _fields) ...[
                  _fieldWidget(field),
                  const SizedBox(height: 9),
                ],
                if (_fields.isEmpty && items.isEmpty)
                  const Text('لا توجد حقول معرفة لهذه الخدمة في كتالوج الخادم. لم يتم تخمين حقول أو معرف خدمة بديل.', style: TextStyle(color: Color(0xFF92400E), fontSize: 11, height: 1.5)),
                if (_pendingTransaction != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFFDE3A7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 19),
                          SizedBox(width: 7),
                          Expanded(child: Text('يوجد طلب سابق لم تُحسم نتيجته', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF92400E)))),
                        ]),
                        const SizedBox(height: 5),
                        Text(
                          'المرجع: ${_pendingTransaction!['id'] ?? 'غير متوفر'}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'لن نرسل طلبًا ماليًا جديدًا من هذه الشاشة. استخدم زر فحص العملية السابقة حتى تصل حالة نهائية من الخادم.',
                          style: TextStyle(fontSize: 10, height: 1.45, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_blockedAfterAmbiguousSubmit) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 19),
                          SizedBox(width: 7),
                          Expanded(child: Text('يجب فحص الطلب السابق أولًا', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF9F1239)))),
                        ]),
                        const SizedBox(height: 5),
                        const Text(
                          'لم يصل تأكيد أو مرجع يمكن فحصه بعد الإرسال. قد يكون الخادم استلم الطلب بالفعل؛ لذلك عُطلت إعادة الإرسال لتقليل احتمال تكرار الخصم. افحص سجل العمليات لدى الخادم.',
                          style: TextStyle(fontSize: 10.5, height: 1.5, color: Color(0xFF9F1239), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _allowRetryAfterManualCheck,
                            icon: const Icon(Icons.fact_check_outlined, size: 17),
                            label: const Text('تحققت من السجل وأريد المتابعة'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF9F1239)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: Column(children: [
                      const LinearProgressIndicator(color: AppColors.blue),
                      const SizedBox(height: 9),
                      Text(_progress, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('مدة التحقق: $_elapsed / 40 ثانية', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 47,
                  child: FilledButton.icon(
                    onPressed: _busy || _blockedAfterAmbiguousSubmit
                      ? null
                      : (_pendingTransaction != null ? _reviewPendingTransaction : _submit),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy),
                    icon: _busy
                      ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(kind == 'query' || kind == 'catalog' ? Icons.manage_search_rounded : Icons.lock_clock_rounded),
                    label: Text(
                      _busy
                          ? 'جاري انتظار نتيجة الخادم...'
                          : _blockedAfterAmbiguousSubmit
                              ? 'تحقق من سجل العمليات أولًا'
                              : _pendingTransaction != null
                                  ? 'فحص العملية السابقة'
                                  : (kind == 'query' || kind == 'catalog' ? 'إرسال الاستعلام' : 'تأكيد السداد'),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('ينتظر التطبيق نتيجة الخادم حتى 40 ثانية. إذا بقي الطلب قيد المعالجة، سيظهر المرجع ورسالة انتظار ولن يعرض نجاحًا غير مؤكد.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.muted, height: 1.5)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final available = _available(item);
    final selected = _item?['id'] == item['id'] && _item?['type'] == item['type'];
    final price = num.tryParse('${item['price'] ?? item['sale_price'] ?? ''}');
    return Opacity(
      opacity: available ? 1 : .5,
      child: InkWell(
        onTap: !available || _busy ? null : () => setState(() => _item = item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(color: selected ? const Color(0xFFFFF1F4) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.burgundy : AppColors.border, width: selected ? 1.5 : 1)),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.burgundy : AppColors.muted, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item['name'] ?? 'خيار'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              if (!available) const Text('غير متاح حاليًا', style: TextStyle(fontSize: 9, color: AppColors.rose)),
            ])),
            Text(price == null ? 'السعر من الخادم' : money(price, '${item['currency'] ?? 'YER'}'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.burgundy)),
          ]),
        ),
      ),
    );
  }

  Widget _fieldWidget(Map<String, dynamic> field) {
    final key = '${field['key'] ?? ''}'.trim();
    final type = '${field['type'] ?? 'text'}'.toLowerCase();
    final options = _options(field);
    if (options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _choices[key],
        isExpanded: true,
        decoration: InputDecoration(labelText: '${field['label'] ?? key}', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: options.map((o) => DropdownMenuItem<String>(value: o.key, child: Text(o.value))).toList(),
        validator: (v) => field['required'] == true && (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
        onChanged: _busy ? null : (v) => setState(() => _choices[key] = v),
      );
    }
    final numeric = ['number','integer','decimal','amount','float'].contains(type) || key.toLowerCase() == 'amount';
    final secret = field['secret'] == true || ['password','secret'].contains(type);
    return TextFormField(
      controller: _values[key],
      enabled: !_busy,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : (['phone','mobile'].contains(key.toLowerCase()) ? TextInputType.phone : TextInputType.text),
      obscureText: secret,
      validator: (v) => _validate(field, v),
      decoration: InputDecoration(labelText: '${field['label'] ?? key}', prefixIcon: Icon(_fieldIcon(key), size: 18), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  List<MapEntry<String, String>> _options(Map<String, dynamic> field) {
    final raw = field['choices'];
    if (raw is List) return raw.map((o) {
      if (o is Map) {
        final value = '${o['value'] ?? o['key'] ?? o['id'] ?? ''}';
        return MapEntry(value, '${o['label'] ?? o['name'] ?? value}');
      }
      return MapEntry('$o', '$o');
    }).where((o) => o.key.isNotEmpty).toList();
    if (raw is Map) return raw.entries.map((e) => MapEntry('${e.key}', '${e.value}')).toList();
    return [];
  }
}


class _TransactionResultDialog extends StatefulWidget {
  const _TransactionResultDialog({required this.app, required this.transaction});
  final AppController app;
  final Map<String, dynamic> transaction;
  @override
  State<_TransactionResultDialog> createState() => _TransactionResultDialogState();
}

class _TransactionResultDialogState extends State<_TransactionResultDialog> {
  late Map<String, dynamic> _tx;
  bool _checking = false;
  String get _id => '${_tx['id'] ?? ''}'.trim();
  String get _status => _statusOf(_tx);

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);
  }

  Future<void> _checkAgain() async {
    if (_checking || _id.isEmpty) return;
    setState(() => _checking = true);
    try {
      final result = await widget.app.api.checkOperationStatus(_id);
      if (mounted) setState(() => _tx = result);
      if (!_isTerminal(_statusOf(result))) {
        final pendingResult = await widget.app.api.waitForServiceTransaction(
          _id,
          initial: result,
          maxWait: const Duration(seconds: 30),
          pollInterval: const Duration(seconds: 2),
        );
        if (mounted) setState(() => _tx = pendingResult);
      }
      try { await widget.app.refreshWalletAndReports(); } catch (_) {}
    } catch (e) {
      if (mounted) showAppToast(context, 'تعذر فحص الحالة الآن: $e', isError: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _statusView(_status, _tx);
    final error = '${_tx['error_message'] ?? _tx['detail'] ?? ''}'.trim();
    final result = _tx['result'];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      titlePadding: const EdgeInsets.fromLTRB(18, 19, 18, 5),
      contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: view.color.withOpacity(.11), shape: BoxShape.circle),
          child: Icon(view.icon, size: 30, color: view.color),
        ),
        const SizedBox(height: 9),
        Text(view.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
      ]),
      content: SizedBox(
        width: 370,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(view.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, height: 1.55)),
              const SizedBox(height: 10),
              _ResultRow('مرجع العملية', _id),
              if ('${_tx['amount'] ?? ''}'.isNotEmpty)
                _ResultRow('المبلغ من الخادم', '${_tx['amount']} ${_tx['currency'] ?? 'YER'}'),
              if (error.isNotEmpty) _ResultRow('ملاحظة الخادم', error),
              if (result is Map)
                for (final entry in result.entries.where((e) {
                  final key = '${e.key}'.toLowerCase();
                  return e.value != null && e.value is! Map &&
                      !key.contains('token') && !key.contains('secret') &&
                      !key.contains('password') && !key.contains('authorization');
                }).take(6))
                  _ResultRow('${entry.key}', entry.value is List ? (entry.value as List).take(4).join('، ') : '${entry.value}'),
              if (_checking) ...[
                const SizedBox(height: 11),
                const LinearProgressIndicator(color: AppColors.blue),
                const SizedBox(height: 7),
                const Text('يجري طلب آخر لفحص الحالة؛ لم يتم إنشاء عملية جديدة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_id.isNotEmpty && (!_isTerminal(_status) || _status == 'manual_review'))
          OutlinedButton.icon(
            onPressed: _checking ? null : _checkAgain,
            icon: const Icon(Icons.sync_rounded, size: 17),
            label: Text(_checking ? 'جاري الفحص...' : 'فحص ومتابعة'),
          ),
        FilledButton(
          onPressed: _checking ? null : () => Navigator.pop(context, _tx),
          style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy),
          child: const Text('تم'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 10.5, color: AppColors.dark, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _StatusView {
  const _StatusView(this.title, this.message, this.color, this.icon);
  final String title;
  final String message;
  final Color color;
  final IconData icon;
}

String _statusOf(Map<String, dynamic> tx) => '${tx['status'] ?? ''}'.trim().toLowerCase();

bool _isTerminal(String status) => const {
  'success', 'completed', 'done', 'executed',
  'failed', 'error', 'rejected', 'refunded',
}.contains(status);

_StatusView _statusView(String status, Map<String, dynamic> tx) {
  switch (status) {
    case 'success':
    case 'completed':
    case 'done':
    case 'executed':
      return const _StatusView(
        'تم تأكيد نجاح العملية',
        'وصلت حالة نجاح مؤكدة من الخادم. هذه هي النتيجة النهائية المعروضة.',
        AppColors.emerald,
        Icons.check_circle_rounded,
      );
    case 'failed':
    case 'error':
    case 'rejected':
      return const _StatusView(
        'لم تنجح العملية',
        'أعاد الخادم حالة فشل. راجع السبب أدناه ولا تكرر العملية إذا كانت النتيجة غير واضحة.',
        AppColors.rose,
        Icons.cancel_rounded,
      );
    case 'refunded':
      return const _StatusView(
        'تم إرجاع الرصيد',
        'أعاد الخادم حالة استرداد الرصيد. حدّث الرصيد وراجع سجل العملية قبل المحاولة مرة أخرى.',
        Color(0xFFB45309),
        Icons.account_balance_wallet_rounded,
      );
    case 'manual_review':
      return const _StatusView(
        'العملية تحتاج مراجعة',
        'لم يصل تأكيد نهائي للنجاح. لا تكرر السداد قبل انتهاء المراجعة التشغيلية.',
        Color(0xFFB45309),
        Icons.support_agent_rounded,
      );
    case 'accepted':
    case 'queued':
    case 'processing':
    case 'pending_provider':
      return const _StatusView(
        'تم إرسال العملية وجاري انتظار الرد',
        'استلم الخادم الطلب لكنه لم يرجع نتيجة نهائية بعد. لا تعِد إرساله؛ احتفظ بالمرجع وافحص الحالة لاحقًا.',
        AppColors.blue,
        Icons.hourglass_top_rounded,
      );
    default:
      final hasId = '${tx['id'] ?? ''}'.trim().isNotEmpty;
      return _StatusView(
        hasId ? 'النتيجة لم تُحسم بعد' : 'تعذر تحديد النتيجة',
        hasId
            ? 'يوجد مرجع للعملية، لكن الحالة لا تثبت نجاحها أو فشلها بعد.'
            : 'لم يصل تأكيد كافٍ من الخادم لإثبات اكتمال العملية.',
        const Color(0xFFB45309),
        Icons.help_outline_rounded,
      );
  }
}

Color _serviceColor(String name) {
  final value = name.toLowerCase();
  if (value.contains('يمن موبايل') || value.contains('yem')) return AppColors.burgundy;
  if (value.contains('سبأفون') || value.contains('saba')) return AppColors.blue;
  if (value.contains('يو') || value.contains('you')) return AppColors.amber;
  if (value.contains('واي') || value.contains('why')) return AppColors.rose;
  if (value.contains('4g') || value.contains('فورجي')) return AppColors.sky;
  if (value.contains('نت') || value.contains('adsl')) return AppColors.indigo;
  if (value.contains('كهرب') || value.contains('ماء')) return AppColors.teal;
  return AppColors.purple;
}

IconData _serviceIcon(String name, String kind) {
  final value = '$name $kind'.toLowerCase();
  if (value.contains('query') || value.contains('استعلام')) return Icons.manage_search_rounded;
  if (value.contains('كهرب')) return Icons.electrical_services_rounded;
  if (value.contains('ماء') || value.contains('water')) return Icons.water_drop_rounded;
  if (value.contains('net') || value.contains('نت') || value.contains('wifi')) return Icons.wifi_rounded;
  if (value.contains('4g') || value.contains('فورجي')) return Icons.router_rounded;
  if (value.contains('باق') || value.contains('package')) return Icons.inventory_2_rounded;
  if (value.contains('رصيد') || value.contains('balance')) return Icons.account_balance_wallet_rounded;
  return Icons.phone_android_rounded;
}

IconData _fieldIcon(String key) {
  final value = key.toLowerCase();
  if (value.contains('mobile') || value.contains('phone')) return Icons.phone_android_rounded;
  if (value.contains('amount') || value.contains('price')) return Icons.payments_outlined;
  if (value.contains('player') || value.contains('account')) return Icons.person_outline_rounded;
  return Icons.edit_outlined;
}
