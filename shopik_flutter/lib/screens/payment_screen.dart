import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import 'payment_screen_legacy.dart' as legacy;

/// Compatibility wrapper around the existing payment UI.
/// It only bridges the old client setting keys to the canonical server settings,
/// so the existing screen fetches packages from the new Service catalog without
/// changing its visual/payment workflow.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  static const Map<String, String> _canonicalAliases = {
    'bagatmobileget': 'yemen_mobile_packages',
    'bagatsabafonget': 'sabafon_packages',
    'bagatyouget': 'you_packages',
    'bagatwayget': 'wai_packages',
    'yemen4g_packages_list': 'yemen4g_packages',
    'yemen_net_packages_list': 'yemen_net_adsl',
  };

  void _bridgeCanonicalPackageSettings(AppController app) {
    for (final entry in _canonicalAliases.entries) {
      final source = app.serviceSettingsObjectMap[entry.value];
      if (source == null) continue;
      final serviceId = int.tryParse('${source['service_id'] ?? ''}');
      if (serviceId == null || serviceId <= 0) continue;
      app.serviceSettingsMap[entry.key] = serviceId;
      final alias = Map<String, dynamic>.from(source);
      alias['key'] = entry.key;
      app.serviceSettingsObjectMap[entry.key] = alias;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    _bridgeCanonicalPackageSettings(app);
    return const legacy.PaymentScreen(key: ValueKey('canonical-payment-screen'));
  }
}
