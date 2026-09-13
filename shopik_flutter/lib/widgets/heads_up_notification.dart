import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HeadsUpType {
  success,
  info,
  warning,
  error,
}

class HeadsUpNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    HeadsUpType type = HeadsUpType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    dismiss();
    try { HapticFeedback.lightImpact(); } catch (_) {}

    final overlayState = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _HeadsUpBannerWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismiss: dismiss,
        onTap: onTap,
      ),
    );
    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _HeadsUpBannerWidget extends StatefulWidget {
  const _HeadsUpBannerWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.onTap,
  });
  final String title;
  final String message;
  final HeadsUpType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  State<_HeadsUpBannerWidget> createState() => _HeadsUpBannerWidgetState();
}

class _HeadsUpBannerWidgetState extends State<_HeadsUpBannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _offsetAnimation = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    Future.delayed(widget.duration, () { if (mounted) _dismiss(); });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Color get _accentColor {
    switch (widget.type) {
      case HeadsUpType.success: return const Color(0xFF059669);
      case HeadsUpType.error: return const Color(0xFFDC2626);
      case HeadsUpType.warning: return const Color(0xFFD97706);
      case HeadsUpType.info: return const Color(0xFF0284C7);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case HeadsUpType.success: return Icons.check_circle_rounded;
      case HeadsUpType.error: return Icons.cancel_rounded;
      case HeadsUpType.warning: return Icons.warning_amber_rounded;
      case HeadsUpType.info: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final slate = const Color(0xFF64748B);
    return Positioned(
      top: topPadding + 10,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: GestureDetector(
              onTap: () { widget.onTap?.call(); _dismiss(); },
              onVerticalDragUpdate: (details) { if (details.primaryDelta != null && details.primaryDelta! < -6) _dismiss(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _accentColor.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6)),
                    BoxShadow(color: _accentColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _accentColor.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(_icon, color: _accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(widget.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _accentColor)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: slate.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                child: Text('الآن', style: TextStyle(fontSize: 9, color: slate)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(widget.message, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: Icon(Icons.close, size: 16, color: slate), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: _dismiss),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
