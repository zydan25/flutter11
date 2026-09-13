import 'package:flutter/material.dart';
import '../core/telecom_catalog.dart';
import 'common.dart';

enum PackageActionChoice {
  activateFromBalance,
  payAndActivate,
  deletePackage,
}

class PackageDetailsSheet extends StatefulWidget {
  const PackageDetailsSheet({
    super.key,
    required this.package,
    required this.phoneNumber,
    this.currentBalance = 436.04,
    this.loanAmount = 122.0,
  });

  final TelecomPackageInfo package;
  final String phoneNumber;
  final double currentBalance;
  final double loanAmount;

  static Future<PackageActionChoice?> show(
    BuildContext context, {
    required TelecomPackageInfo package,
    required String phoneNumber,
    double currentBalance = 436.04,
    double loanAmount = 122.0,
  }) {
    return showModalBottomSheet<PackageActionChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PackageDetailsSheet(
        package: package,
        phoneNumber: phoneNumber,
        currentBalance: currentBalance,
        loanAmount: loanAmount,
      ),
    );
  }

  @override
  State<PackageDetailsSheet> createState() => _PackageDetailsSheetState();
}

class _PackageDetailsSheetState extends State<PackageDetailsSheet> {
  bool _payLoan = true;

  @override
  Widget build(BuildContext context) {
    // Government tax calculation (typically ~17.4% deduction for net credit)
    final netAfterTax = widget.package.price * 0.826;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title + Close Button (Matching Screenshot 1)
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.package.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context, null),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Checkbox: تسديد مبلغ السلفة (Matching Screenshot 1)
            InkWell(
              onTap: () => setState(() => _payLoan = !_payLoan),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _payLoan,
                        activeColor: const Color(0xFF8B1D3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) => setState(() => _payLoan = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تسديد مبلغ السلفة ${widget.loanAmount.toStringAsFixed(1)} ريال',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Price Box: سعر الباقة : [ 2000 ريال ] (Matching Screenshot 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              ),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'سعر الباقة:  ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569), fontFamily: 'Cairo'),
                      ),
                      TextSpan(
                        text: '${widget.package.price.toInt()} ريال',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Text: الصافي بعد خصم الضريبة الحكومية (Matching Screenshot 1)
            Center(
              child: Text(
                'الصافي بعد خصم الضريبة الحكومية: ${netAfterTax.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Text: رصيد الرقم الحالي (Matching Screenshot 1 in blue)
            Center(
              child: Text(
                'رصيد الرقم الحالي: ${widget.currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3 Action Buttons (Matching Screenshot 1)
            Row(
              children: [
                // Button 1: تفعيل من الرصيد
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, PackageActionChoice.activateFromBalance),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.credit_card_outlined, size: 16),
                      label: const Text('تفعيل من الرصيد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: حذف الباقة
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, PackageActionChoice.deletePackage),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                      label: const Text('حذف الباقة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 3: تسديد + تفعيل (Green checkmark button)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, PackageActionChoice.payAndActivate),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('تسديد + تفعيل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
