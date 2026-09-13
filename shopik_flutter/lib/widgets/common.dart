import 'package:flutter/material.dart';
export 'dart:async' show unawaited;
export 'heads_up_notification.dart';

class AppColors {
  static const burgundy = Color(0xFF8B1D3B);
  static const burgundyDark = Color(0xFF78142F);
  static const burgundyLight = Color(0xFF9E1F3D);
  static const emerald = Color(0xFF059669);
  static const blue = Color(0xFF0284C7);
  static const sky = Color(0xFF0284C7);
  static const indigo = Color(0xFF4F46E5);
  static const teal = Color(0xFF0F766E);
  static const amber = Color(0xFFF59E0B);
  static const purple = Color(0xFF7C3AED);
  static const page = Color(0xFFF7F9FC);
  static const border = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const dark = Color(0xFF0F172A);
  static const navy = Color(0xFF1E293B);
  static const rose = Color(0xFFE11D48);
}

/// Fire-and-forget helper used by UI refreshes where the caller intentionally
/// does not need to await the Future. Errors are consumed so they do not create
/// an unhandled asynchronous error.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}

class PageCard extends StatelessWidget {
  const PageCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.margin});

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x100F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.color = AppColors.burgundy, this.icon});

  final String title;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
        if (icon != null) const SizedBox(width: 8),
        Expanded(
          child: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ),
      ],
    );
  }
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.title,
    this.color = AppColors.burgundy,
    this.actions,
    this.bottomSheet,
    this.floatingActionButton,
    required this.child,
  });

  final String title;
  final Color color;
  final List<Widget>? actions;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: actions,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      bottomSheet: bottomSheet,
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}

class RefSection extends StatelessWidget {
  const RefSection({
    super.key,
    required this.title,
    this.icon,
    this.action,
    this.color = AppColors.burgundy,
  });

  final String title;
  final IconData? icon;
  final Widget? action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}

class RefPill extends StatelessWidget {
  const RefPill(this.text, {super.key, this.color = AppColors.emerald});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

class RefOperationTile extends StatelessWidget {
  const RefOperationTile({super.key, required this.operation});

  final Map<String, dynamic> operation;

  @override
  Widget build(BuildContext context) {
    final title = '${operation['service_name'] ?? operation['packageName'] ?? operation['service'] ?? operation['title'] ?? 'عملية سداد معتمدة'}';
    final status = '${operation['status'] ?? 'completed'}';
    final amount = num.tryParse('${operation['amount'] ?? operation['price'] ?? 0}') ?? 0;
    final isSuccess = status == 'success' || status == 'completed' || status == 'منجز';
    final date = '${operation['created_at'] ?? operation['date'] ?? 'اليوم'}';
    final phone = '${operation['phone'] ?? operation['recipient'] ?? operation['account'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
              color: isSuccess ? AppColors.emerald : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone.isNotEmpty ? '$date • $phone' : date,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            money(amount),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.burgundy),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, this.color = AppColors.emerald});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withOpacity(.18))),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text, this.icon = Icons.inbox_outlined, this.action});

  final String text;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PageCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.black26),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, required this.visible, this.text = 'جاري تنفيذ الطلب...'});

  final bool visible;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(.45),
        child: Center(
          child: Container(
            width: 245,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3, color: AppColors.burgundy),
                const SizedBox(height: 16),
                Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String money(dynamic value, [String currency = 'ر.ي']) {
  final n = num.tryParse('$value');
  if (n == null) return '$value $currency';
  final isInt = n == n.roundToDouble();
  final formattedNumber = isInt ? _formatThousands(n.toInt().toString()) : _formatThousands(n.toStringAsFixed(2));
  return '$formattedNumber $currency';
}

String _formatThousands(String numStr) {
  final parts = numStr.split('.');
  final integerPart = parts[0];
  final buffer = StringBuffer();
  final len = integerPart.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(integerPart[i]);
  }
  if (parts.length > 1) {
    buffer.write('.${parts[1]}');
  }
  return buffer.toString();
}

String absoluteUrl(String? value) {
  if (value == null || value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  return 'https://shopik.alattab.site${value.startsWith('/') ? value : '/$value'}';
}

Color serviceColor(String key) {
  final v = key.toLowerCase();
  if (v.contains('yemen_mobile') || v.contains('يمن موبايل')) return AppColors.burgundy;
  if (v.contains('sabafon') || v.contains('سبأفون')) return AppColors.blue;
  if (v.contains('you') || v.contains('يو')) return AppColors.amber;
  if (v.contains('4g') || v.contains('فورجي')) return const Color(0xFF0EA5E9);
  if (v.contains('net') || v.contains('نت')) return AppColors.indigo;
  if (v.contains('game') || v.contains('لعبة')) return AppColors.purple;
  return AppColors.teal;
}

void showAppToast(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      backgroundColor: isError
          ? const Color(0xFFDC2626)
          : (isSuccess ? const Color(0xFF059669) : const Color(0xFF0F172A)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 3),
    ),
  );
}
