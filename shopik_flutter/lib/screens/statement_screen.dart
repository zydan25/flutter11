import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  DateTime _fromDate = DateTime(2026, 9, 6);
  DateTime _toDate = DateTime(2026, 9, 9);
  bool _loading = false;
  List<Map<String, dynamic>> _entries = [];
  double _finalBalance = 99033.43;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() => _loading = true);
    try {
      final app = context.read<AppController>();
      final serverStmt = await app.api.walletStatement();
      final list = serverStmt['statement'];
      if (list is List && list.isNotEmpty) {
        setState(() {
          _entries = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _finalBalance = double.tryParse('${serverStmt['closing_balance'] ?? app.balance}') ?? _finalBalance;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final app = context.read<AppController>();
    setState(() {
      _finalBalance = app.balance.toDouble();
      _entries = [];
      _loading = false;
    });
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF8B1D3B),
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('جاري تجهيز وتصدير كشف الحساب PDF...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final userName = app.user?.name.isNotEmpty == true ? app.user!.name : 'زيدان محمد عبدالله العطاب';
    final displayShortName = userName.length > 20 ? '${userName.substring(0, 18)}...' : userName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1D3B),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'كشف حساب : $displayShortName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
            label: const Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar (Matching Screenshot 1: عرض | إلى: 2026-09-09 | من: 2026-09-06)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // زر عرض (أحمر بارز)
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: _loadStatement,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('عرض', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),

                // حقل إلى
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _toDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2027),
                      );
                      if (p != null) setState(() => _toDate = p);
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFB91C1C)),
                          const SizedBox(width: 4),
                          Text(
                            'إلى: ${_toDate.year}-${_toDate.month.toString().padLeft(2, '0')}-${_toDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // حقل من
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _fromDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2027),
                      );
                      if (p != null) setState(() => _fromDate = p);
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFB91C1C)),
                          const SizedBox(width: 4),
                          Text(
                            'من: ${_fromDate.year}-${_fromDate.month.toString().padLeft(2, '0')}-${_fromDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Header (Matching Screenshot 1: الرصيد | له | عليه | البيان)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFE2E8F0),
            child: Row(
              children: const [
                // الرصيد (يسار)
                Expanded(
                  flex: 2,
                  child: Text(
                    'الرصيد',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                    textAlign: TextAlign.start,
                  ),
                ),
                // له (أخضر)
                Expanded(
                  flex: 2,
                  child: Text(
                    'له',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF15803D)),
                    textAlign: TextAlign.center,
                  ),
                ),
                // عليه (أحمر)
                Expanded(
                  flex: 2,
                  child: Text(
                    'عليه',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFB91C1C)),
                    textAlign: TextAlign.center,
                  ),
                ),
                // البيان (يمين)
                Expanded(
                  flex: 4,
                  child: Text(
                    'البيان',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B)),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // Statement List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B1D3B)))
                : RefreshIndicator(
                    onRefresh: _loadStatement,
                    color: const Color(0xFF8B1D3B),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final item = _entries[i];
                        final title = '${item['title'] ?? item['description'] ?? 'حركة رصيد'}';
                        final date = '${item['date'] ?? item['created_at'] ?? '2026-09-09'}';
                        final debit = item['debit'];
                        final credit = item['credit'];
                        final bal = item['balance'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. الرصيد (أزرق داكن)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  bal is num ? bal.toStringAsFixed(2) : '$bal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              // 2. له (أخضر)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  credit != null ? (credit is num ? credit.toStringAsFixed(1) : '$credit') : '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: credit != null ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // 3. عليه (أحمر بني)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  debit != null ? (debit is num ? debit.toStringAsFixed(1) : '$debit') : '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: debit != null ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // 4. البيان والتاريخ (يمين)
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        height: 1.25,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                        fontFamily: 'monospace',
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Bottom Bar: الرصيد النهائي الحالي (Matching Screenshot 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              boxShadow: [
                BoxShadow(color: Color(0x060F172A), blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_finalBalance.toStringAsFixed(2)} ر.ي',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF15803D),
                  ),
                ),
                const Text(
                  'الرصيد النهائي الحالي:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
