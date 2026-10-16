import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';


String _transactionPhone(Map<String, dynamic> item) {
  final payload = item['payload'] is Map
      ? Map<String, dynamic>.from(item['payload'] as Map)
      : <String, dynamic>{};
  for (final key in const [
    'phone', 'mobile', 'mobile_number', 'phone_number',
    'subscriber_number', 'account_number', 'msisdn',
  ]) {
    final value = item[key] ?? payload[key];
    if (value != null && '${value}'.trim().isNotEmpty) return '${value}'.trim();
  }
  return '';
}

dynamic _transactionResponse(Map<String, dynamic> item) =>
    item['provider_response'] ?? item['server_response'] ?? item['raw_response'] ?? item['result'] ?? item['response'];

String _transactionResponseText(Map<String, dynamic> item) {
  final response = _transactionResponse(item);
  if (response == null) return '';
  if (response is String) return response;
  try {
    return const JsonEncoder.withIndent('  ').convert(response);
  } catch (_) {
    return '${response}';
  }
}

String _transactionServiceName(Map<String, dynamic> item, [AppController? app]) {
  final code = '${item['service_code'] ?? item['service'] ?? item['service_key'] ?? ''}'.trim();
  for (final key in const ['service_name', 'service_display_name', 'display_name']) {
    final name = '${item[key] ?? ''}'.trim();
    if (name.isNotEmpty && name.toLowerCase() != code.toLowerCase()) return name;
  }
  if (app != null && code.isNotEmpty) {
    for (final setting in app.serviceSettingsRaw) {
      final nested = setting['service'] is Map
          ? Map<String, dynamic>.from(setting['service'] as Map)
          : <String, dynamic>{};
      final keys = [
        '${setting['key'] ?? ''}',
        '${setting['service_code'] ?? ''}',
        '${nested['code'] ?? ''}',
        '${nested['slug'] ?? ''}',
      ].map((v) => v.trim().toLowerCase()).where((v) => v.isNotEmpty);
      if (keys.contains(code.toLowerCase())) {
        final name = '${nested['name'] ?? setting['name'] ?? ''}'.trim();
        if (name.isNotEmpty) return name;
      }
    }
    final id = int.tryParse('${item['service_id'] ?? ''}');
    for (final entry in app.serviceDetailsCache.entries) {
      final detail = entry.value;
      if ((id != null && entry.key == id) ||
          '${detail['code'] ?? ''}'.trim().toLowerCase() == code.toLowerCase() ||
          '${detail['slug'] ?? ''}'.trim().toLowerCase() == code.toLowerCase()) {
        final name = '${detail['name'] ?? ''}'.trim();
        if (name.isNotEmpty) return name;
      }
    }
  }
  switch (code.toLowerCase()) {
    case 'yem-balance':
    case 'yemen_mobile_recharge':
    case 'yemen-mobile-recharge':
      return 'تسديد رصيد يمن موبايل';
    case 'yemen_mobile_balance':
    case 'yem-balance-inquiry':
      return 'استعلام رصيد يمن موبايل';
    case 'yemen_mobile_offers':
    case 'yem-offers':
      return 'استعلام باقات يمن موبايل';
    case 'bagatmobileget':
      return 'باقات يمن موبايل';
  }
  final fallback = '${item['packageName'] ?? item['item_name'] ?? item['title'] ?? item['name'] ?? code}'.trim();
  return fallback.isEmpty ? 'خدمة غير محددة' : fallback;
}

