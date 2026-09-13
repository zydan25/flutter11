import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../core/app_controller.dart';
import '../widgets/common.dart';
import 'screen_common.dart';

class FingerprintSettingsScreen extends StatefulWidget {
  const FingerprintSettingsScreen({super.key});
  @override State<FingerprintSettingsScreen> createState() => _FingerprintSettingsScreenState();
}

class _FingerprintSettingsScreenState extends State<FingerprintSettingsScreen> {
  static const storage = FlutterSecureStorage();
  final auth = LocalAuthentication();
  bool biometricLogin = true;
  bool biometricTransactions = true;
  bool hideBalance = false;
  bool pushNotifications = true;
  int autoLockMinutes = 5;
  bool available = false;
  bool testing = false;
  String? result;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      available = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      biometricLogin = (await storage.read(key:'shopik_biometric_enabled')) != 'false';
      biometricTransactions = (await storage.read(key:'shopik_biometric_transactions')) != 'false';
      hideBalance = (await storage.read(key:'shopik_hide_balance')) == 'true';
      pushNotifications = (await storage.read(key:'shopik_push_notifications')) != 'false';
      autoLockMinutes = int.tryParse(await storage.read(key:'shopik_auto_lock_minutes') ?? '') ?? 5;
    } catch (_) {}
    if (mounted) setState(() {});
  }
  Future<void> _save(String key, String value) => storage.write(key:key,value:value);
  Future<void> _toggleLogin(bool value) async {
    if (value) {
      if (!available) { if (mounted) setState(() => result = 'البصمة غير متاحة على هذا الجهاز.'); return; }
      if (!await auth.authenticate(localizedReason:'يرجى لمس مستشعر البصمة لتفعيل الدخول السريع')) return;
    }
    setState(() => biometricLogin = value);
    await _save('shopik_biometric_enabled', '$value');
  }
  Future<void> _test() async {
    setState(() { testing = true; result = null; });
    try {
      final ok = available && await auth.authenticate(localizedReason:'فحص وتجربة مستشعر البصمة الآن');
      if (mounted) setState(() => result = ok ? 'تمت المصادقة بالبصمة الحقيقية بنجاح تام ✓' : 'لم يتم التحقق من البصمة.');
    } catch (e) { if (mounted) setState(() => result = e.toString()); }
    finally { if (mounted) setState(() => testing = false); }
  }
  Widget _switch(String title,String subtitle,IconData icon,bool value,ValueChanged<bool> onChanged,{Color color=AppColors.burgundy}) => SwitchListTile.adaptive(contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:1),secondary:Container(width:40,height:40,decoration:BoxDecoration(color:color.withOpacity(.08),borderRadius:BorderRadius.circular(13)),child:Icon(icon,color:color,size:22)),title:Text(title,style:const TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),subtitle:Text(subtitle,style:const TextStyle(fontSize:9,color:AppColors.muted)),value:value,activeThumbColor:color,onChanged:onChanged);

  @override Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return ScreenFrame(title:'إعدادات البصمة والحماية',color:AppColors.burgundy,actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded)),IconButton(onPressed:app.logout,icon:const Icon(Icons.logout_rounded))],child:ListView(padding:const EdgeInsets.all(12),children:[
      PageCard(child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFFFF1F2),borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFFECACA))),child:const Icon(Icons.fingerprint_rounded,color:AppColors.burgundy,size:28)),const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('المصادقة البيومترية (Android Biometric / Keystore)',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('مفتاح الجلسة محفوظ بطريقة آمنة داخل الجهاز',style:TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w600))])),StatusBadge(text:available?'متاح ✓':'غير متاح',color:available?AppColors.emerald:Colors.red)])),
      if(result!=null)...[const SizedBox(height:8),Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:AppColors.emerald,borderRadius:BorderRadius.circular(15)),child:Text(result!,style:const TextStyle(color:Colors.white,fontSize:9.5,fontWeight:FontWeight.w900)))],
      const SizedBox(height:9),
      PageCard(padding:EdgeInsets.zero,child:Column(children:[_switch('تسجيل الدخول السريع بالبصمة','تخطي كتابة كلمة المرور وفتح التطبيق بالبصمة',Icons.fingerprint_rounded,biometricLogin,_toggleLogin),const Divider(height:1),_switch('طلب البصمة قبل تأكيد عمليات التسديد','حماية إضافية قبل خصم الرصيد أو تنفيذ التحويل',Icons.security_rounded,biometricTransactions,(v){setState(()=>biometricTransactions=v);_save('shopik_biometric_transactions','$v');}),const Divider(height:1),ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:12),leading:const Icon(Icons.lock_clock_rounded,color:Color(0xFF475569)),title:const Text('القفل التلقائي للتطبيق',style:TextStyle(fontSize:11.5,fontWeight:FontWeight.w900)),subtitle:const Text('عند ترك التطبيق في الخلفية',style:TextStyle(fontSize:9,color:AppColors.muted)),trailing:DropdownButton<int>(value:autoLockMinutes,items:const[DropdownMenuItem(value:1,child:Text('دقيقة')),DropdownMenuItem(value:5,child:Text('5 دقائق')),DropdownMenuItem(value:15,child:Text('15 دقيقة')),DropdownMenuItem(value:30,child:Text('30 دقيقة'))],onChanged:(v){if(v!=null){setState(()=>autoLockMinutes=v);_save('shopik_auto_lock_minutes','$v');}}))])),
      const SizedBox(height:9),
      SizedBox(width:double.infinity,height:46,child:FilledButton.icon(onPressed:testing?null:_test,style:FilledButton.styleFrom(backgroundColor:AppColors.burgundy),icon:testing?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.fingerprint_rounded),label:Text(testing?'جاري قراءة البصمة...':'فحص وتجربة مستشعر البصمة الآن',style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w900)))),
      const SizedBox(height:9),
      PageCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('تفضيلات الخصوصية والإشعارات',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900)),const SizedBox(height:5),_switch('إخفاء الرصيد تلقائياً','إخفاء الرصيد عند فتح التطبيق لحماية الخصوصية',Icons.visibility_off_rounded,hideBalance,(v){setState(()=>hideBalance=v);_save('shopik_hide_balance','$v');},color:const Color(0xFF475569)),const Divider(),_switch('إشعارات العمليات الفورية','تنبيهات وصول الحوالات ونتائج السداد',Icons.notifications_active_rounded,pushNotifications,(v){setState(()=>pushNotifications=v);_save('shopik_push_notifications','$v');},color:const Color(0xFF475569))])),
      const SizedBox(height:9),
      PageCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Row(children:[Icon(Icons.dns_rounded,color:AppColors.burgundy,size:17),SizedBox(width:6),Text('عنوان الخادم المركزي (Backend URL)',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900))]),const SizedBox(height:8),const Text('https://shopik.alattab.site',textDirection:TextDirection.ltr,style:TextStyle(fontSize:10,fontWeight:FontWeight.w900)),const SizedBox(height:4),const Text('الخادم الرسمي المعتمد: shopik.alattab.site',style:TextStyle(fontSize:9,color:AppColors.muted,fontWeight:FontWeight.w700))])),
      const SizedBox(height:9),
      PageCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('بيانات الجلسة الحالية',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900)),const SizedBox(height:5),_Line('رقم الهاتف',app.user?.phone??'-'),_Line('حالة التخزين','محفوظ في التخزين الآمن',color:AppColors.emerald),_Line('الخادم','shopik.alattab.site') ])),
      const SizedBox(height:9),
      OutlinedButton.icon(onPressed:app.logout,style:OutlinedButton.styleFrom(foregroundColor:Colors.red,side:const BorderSide(color:Color(0xFFFECACA))),icon:const Icon(Icons.logout_rounded),label:const Text('تسجيل الخروج من الحساب',style:TextStyle(fontWeight:FontWeight.w900))),
    ]));
  }
}
class _Line extends StatelessWidget { const _Line(this.a,this.b,{this.color}); final String a,b; final Color? color; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(a,style:const TextStyle(fontSize:9,color:AppColors.muted)),Flexible(child:Text(b,textAlign:TextAlign.left,style:TextStyle(fontSize:9.5,fontWeight:FontWeight.w900,color:color??const Color(0xFF0F172A))))])); }
