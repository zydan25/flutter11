import 'package:flutter/material.dart';
import '../models/models.dart';
import 'reference_home.dart';
import 'reference_store.dart';
import 'reference_account_clean.dart';
import 'reference_security.dart';
import 'statement_screen.dart' as stmt;
import 'transfer_screen.dart' as trf;
import 'wifi_screen.dart' as wf;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const MainHomeScreen();
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) => const GamesServicesScreen();
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) => const UserProfileEditScreen();
}

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const OperationsView();
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => const OrdersDetailView();
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final dynamic product;
  @override
  Widget build(BuildContext context) {
    final prod = product is Product
        ? product as Product
        : Product.fromJson(product is Map ? Map<String, dynamic>.from(product) : <String, dynamic>{});
    return ProductDetailView(product: prod);
  }
}

class StatementScreen extends StatelessWidget {
  const StatementScreen({super.key});
  @override
  Widget build(BuildContext context) => const stmt.StatementScreen();
}

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) => const StoreView();
}

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});
  @override
  Widget build(BuildContext context) => const trf.TransferScreen();
}

class WifiScreen extends StatelessWidget {
  const WifiScreen({super.key});
  @override
  Widget build(BuildContext context) => const wf.WifiScreen();
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const FingerprintSettingsScreen();
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => const UserProfileEditScreen();
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const OperationsView();
}