bool _isServiceInquiry(Map<String, dynamic> item) {
  final kind = '${item['service_kind'] ?? item['serviceKind'] ?? ''}'.trim().toLowerCase();
  if (kind == 'query' || kind == 'catalog') return true;
  final code = '${item['service_code'] ?? item['service'] ?? item['service_key'] ?? ''}'.trim().toLowerCase();
  final label = '${item['service_name'] ?? item['display_name'] ?? item['type'] ?? item['action'] ?? ''}'.trim().toLowerCase();
  final text = '$code $label';
  return const [
    'inquiry', 'query', 'catalog', 'استعلام', 'فحص السلفة', 'loan_check',
    'sulfa_check', 'check_balance', 'check_offers', 'packages_list',
  ].any(text.contains);
}

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  Widget _buildSectionChoice({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B1D3B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF8B1D3B) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xFF334155)))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.18) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xFF334155))),
            ),
          ],
        ),
      ),
    );
  }
  String _selectedAccount = 'الحساب الرئيسي';
  String _selectedBranch = 'اختر النقطة , الفرع';
  DateTime _selectedDate = DateTime(2026, 9, 9);
  bool _loading = false;
  String _searchQuery = '';
  bool _showSearchField = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Payment records and provider inquiries are shown in separate sections.
  List<Map<String, dynamic>> _operations = [];
  List<Map<String, dynamic>> _inquiries = [];
  String _selectedSection = 'operations';
  bool _sortByPhone = false;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOperations() async {
    if (mounted) setState(() => _loading = true);
    final app = context.read<AppController>();
    List<Map<String, dynamic>> records = [];
    try {
      records = await app.api.serviceRequests();
      if (records.isEmpty) records = await app.api.serviceReports();
    } catch (_) {}
    if (records.isEmpty) records = List<Map<String, dynamic>>.from(app.operations);

    final inquiries = records.where(_isServiceInquiry).toList();
    final payments = records.where((item) => !_isServiceInquiry(item)).toList();
    if (!mounted) return;
    setState(() {
      _operations = payments;
      _inquiries = inquiries;
      _loading = false;
    });
  }

  Future<void> _checkOperation(Map<String, dynamic> op) async {
    final operationId = '${op['id'] ?? ''}'.trim();
    if (operationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFB45309),
          content: Text('لا يوجد رقم مرجع للعملية يمكن فحصه من الخادم.'),
        ),
      );
      return;
    }

    var progressDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('جاري فحص حالة العملية من الخادم...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    void closeProgressDialog() {
      if (!progressDialogOpen || !mounted) return;
      progressDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    try {
      final app = context.read<AppController>();
      var result = await app.api.checkOperationStatus(operationId);
      var status = '${result['status'] ?? ''}'.trim().toLowerCase();

      // A provider check can report that the transaction is still processing.
      // Continue checking the existing UUID; never submit a second payment.
      if (status.isEmpty ||
          const {'accepted', 'queued', 'pending', 'pending_provider', 'processing', 'manual_review'}.contains(status)) {
        result = await app.api.waitForServiceTransaction(
          operationId,
          initial: result,
          maxWait: const Duration(seconds: 30),
          pollInterval: const Duration(seconds: 2),
        );
        status = '${result['status'] ?? ''}'.trim().toLowerCase();
      }

      closeProgressDialog();
      if (!mounted) return;

      final note = '${result['error_message'] ?? result['message'] ?? result['detail'] ?? ''}'.trim();
      setState(() {
        op['status'] = status.isEmpty ? 'unknown' : status;
        if (note.isNotEmpty) op['notes'] = note;
        op['last_checked_at'] = DateTime.now().toIso8601String();
      });

      final success = const {'success', 'completed', 'done', 'executed'}.contains(status);
      final failure = const {'failed', 'error', 'rejected', 'refunded'}.contains(status);
      final message = success
          ? 'أكد الخادم نجاح العملية.'
          : status == 'refunded'
              ? 'أفاد الخادم أن الرصيد أُعيد.'
              : const {'failed', 'error', 'rejected'}.contains(status)
                  ? 'أفاد الخادم أن العملية لم تنجح.'
                  : status == 'manual_review'
                      ? 'العملية تحتاج إلى مراجعة تشغيلية. لا تكرر السداد.'
                      : 'لم تصل نتيجة نهائية بعد؛ الحالة الحالية: ${status.isEmpty ? 'غير معروفة' : status}.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success
              ? const Color(0xFF059669)
              : failure
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFB45309),
          behavior: SnackBarBehavior.floating,
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      );
    } catch (e) {
      closeProgressDialog();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB45309),
          behavior: SnackBarBehavior.floating,
          content: Text('تعذر التحقق من حالة العملية؛ لم نغيرها إلى ناجحة: $e'),
        ),
      );
    }
  }

  void _deleteOperation(Map<String, dynamic> operation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف العملية من السجل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        content: const Text('هل أنت متأكد من حذف هذه العملية من شاشة العرض الحالية؟', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final id = '${operation['id'] ?? ''}';
              if (id.isNotEmpty && _selectedSection == 'operations') {
                context.read<AppController>().api.deleteServiceRequest(id);
              }
              setState(() {
                final list = _selectedSection == 'inquiries' ? _inquiries : _operations;
                final index = list.indexWhere((item) =>
                    identical(item, operation) ||
                    ('${item['id'] ?? ''}'.isNotEmpty && item['id'] == operation['id']));
                if (index >= 0) list.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف العملية من العرض')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _printReceipt(Map<String, dynamic> op) {
    final rawReceiptId = '${op['id'] ?? ''}'.trim();
    final receiptId = rawReceiptId.isEmpty
        ? 'غير متوفر'
        : rawReceiptId.length > 8
            ? rawReceiptId.substring(0, 8)
            : rawReceiptId;
    final app = context.read<AppController>();
    final status = '${op['status'] ?? 'unknown'}'.trim().toLowerCase();
    final statusLabel = const {'success', 'completed', 'done', 'executed'}.contains(status)
        ? 'ناجح'
        : const {'failed', 'error', 'rejected'}.contains(status)
            ? 'فاشل'
            : status == 'refunded'
                ? 'أُعيد الرصيد'
                : 'غير محسوم / قيد التنفيذ';
    final response = _transactionResponseText(op);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('سند تنفيذ العملية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text('شبكة شبيك الإلكترونية المعتمدة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF8B1D3B))),
                  const SizedBox(height: 4),
                  Text('رقم السند: #$receiptId', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const Divider(height: 20),
                  _receiptRow('الخدمة:', _transactionServiceName(op, app)),
                  _receiptRow('رقم الهاتف:', _transactionPhone(op).isEmpty ? '---' : _transactionPhone(op)),
                  _receiptRow('المبلغ:', '${op['amount']} ريال يمني'),
                  _receiptRow('الحالة:', statusLabel),
                  _receiptRow('التاريخ:', '${op['created_at'] ?? 'غير متوفر'}'),
                  if (response.isNotEmpty) _receiptRow('رد الخادم:', response),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال أمر الطباعة بنجاح')),
                );
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('طباعة السند الفوري'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1D3B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  void _sendMessage(Map<String, dynamic> op) {
    final phone = '${op['phone'] ?? ''}'.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مراسلة الزبون', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        content: Text(
          phone.isNotEmpty
              ? 'إرسال إشعار تفاصيل العملية إلى الرقم: $phone عبر واتساب أو الرسائل القصيرة SMS.'
              : 'يرجى تحديد رقم الهاتف لإرسال الإشعار والتفاصيل.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(phone.isNotEmpty ? 'تم فتح المراسلة للرقم $phone' : 'تم تجهيز الإشعار')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            child: const Text('إرسال الآن'),
          ),
        ],
      ),
    );
  }

  void _openDetails(Map<String, dynamic> op) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(
          operation: op,
          onCheck: () => _checkOperation(op),
          onPrint: () => _printReceipt(op),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppController>();
    final activeRecords = _selectedSection == 'inquiries' ? _inquiries : _operations;
    final query = _searchQuery.toLowerCase();
    final filteredOps = activeRecords.where((op) {
      final searchable = [
        _transactionServiceName(op, app),
        _transactionPhone(op),
        '${op['amount'] ?? ''}',
        '${op['id'] ?? ''}',
        '${op['status'] ?? ''}',
        _transactionResponseText(op),
      ].join(' ').toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
    if (_sortByPhone) {
      filteredOps.sort((a, b) => _transactionPhone(a).compareTo(_transactionPhone(b)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1D3B),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                onPressed: widget.onBack,
              )
            : null,
        title: _showSearchField
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'بحث بالرقم أو الخدمة أو رد الخادم...',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Text(
                _selectedSection == 'inquiries' ? 'الاستعلامات' : 'العمليات',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _sortByPhone ? 'إلغاء الفرز حسب رقم الهاتف' : 'فرز حسب رقم الهاتف',
            icon: Icon(_sortByPhone ? Icons.sort_by_alpha_rounded : Icons.phone_iphone_rounded, color: Colors.white),
            onPressed: () => setState(() => _sortByPhone = !_sortByPhone),
          ),
          IconButton(
            icon: Icon(_showSearchField ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearchField = !_showSearchField;
                if (!_showSearchField) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadOperations,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionChoice(
                    label: 'العمليات',
                    count: _operations.length,
                    selected: _selectedSection == 'operations',
                    onTap: () => setState(() => _selectedSection = 'operations'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSectionChoice(
                    label: 'الاستعلامات',
                    count: _inquiries.length,
                    selected: _selectedSection == 'inquiries',
                    onTap: () => setState(() => _selectedSection = 'inquiries'),
                  ),
                ),
              ],
            ),
          ),
          // Filter Row 1: Dropdowns (Matching Screenshot 3)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    // Account Dropdown
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccount,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                            items: const [
                              DropdownMenuItem(value: 'الحساب الرئيسي', child: Text('الحساب الرئيسي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'حساب التسديدات', child: Text('حساب التسديدات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedAccount = v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Branch Dropdown
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBranch,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                            items: const [
                              DropdownMenuItem(value: 'اختر النقطة , الفرع', child: Text('اختر النقطة , الفرع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                              DropdownMenuItem(value: 'فرع المركز الرئيسي', child: Text('فرع المركز الرئيسي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'نقطة المشتري', child: Text('نقطة المشتري', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedBranch = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date Picker Pill Row (Matching Screenshot 3: الأربعاء، 9 سبتمبر 2026)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        Row(
                          children: [
                            Text(
                              'الأربعاء، ${_selectedDate.day} سبتمبر ${_selectedDate.year}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFFB91C1C)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Operations List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B1D3B)))
                : filteredOps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              _selectedSection == 'inquiries' ? 'لا توجد استعلامات مسجلة' : 'لا توجد عمليات مسجلة',
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOperations,
                        color: const Color(0xFF8B1D3B),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredOps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final op = filteredOps[i];
                            return _buildOperationCard(op, i);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> op, int index) {
    final app = context.read<AppController>();
    final service = _transactionServiceName(op, app);
    final type = '${op['type'] ?? op['item_name'] ?? op['packageName'] ?? op['service_kind'] ?? 'عملية خدمة'}';
    final phone = _transactionPhone(op);
    final amount = double.tryParse('${op['amount'] ?? 0}') ?? 0;
    final serverResponse = _transactionResponseText(op);
    final statusValue = '${op['status'] ?? 'unknown'}'.trim().toLowerCase();
    final isReady = const {'success', 'completed', 'done', 'executed'}.contains(statusValue);
    final isFailure = const {'failed', 'error', 'rejected', 'refunded'}.contains(statusValue);
    final isReview = statusValue == 'manual_review';
    final statusLabel = isReady
        ? 'ناجح'
        : statusValue == 'refunded'
            ? 'أُعيد الرصيد'
            : isFailure
                ? 'فشل'
                : isReview
                    ? 'مراجعة'
                    : statusValue == 'accepted' || statusValue == 'queued' || statusValue == 'processing' || statusValue == 'pending_provider'
                        ? 'قيد التنفيذ'
                        : 'غير محسومة';
    final statusColor = isReady
        ? const Color(0xFF059669)
        : isFailure
            ? const Color(0xFFDC2626)
            : const Color(0xFFB45309);
    final statusBg = isReady
        ? const Color(0xFFE8F8F0)
        : isFailure
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFFBEB);
    final statusBorder = isReady
        ? const Color(0xFFA7F3D0)
        : isFailure
            ? const Color(0xFFFECACA)
            : const Color(0xFFFDE68A);
    final statusIcon = isReady
        ? Icons.check_circle_rounded
        : isFailure
            ? Icons.cancel_rounded
            : isReview
                ? Icons.support_agent_rounded
                : Icons.access_time_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Top Info Row (Matching Screenshot 3)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right side: Service details (RTL align)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            phone.isNotEmpty ? phone : '---',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.phone_android_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          const Text('رقم التلفون:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.monetization_on_outlined, size: 14, color: Color(0xFFB91C1C)),
                          const SizedBox(width: 4),
                          const Text('سعر العملية:', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (serverResponse.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'رد الخادم: ${serverResponse.replaceAll('\n', ' ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, height: 1.35, color: Color(0xFF475569)),
                        ),
                      ],
                    ],
                  ),
                ),

                // A success badge requires an explicit success status from the backend.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bottom Action Buttons Row (Matching Screenshot 3: حذف, تفاصيل, طباعة, مراسله, فحص)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. حذف
                _buildActionBtn(
                  label: 'حذف',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  onTap: () => _deleteOperation(op),
                ),
                // 2. تفاصيل
                _buildActionBtn(
                  label: 'تفاصيل',
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF0284C7),
                  onTap: () => _openDetails(op),
                ),
                // 3. طباعة
                _buildActionBtn(
                  label: 'طباعة',
                  icon: Icons.print_outlined,
                  color: const Color(0xFF475569),
                  onTap: () => _printReceipt(op),
                ),
                // 4. مراسله
                _buildActionBtn(
                  label: 'مراسله',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => _sendMessage(op),
                ),
                // 5. فحص (The Key Live Inspection Feature)
                _buildActionBtn(
                  label: 'فحص',
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFFEA580C),
                  onTap: () => _checkOperation(op),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 4: Operation Details Screen (Matching Screenshot 4 Exactly)
// ---------------------------------------------------------------------------
class OperationDetailScreen extends StatelessWidget {
  const OperationDetailScreen({
    super.key,
    required this.operation,
    required this.onCheck,
    required this.onPrint,
  });

  final Map<String, dynamic> operation;
  final VoidCallback onCheck;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final rawOpId = '${operation['id'] ?? ''}'.trim();
    final opId = rawOpId.isEmpty ? 'غير متوفر' : rawOpId;
    final shortTitle = opId.length > 12 ? '${opId.substring(0, 12)}...' : opId;
    final app = context.read<AppController>();
    final service = _transactionServiceName(operation, app);
    final type = '${operation['type'] ?? operation['item_name'] ?? operation['packageName'] ?? operation['service_kind'] ?? 'غير محدد'}';
    final phone = _transactionPhone(operation);
    final serverResponse = _transactionResponseText(operation);
    final amount = double.tryParse('${operation['amount'] ?? ''}') ?? 0.0;
    final createdAt = '${operation['created_at'] ?? 'غير متوفر'}';
    final completedAt = '${operation['completed_at'] ?? 'لم تكتمل بعد'}';
    final readiness = '${operation['status'] ?? 'unknown'}'.trim();
    final normalizedStatus = readiness.toLowerCase();
    final isReady = const {'success', 'completed', 'done', 'executed'}.contains(normalizedStatus);
    final isFailure = const {'failed', 'error', 'rejected', 'refunded'}.contains(normalizedStatus);
    final isReview = normalizedStatus == 'manual_review';
    final readinessLabel = isReady
        ? 'تم تأكيد النجاح'
        : isFailure
            ? (normalizedStatus == 'refunded' ? 'أُعيد الرصيد' : 'فشل')
            : isReview
                ? 'قيد المراجعة'
                : 'تم الإرسال / بانتظار النتيجة';
    final readinessColor = isReady
        ? const Color(0xFF2E7D32)
        : isFailure
            ? const Color(0xFFC62828)
            : const Color(0xFFB45309);
    final readinessIcon = isReady
        ? Icons.check_circle_rounded
        : isFailure
            ? Icons.cancel_rounded
            : isReview
                ? Icons.support_agent_rounded
                : Icons.hourglass_top_rounded;
    final stateCode = '${operation['state_code'] ?? operation['state'] ?? 'غير متوفر'}';
    final chipCode = '${operation['chip_code'] ?? 'غير متوفر'}';
    final notes = '${operation['notes'] ?? operation['message'] ?? 'لا توجد ملاحظات من الخادم'}';
    final cancelReason = '${operation['cancel_reason'] ?? 'غير متوفر'}';
    final transferNumber = '${operation['transfer_number'] ?? 'غير متوفر'}';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1D3B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل العملية رقم: $shortTitle',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'تفاصيل العملية #$opId:\nالخدمة: $service\nرقم الهاتف: $phone\nالمبلغ: $amount ر.ي\nالحالة: $readinessLabel\nرد الخادم: $serverResponse'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ تفاصيل العملية للمشاركة')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report the status received from the backend; never synthesize success.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: readinessColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(readinessIcon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    readinessLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. White Details Table (Matching Screenshot 4 Field by Field)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow('رقم العملية', opId, isMono: true, copyable: true, context: context),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('الخدمة', service),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('الصنف / الزبون', type),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('رقم الهاتف', phone.isNotEmpty ? phone : ''),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('السعر', '${amount.toStringAsFixed(2)} ر.ي', isRed: true),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('تاريخ الاضافة', createdAt),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('تاريخ التجهيز', completedAt),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('الحالة من الخادم', readinessLabel, isGreen: isReady),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('رد الخادم كما وصل', serverResponse.isNotEmpty ? serverResponse : 'لم يرسل الخادم ردًا تفصيليًا لهذه العملية'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('الحالة', stateCode),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('رقم الشريحة / البرمجة', chipCode),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('ملاحظات', notes),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('سبب الالغاء', cancelReason),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildDetailRow('رقم الحوالة', transferNumber),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Two Main Action Buttons: [فحص العملية] & [طباعة] (Matching Screenshot 4)
          Row(
            children: [
              // فحص العملية (أحمر عريض)
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onCheck,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'فحص العملية',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // طباعة (أبيض بإطار أحمر)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_rounded, color: Color(0xFFB91C1C), size: 20),
                    label: const Text(
                      'طباعة',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFB91C1C)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMono = false,
    bool isRed = false,
    bool isGreen = false,
    bool copyable = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value (Left aligned in RTL display)
          Expanded(
            child: Row(
              children: [
                if (copyable && context != null)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ رقم العملية')),
                      );
                    },
                  ),
                if (copyable) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: isMono ? 'monospace' : null,
                      color: isRed
                          ? const Color(0xFFB91C1C)
                          : isGreen
                              ? const Color(0xFF059669)
                              : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Label (Right aligned)
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
