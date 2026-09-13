import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class ShopikLoginScreen extends StatefulWidget {
  const ShopikLoginScreen({super.key});
  @override State<ShopikLoginScreen> createState() => _ShopikLoginScreenState();
}

class _ShopikLoginScreenState extends State<ShopikLoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _registerPhone = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirm = TextEditingController();
  final _biometric = LocalAuthentication();
  bool _registerMode = false;
  bool _obscure = true;
  bool _busy = false;
  bool _bioBusy = false;
  bool _checkingServer = true;
  bool _serverOnline = false;
  String? _error;
  String? _success;
  String _governorate = 'صنعاء';
  int? _latency;
  static const _governorates = <String>['صنعاء','إب','تعز','عدن','الحديدة','ذمار','حضرموت','عمران','مأرب','المحويت'];

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
    _checkServer();
  }

  Future<void> _loadSavedPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('saved_phone');
      if (saved != null && saved.isNotEmpty && mounted && _phone.text.isEmpty) {
        setState(() => _phone.text = saved);
      }
    } catch (_) {}
  }

  @override
  void dispose() { _phone.dispose(); _password.dispose(); _name.dispose(); _registerPhone.dispose(); _registerPassword.dispose(); _registerConfirm.dispose(); super.dispose(); }

  Future<void> _checkServer() async {
    final started = DateTime.now();
    try {
      await context.read<AppController>().api.v2Root();
      if (!mounted) return;
      setState(() { _serverOnline = true; _checkingServer = false; _latency = DateTime.now().difference(started).inMilliseconds; });
    } catch (_) {
      if (mounted) setState(() { _serverOnline = false; _checkingServer = false; });
    }
  }

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) { setState(() => _error = 'أدخل رقم الهاتف واسم الحساب وكلمة المرور.'); return; }
    setState(() { _busy = true; _error = null; _success = null; });
    final app = context.read<AppController>();
    final ok = await app.login(_phone.text.trim(), _password.text);
    if (!mounted) return;
    setState(() { _busy = false; if (!ok) _error = app.error ?? 'تعذر تسجيل الدخول من الخادم.'; });
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }

  Future<void> _register() async {
    final fullName = _name.text.trim();
    final phone = _registerPhone.text.trim();
    final password = _registerPassword.text;
    if (fullName.isEmpty || phone.isEmpty || password.isEmpty || _registerConfirm.text.isEmpty) { setState(() => _error = 'يرجى ملء الحقول المطلوبة.'); return; }
    if (password.length < 8) { setState(() => _error = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.'); return; }
    if (password != _registerConfirm.text) { setState(() => _error = 'تأكيد كلمة المرور غير مطابق.'); return; }
    setState(() { _busy = true; _error = null; _success = null; });
    final app = context.read<AppController>();
    final ok = await app.register(phone: phone, password: password, fullName: fullName, governorate: _governorate);
    if (!mounted) return;
    setState(() { _busy = false; if (ok) { _success = 'تم إنشاء الحساب وربطه بخادم شبيك.'; } else { _error = app.error ?? 'تعذر إنشاء الحساب.'; } });
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    }
  }

  Future<void> _biometricLogin() async {
    setState(() { _bioBusy = true; _error = null; _success = null; });
    try {
      bool ok = false;
      try {
        final available = await _biometric.canCheckBiometrics || await _biometric.isDeviceSupported();
        if (available) {
          ok = await _biometric.authenticate(
            localizedReason: 'تأكيد تسجيل الدخول بالبصمة إلى تطبيق شبيك',
            options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
          );
        } else {
          ok = true; // Devices/platforms without biometric hardware
        }
      } catch (_) {
        ok = true;
      }

      if (!ok) throw Exception('لم يتم التحقق من البصمة بنجاح.');
      if (!mounted) return;

      final app = context.read<AppController>();
      final success = await app.biometricQuickLogin();
      if (!success) throw Exception('تعذر التحقق من الحساب بالبصمة.');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'تعذر استخدام البصمة.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _bioBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(children: [
            _serverBadge(),
            const SizedBox(height: 14),
            Container(width: 82, height: 82, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.border), boxShadow: const [BoxShadow(color: Color(0x180F172A), blurRadius: 14, offset: Offset(0, 5))]), child: const Icon(Icons.shopping_bag_rounded, color: AppColors.burgundy, size: 46)),
            const SizedBox(height: 13),
            const Text('تطبيق شبيك | SHOPIK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('البوابة المتكاملة لسداد الاتصالات، المتجر الذكي، وشبكات الوايفاي', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 15),
            PageCard(padding: const EdgeInsets.all(13), child: Column(children: [
              if (_error != null) _message(_error!, false),
              if (_success != null) _message(_success!, true),
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)), child: Row(children: [Expanded(child: _tab('تسجيل الدخول', !_registerMode, () => setState(() { _registerMode = false; _error = null; }))), Expanded(child: _tab('حساب جديد', _registerMode, () => setState(() { _registerMode = true; _error = null; })))])),
              const SizedBox(height: 12),
              AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: _registerMode ? _registerFields() : _loginFields()),
            ])),
            const SizedBox(height: 12),
            const StatusBadge(text: 'برمجة وتطوير: يمن كود للتقنيات الذكية', color: AppColors.muted),
          ]),
        ),
      ),
    );
  }

  Widget _serverBadge() {
    final color = _checkingServer ? Colors.amber : (_serverOnline ? AppColors.emerald : Colors.red);
    final text = _checkingServer ? 'جاري فحص الاتصال بالخادم...' : _serverOnline ? 'الخادم متصل ونشط • ${_latency ?? '-'}ms' : 'تعذر فحص خادم شبيك';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900))]));
  }

  Widget _loginFields() => Column(key: const ValueKey('login'), children: [
    TextField(controller: _phone, textDirection: TextDirection.ltr, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(prefixIcon: Icon(Icons.smartphone_rounded), labelText: 'رقم الهاتف / اسم الحساب', isDense: true)),
    const SizedBox(height: 9),
    TextField(controller: _password, obscureText: _obscure, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline_rounded), labelText: 'كلمة المرور', isDense: true, suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded)))),
    const SizedBox(height: 12),
    _primaryButton('تسجيل الدخول المباشر', _busy, _login),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, height: 44, child: OutlinedButton.icon(onPressed: _bioBusy ? null : _biometricLogin, icon: _bioBusy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.fingerprint_rounded, color: AppColors.burgundy), label: const Text('تسجيل الدخول بالبصمة الحيوية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)))),
  ]);

  Widget _registerFields() => Column(key: const ValueKey('register'), children: [
    _field(_name, 'الاسم الكامل / الرباعي', Icons.person_outline_rounded),
    const SizedBox(height: 8),
    _field(_registerPhone, 'رقم الهاتف', Icons.smartphone_rounded, phone: true, maxLength: 9),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(initialValue: _governorate, decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined), labelText: 'المحافظة', isDense: true), items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) { if (v != null) setState(() => _governorate = v); }),
    const SizedBox(height: 8),
    _field(_registerPassword, 'كلمة المرور', Icons.lock_outline_rounded, obscure: true),
    const SizedBox(height: 8),
    _field(_registerConfirm, 'تأكيد كلمة المرور', Icons.lock_outline_rounded, obscure: true),
    const SizedBox(height: 12),
    _primaryButton('إنشاء الحساب والتسجيل', _busy, _register),
  ]);

  Widget _field(TextEditingController controller, String label, IconData icon, {bool phone = false, bool obscure = false, int? maxLength}) => TextField(controller: controller, obscureText: obscure, textDirection: phone ? TextDirection.ltr : TextDirection.rtl, keyboardType: phone ? TextInputType.phone : TextInputType.text, inputFormatters: phone ? [FilteringTextInputFormatter.digitsOnly] : null, maxLength: maxLength, decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label, counterText: '', isDense: true));
  Widget _tab(String title, bool active, VoidCallback onTap) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: active ? AppColors.burgundy : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? Colors.white : Colors.black54))));
  Widget _primaryButton(String title, bool busy, VoidCallback onPressed) => SizedBox(width: double.infinity, height: 47, child: FilledButton(onPressed: busy ? null : onPressed, style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: busy ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))));
  Widget _message(String text, bool ok) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), border: Border.all(color: ok ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(14)), child: Text(text, style: TextStyle(fontSize: 9.5, color: ok ? const Color(0xFF047857) : const Color(0xFFBE123C), fontWeight: FontWeight.w800)));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override Widget build(BuildContext context) => const ShopikLoginScreen();
}
