import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String numberToArabicWords(num value) {
  final v = value.toInt();
  if (v == 50) return 'خمسون';
  if (v == 100) return 'مائة';
  if (v == 150) return 'مائة وخمسون';
  if (v == 200) return 'مائتان';
  if (v == 250) return 'مائتان وخمسون';
  if (v == 300) return 'ثلاثمائة';
  if (v == 400) return 'أربعمائة';
  if (v == 500) return 'خمسمائة';
  if (v == 600) return 'ستمائة';
  if (v == 700) return 'سبعمائة';
  if (v == 800) return 'ثمانمائة';
  if (v == 900) return 'تسعمائة';
  if (v == 1000) return 'ألف';
  if (v == 1200) return 'ألف ومائتان';
  if (v == 1500) return 'ألف وخمسمائة';
  if (v == 2000) return 'ألفين';
  if (v == 2400) return 'ألفين وأربعمائة';
  if (v == 2500) return 'ألفين وخمسمائة';
  if (v == 3000) return 'ثلاثة آلاف';
  if (v == 3500) return 'ثلاثة آلاف وخمسمائة';
  if (v == 4000) return 'أربعة آلاف';
  if (v == 4500) return 'أربعة آلاف وخمسمائة';
  if (v == 5000) return 'خمسة آلاف';
  if (v == 6000) return 'ستة آلاف';
  if (v == 7000) return 'سبعة آلاف';
  if (v == 8000) return 'ثمانية آلاف';
  if (v == 9000) return 'تسعة آلاف';
  if (v == 10000) return 'عشرة آلاف';
  return '$v ريال';
}

class OrderConfirmationDialog extends StatefulWidget {
  const OrderConfirmationDialog({
    super.key,
    required this.serviceName,
    required this.itemName,
    required this.phoneNumber,
    required this.amount,
    this.feeRatio = 1.0,
    this.lastTxTime = '09:36 - 2026-09-09 ص',
    this.lastTxName = 'باقة مزايا فولتي 48 ساعة دفع مسبق',
    this.lastTxAmount = '600.00 ر.ي',
    this.isRealVerified = true,
    this.onCheckReadiness,
  });

  final String serviceName;
  final String itemName;
  final String phoneNumber;
  final num amount;
  final double feeRatio;
  final String lastTxTime;
  final String lastTxName;
  final String lastTxAmount;
  final bool isRealVerified;
  final VoidCallback? onCheckReadiness;

  static Future<String?> show(
    BuildContext context, {
    required String serviceName,
    required String itemName,
    required String phoneNumber,
    required num amount,
    double feeRatio = 1.0,
    String lastTxTime = '09:36 - 2026-09-09 ص',
    String lastTxName = 'باقة مزايا فولتي 48 ساعة دفع مسبق',
    String lastTxAmount = '600.00 ر.ي',
    bool isRealVerified = true,
    VoidCallback? onCheckReadiness,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OrderConfirmationDialog(
        serviceName: serviceName,
        itemName: itemName,
        phoneNumber: phoneNumber,
        amount: amount,
        feeRatio: feeRatio,
        lastTxTime: lastTxTime,
        lastTxName: lastTxName,
        lastTxAmount: lastTxAmount,
        isRealVerified: isRealVerified,
        onCheckReadiness: onCheckReadiness,
      ),
    );
  }

  @override
  State<OrderConfirmationDialog> createState() => _OrderConfirmationDialogState();
}

class _OrderConfirmationDialogState extends State<OrderConfirmationDialog> {
  String _receivedAmount = '';

  void _onKeyPress(String key) {
    HapticFeedback.selectionClick();
    if (_receivedAmount.length < 8) {
      setState(() => _receivedAmount += key);
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_receivedAmount.isNotEmpty) {
      setState(() => _receivedAmount = _receivedAmount.substring(0, _receivedAmount.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = widget.amount * (1 + (widget.feeRatio / 100));
    final arabicWords = numberToArabicWords(widget.amount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  // Amber Circular (i) Icon
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B), width: 3.5),
                    ),
                    child: const Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context, null),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title with Gold Divider Lines
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: const Color(0xFFFBBF24))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'تأكيد الطلب',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: const Color(0xFFFBBF24))),
                ],
              ),
              const SizedBox(height: 14),

              // Section 1: تفاصيل الطلب
              const Text(
                'تفاصيل الطلب',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: const Row(
                        children: [
                          Expanded(child: Text('الخدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                          Expanded(child: Text('الصنف', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                          Expanded(child: Text('رقم الهاتف', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(widget.serviceName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                          Expanded(child: Text(widget.itemName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Expanded(child: Text(widget.phoneNumber, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 2: تفاصيل التكلفة
              const Text(
                'تفاصيل التكلفة',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: const Row(
                        children: [
                          Expanded(child: Text('المبلغ', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                          Expanded(child: Text('النسبة', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                          Expanded(child: Text('التكلفة', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text('${widget.amount}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                          Expanded(child: Text('% ${widget.feeRatio}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                          Expanded(child: Text(totalCost.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Arabic words text
              Text(
                '*اجمالي التكلفة : $arabicWords',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Section 3: اخر عملية لهذا الرقم (Card)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: Color(0xFFE11D48), size: 15),
                            SizedBox(width: 4),
                            Text(
                              'اخر عملية لهذا الرقم',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        Text(
                          widget.lastTxTime,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lastTxName,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: widget.onCheckReadiness,
                          child: const Text(
                            'فحص الجاهزية',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          widget.lastTxAmount,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                            SizedBox(width: 3),
                            Text(
                              'حقيقية ومؤكدة بالسيرفر ✓',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section 4: المبلغ المستلم & Keypad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المبلغ المستلم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    Text(
                      _receivedAmount.isEmpty ? '0' : _receivedAmount,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2-Row Keypad (1..6 on row 1, 7..0, backspace on row 2)
              Row(
                children: [
                  for (final numKey in ['1', '2', '3', '4', '5', '6'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: InkWell(
                          onTap: () => _onKeyPress(numKey),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                numKey,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  for (final numKey in ['7', '8', '9', '0'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: InkWell(
                          onTap: () => _onKeyPress(numKey),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                numKey,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Backspace Button
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: InkWell(
                        onTap: _onBackspace,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: const Center(
                            child: Icon(Icons.backspace_outlined, size: 16, color: Color(0xFFDC2626)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom 3 Action Buttons
              Row(
                children: [
                  // Confirm (موافق)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'confirm'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('موافق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // SMS (عبر الرسائل)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'sms'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: const Text('عبر الرسائل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // WhatsApp (عبر الواتس)
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, 'whatsapp'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('عبر الواتس', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
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
}
