import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/app_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppController(ApiClient()), child: const ShopikApp()));
}

class ShopikApp extends StatefulWidget {
  const ShopikApp({super.key});
  @override State<ShopikApp> createState() => _ShopikAppState();
}

class _ShopikAppState extends State<ShopikApp> {
  bool booting = true;
  @override void initState() { super.initState(); _boot(); }
  Future<void> _boot() async {
    await context.read<AppController>().restore();
    if (mounted) setState(() => booting = false);
  }
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'شبيك باي | SHOPIK PAY',
    locale: const Locale('ar'),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.burgundy),
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(centerTitle: true, backgroundColor: AppColors.burgundy, foregroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.burgundy, width: 1.5)),
      ),
    ),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
    home: booting ? const _Splash() : Consumer<AppController>(builder: (_, app, __) => app.isLoggedIn ? const HomeShell() : const ShopikLoginScreen()),
  );
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: AppColors.burgundy), SizedBox(height: 18), Text('شبيك SHOPIK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)), SizedBox(height: 6), Text('جاري تهيئة التطبيق والاتصال بالخادم', style: TextStyle(fontSize: 10, color: AppColors.muted))])));
}
