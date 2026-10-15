import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  String _selectedAccount = 'الحساب الرئيسي';
  String _selectedBranch = 'اختر النقطة , الفرع';
  DateTime _selectedDate = DateTime(2026, 9, 9);
  bool _loading = false;
  String _searchQuery = '';
  bool _showSearchField = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Local state for operations loaded from server
  List<Map<String, dynamic>> _operations = [];

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
    setState(() => _loading = true);
    try {
      final app = context.read<AppController>();
      final serverOps = await app.api.serviceRequests();
      if (serverOps.isNotEmpty) {
        setState(() {
          _operations = serverOps;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final app = context.read<AppController>();
    setState(() {
      _operations = List.from(app.operations);
      _loading = false;
    });
  }

  Future<void> _checkOperation(Map<String, dynamic> op) async {
    final rawOpId = '${operation['id'] ?? ''}'.trim();
    final opId = rawOpId.isEmpty ? 'غير متوفر' : rawOpId;
    final shortTitle = opId.length > 12 ? '${opId.substring(0, 12)}...' : opId;
    final service = '${operation['service'] ?? operation['packageName'] ?? 'خدمة غير محددة'}';
    final type = '${operation['type'] ?? 'غير محدد'}';
    final phone = '${operation['phone'] ?? operation['mobile'] ?? ''}'.trim();
    final amount = double.tryParse('${operation['amount'] ?? ''}') ?? 0.0;
    final createdAt = '${operation['created_at'] ?? 'غير متوفر'}';
    final completedAt = '${operation['completed_at'] ?? 'لم تكتمل بعد'}';
    final readiness = '${operation['status'] ?? 'unknown'}'.trim();
    final normalizedStatus = readiness.toLowerCase();
    final isReady = const {'success', 'completed', 'done', 'executed'}.contains(normalizedStatus) || readiness.contains('جاهز');
    final isFailure = const {'failed', 'error', 'rejected', 'refunded'}.contains(normalizedStatus);
    final isReview = normalizedStatus == 'manual_review';
    final readinessLabel = isReady ? 'تم تأكيد النجاح' : isFailure ? (normalizedStatus == 'refunded' ? 'أُعيد الرصيد' : 'فشل') : isReview ? 'قيد المراجعة' : 'تم الإرسال / بانتظار النتيجة';
    final readinessColor = isReady ? const Color(0xFF2E7D32) : isFailure ? const Color(0xFFC62828) : const Color(0xFFB45309);
    final readinessIcon = isReady ? Icons.check_circle_rounded : isFailure ? Icons.cancel_rounded : isReview ? Icons.support_agent_rounded : Icons.hourglass_top_rounded;
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
                  hintText: 'بحث في العمليات...',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : const Text(
                'العمليات',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
        centerTitle: true,
        actions: [
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
                          children: const [
                            Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('لا توجد عمليات مسجلة لهذا التاريخ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
    final service = '${op['service'] ?? op['packageName'] ?? 'yem-balance'}';
    final type = '${op['type'] ?? 'دفع مسبق'}';
    final phone = '${op['phone'] ?? op['mobile'] ?? ''}'.trim();
    final amount = double.tryParse('${op['amount'] ?? 0}') ?? 0;
    final statusValue = '${op['status'] ?? ''}'.trim().toLowerCase();
    final isReady = const {'success', 'completed', 'done', 'executed'}.contains(statusValue) || statusValue.contains('جاهز');
    final isFailure = const {'failed', 'error', 'rejected', 'refunded'}.contains(statusValue);
    final isReview = statusValue == 'manual_review';
    final statusLabel = isReady
        ? 'ناجح'
        : isFailure
            ? (statusValue == 'refunded' ? 'أُعيد الرصيد' : 'فشل')
            : isReview
                ? 'مراجعة'
                : statusValue.isEmpty || statusValue == 'unknown'
                    ? 'غير محسومة'
                    : 'قيد المعالجة';
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
                    ],
                  ),
                ),

                // Display the latest server state. Unknown and pending never mean success.
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
                  onTap: () => _deleteOperation(index),
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
    final opId = '${operation['id'] ?? '32ce0ab6-67d6-481b-a4fc-70ec30ba75a3'}';
    final shortTitle = opId.length > 12 ? '${opId.substring(0, 12)}...' : opId;
    final service = '${operation['service'] ?? operation['packageName'] ?? 'freefire'}';
    final type = '${operation['type'] ?? 'دفع مسبق'}';
    final phone = '${operation['phone'] ?? operation['mobile'] ?? ''}'.trim();
    final amount = double.tryParse('${operation['amount'] ?? 1200}') ?? 1200.0;
    final createdAt = '${operation['created_at'] ?? '2026-09-10T12:19:56.659877+00:00'}';
    final completedAt = '${operation['completed_at'] ?? '2026-09-10T12:20:31.589978+00:00'}';
    final readiness = '${operation['status'] ?? 'جاهز'}';
    final stateCode = '${operation['state_code'] ?? operation['state'] ?? 'refunded'}';
    final chipCode = '${operation['chip_code'] ?? '7bc188ad33bec2c1'}';
    final notes = '${operation['notes'] ?? 'تم تجهيز العملية من نظام المزود تزامن مباشر! الرد: تصحيح الجاهزية بعد التأكد'}';
    final cancelReason = '${operation['cancel_reason'] ?? '---'}';
    final transferNumber = '${operation['transfer_number'] ?? '---'}';

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
              Clipboard.setData(ClipboardData(text: 'تفاصيل العملية #$opId:\nالخدمة: $service\nالمبلغ: $amount ر.ي\nالحالة: $readinessLabel'));
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
          // Success is shown only after an explicit success state from the server.
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
