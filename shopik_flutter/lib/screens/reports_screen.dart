import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'statement_screen.dart';
import 'operations_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.onBack, this.onNavigateTab});
  final VoidCallback? onBack;
  final void Function(int tabIndex)? onNavigateTab;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeMetric = 'amount'; // 'amount' (مبلغ) or 'quantity' (كمية)
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await context.read<AppController>().refreshWalletAndReports();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReportDialog(String title, String desc, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B1D3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final balance = app.balance;
    final displayBalance = balance > 0 ? balance : 36533;

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
        title: const Text(
          'تقارير',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Dual Circular Progress Cards (Matching Screenshot 2)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // Right: حصالة ارباحي (دائرة سماوية 0.0%)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            CircularProgressIndicator(
                              value: 0.05,
                              strokeWidth: 6,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                            ),
                            Text(
                              '0.0%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('حصالة ارباحي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      const Text('0.00 ر.ي', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(height: 80, width: 1, color: const Color(0xFFE2E8F0)),

                // Left: رصيدي (دائرة حمراء 86.0%)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            CircularProgressIndicator(
                              value: 0.86,
                              strokeWidth: 6,
                              backgroundColor: Color(0xFFFEE2E2),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB91C1C)),
                            ),
                            Text(
                              '86.0%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('رصيدي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text('${money(displayBalance, "")} ر.ي', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. 3x3 Reports Grid (Matching Screenshot 2 Exactly)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              // 1. كشف حساب (أيقونة فاتورة حمراء)
              _buildReportItem(
                title: 'كشف حساب',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Tab 4 is كشف حساب
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementScreen()));
                  }
                },
              ),
              // 2. سجل (أيقونة ساعة زرقاء)
              _buildReportItem(
                title: 'سجل',
                icon: Icons.history_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(3); // Tab 3 is العمليات
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsScreen()));
                  }
                },
              ),
              // 3. الأرصدة (أيقونة محفظة خضراء)
              _buildReportItem(
                title: 'الأرصدة',
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () => _showReportDialog('تقرير الأرصدة', 'عرض رصيدك المتاح الحالي ($displayBalance ريال يمني) وأرصدة العملات الأجنبية المحفوظة.', Icons.account_balance_wallet_rounded, const Color(0xFF059669)),
              ),
              // 4. التسديدات (أيقونة نقدية برتقالية)
              _buildReportItem(
                title: 'التسديدات',
                icon: Icons.payments_rounded,
                color: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                onTap: () => _showReportDialog('تقرير التسديدات', 'إجمالي التسديدات المنفذة عبر حسابك بقيمة 2,086,110 ر.ي لجميع مشغلي الاتصالات.', Icons.payments_rounded, const Color(0xFFEA580C)),
              ),
              // 5. تسديدات الفروع (أيقونة متجر بنفسجية)
              _buildReportItem(
                title: 'تسديدات الفروع',
                icon: Icons.storefront_rounded,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFFAF5FF),
                onTap: () => _showReportDialog('تسديدات الفروع', 'كشف عمليات ونقاط البيع والفروع التابعة لحسابك المعتمد.', Icons.storefront_rounded, const Color(0xFF9333EA)),
              ),
              // 6. الحوالات المالية (أيقونة سهمين خضراء/سماوية)
              _buildReportItem(
                title: 'الحوالات المالية',
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                onTap: () => _showReportDialog('الحوالات المالية', 'سجل الحوالات المالية المرسلة والمستلمة وتغذية الحساب كاش وعبر الصرافين.', Icons.swap_horiz_rounded, const Color(0xFF0284C7)),
              ),
              // 7. كروت الواي فاي (أيقونة واي فاي رمادية زرقاء)
              _buildReportItem(
                title: 'كروت الواي فاي',
                icon: Icons.wifi_rounded,
                color: const Color(0xFF475569),
                bgColor: const Color(0xFFF1F5F9),
                onTap: () => _showReportDialog('كروت الواي فاي', 'إجمالي كروت الشبكات المشتراة والمطبوعة والأكواد الفعالة.', Icons.wifi_rounded, const Color(0xFF475569)),
              ),
              // 8. اخرى (أيقونة 3 نقاط)
              _buildReportItem(
                title: 'اخرى',
                icon: Icons.more_horiz_rounded,
                color: const Color(0xFF64748B),
                bgColor: const Color(0xFFF8FAFC),
                onTap: () => _showReportDialog('تقارير أخرى', 'تقارير إحصائية دورية ومطابقة الحسابات المالية.', Icons.more_horiz_rounded, const Color(0xFF64748B)),
              ),
              // 9. عمولة للفروع (أيقونة شارة وردية)
              _buildReportItem(
                title: 'عمولة للفروع',
                icon: Icons.loyalty_rounded,
                color: const Color(0xFFDB2777),
                bgColor: const Color(0xFFFDF2F8),
                onTap: () => _showReportDialog('عمولة للفروع', 'إجمالي العمولات المستحقة والأرباح الأسبوعية المحتسبة للوكيل.', Icons.loyalty_rounded, const Color(0xFFDB2777)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Bottom Breakdown Card with Segmented Control (Matching Screenshot 2)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Segmented Switcher [مبلغ | كمية]
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeMetric = 'quantity'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeMetric == 'quantity' ? const Color(0xFFB91C1C) : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(15)),
                          ),
                          child: Text(
                            'كمية',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _activeMetric == 'quantity' ? Colors.white : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeMetric = 'amount'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeMetric == 'amount' ? const Color(0xFFB91C1C) : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(15)),
                          ),
                          child: Text(
                            'مبلغ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _activeMetric == 'amount' ? Colors.white : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Rows (Matching Screenshot 2: التسديدات 2,086,110 | الشرائح 0)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeMetric == 'amount' ? '2,086,110' : '842',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          const Text(
                            'التسديدات',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeMetric == 'amount' ? '0' : '0',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          const Text(
                            'الشرائح',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeMetric == 'amount' ? '12,450' : '15',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                          const Text(
                            'كروت الشبكات والواي فاي',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x040F172A), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
