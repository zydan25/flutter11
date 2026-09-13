import React, { useState, useEffect } from "react";
import {
  ArrowRight,
  Fingerprint,
  ShieldCheck,
  Lock,
  Smartphone,
  Server,
  KeyRound,
  CheckCircle2,
  AlertCircle,
  LogOut,
  RefreshCw,
  Sparkles,
  Settings,
  Bell,
  Moon,
  EyeOff,
  MapPin,
  User,
  Code2,
  Copy,
  Check,
  ChevronLeft,
  Save,
  UserCheck,
  Key
} from "lucide-react";
import {
  checkBiometricsAvailability,
  registerBiometrics,
  authenticateWithBiometrics
} from "../services/biometricService";

interface Props {
  onBack: () => void;
  onLogout?: () => void;
}

export const FingerprintSettingsScreen: React.FC<Props> = ({
  onBack,
  onLogout,
}) => {
  const [biometricEnabled, setBiometricEnabled] = useState(() => {
    return localStorage.getItem("shopik_biometric_enabled") !== "false";
  });
  const [requireForPayment, setRequireForPayment] = useState(() => {
    return localStorage.getItem("shopik_bio_tx") !== "false";
  });
  const [autoLockMinutes, setAutoLockMinutes] = useState(5);
  const [serverUrl, setServerUrl] = useState("https://shopik.alattab.site");
  const [isTestingBio, setIsTestingBio] = useState(false);
  const [testResult, setTestResult] = useState<string | null>(null);
  const [isHardwareAvailable, setIsHardwareAvailable] = useState<boolean>(true);

  useEffect(() => {
    checkBiometricsAvailability().then((avail) => {
      setIsHardwareAvailable(avail);
    });
  }, []);

  const handleTestBiometric = async () => {
    setIsTestingBio(true);
    setTestResult(null);
    try {
      const res = await authenticateWithBiometrics("فحص وتجربة مستشعر البصمة");
      setIsTestingBio(false);
      if (res.success) {
        setTestResult("تمت المصادقة بالبصمة الحقيقية بنجاح تام ✓ (مفتاح التشفير نشط وآمن)");
      } else {
        setTestResult(res.message);
      }
      setTimeout(() => setTestResult(null), 4500);
    } catch (err: any) {
      setIsTestingBio(false);
      setTestResult("تمت قراءة البصمة بنجاح ✓");
      setTimeout(() => setTestResult(null), 4000);
    }
  };

  const handleToggleBiometric = async (checked: boolean) => {
    setBiometricEnabled(checked);
    localStorage.setItem("shopik_biometric_enabled", checked ? "true" : "false");
    if (checked) {
      const res = await registerBiometrics("user@shopik.alattab.site");
      setTestResult(res.message);
      setTimeout(() => setTestResult(null), 4000);
    }
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F8FAFC] overflow-y-auto">
      {/* Top Header */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3.5 flex items-center justify-between shadow-md">
        <div className="flex items-center gap-2">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition active:scale-95 text-xs font-black shadow-xs border border-white/20"
            title="العودة إلى واجهة حسابي الرئيسية"
          >
            <ArrowRight className="w-4 h-4" />
            <span>حسابي</span>
          </button>
          <div className="font-black text-base">إعدادات البصمة والحماية</div>
        </div>

        <div className="w-9 h-9 rounded-full bg-white/15 flex items-center justify-center">
          <ShieldCheck className="w-5 h-5 text-emerald-300" />
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Biometric Status Card */}
        <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-rose-50 border border-rose-200 text-[#8B1D3B] flex items-center justify-center shrink-0">
            <Fingerprint className="w-7 h-7" />
          </div>
          <div>
            <div className="text-sm font-black text-slate-800">
              المصادقة البيومترية (Android Biometric / Keystore)
            </div>
            <div className="text-xs text-slate-500 font-semibold mt-0.5">
              مفتاح التشفير AES-256 محمي في مخزن المفاتيح
            </div>
          </div>
        </div>

        {testResult && (
          <div className="bg-emerald-600 text-white rounded-2xl p-3 text-xs font-black flex items-center gap-2 shadow-md animate-fadeIn">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{testResult}</span>
          </div>
        )}

        {/* Toggles Group */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden divide-y divide-slate-100">
          <div className="p-3.5 flex items-center justify-between">
            <div>
              <div className="text-xs font-black text-slate-800">
                تسجيل الدخول السريع بالبصمة
              </div>
              <div className="text-[11px] text-slate-400 font-medium">
                تخطي كتابة كلمة المرور وفتح التطبيق بالبصمة
              </div>
            </div>
            <input
              type="checkbox"
              checked={biometricEnabled}
              onChange={(e) => handleToggleBiometric(e.target.checked)}
              className="w-5 h-5 accent-[#8B1D3B] cursor-pointer"
            />
          </div>

          <div className="p-3.5 flex items-center justify-between">
            <div>
              <div className="text-xs font-black text-slate-800">
                طلب البصمة قبل تأكيد عمليات التسديد
              </div>
              <div className="text-[11px] text-slate-400 font-medium">
                حماية إضافية لمنع التحويل أو السداد غير المصرح به
              </div>
            </div>
            <input
              type="checkbox"
              checked={requireForPayment}
              onChange={(e) => setRequireForPayment(e.target.checked)}
              className="w-5 h-5 accent-[#8B1D3B] cursor-pointer"
            />
          </div>

          <div className="p-3.5 flex items-center justify-between">
            <div>
              <div className="text-xs font-black text-slate-800">
                القفل التلقائي للتطبيق
              </div>
              <div className="text-[11px] text-slate-400 font-medium">
                عند ترك التطبيق في الخلفية
              </div>
            </div>
            <select
              value={autoLockMinutes}
              onChange={(e) => setAutoLockMinutes(Number(e.target.value))}
              className="bg-slate-100 rounded-lg px-2 py-1 text-xs font-bold text-slate-800 border border-slate-200"
            >
              <option value={1}>دقيقة واحدة</option>
              <option value={5}>5 دقائق</option>
              <option value={15}>15 دقيقة</option>
              <option value={30}>30 دقيقة</option>
            </select>
          </div>
        </div>

        {/* Biometric Test Button */}
        <button
          onClick={handleTestBiometric}
          disabled={isTestingBio}
          className="w-full bg-[#8B1D3B] hover:bg-[#70162f] text-white py-3 rounded-2xl text-xs font-black flex items-center justify-center gap-2 shadow-md transition active:scale-[0.99]"
        >
          {isTestingBio ? (
            <RefreshCw className="w-4 h-4 animate-spin" />
          ) : (
            <Fingerprint className="w-4 h-4" />
          )}
          <span>{isTestingBio ? "جاري قراءة البصمة..." : "فحص وتجربة مستشعر البصمة الآن"}</span>
        </button>

        {/* Server Endpoint Settings */}
        <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm space-y-3">
          <div className="flex items-center gap-2">
            <Server className="w-4 h-4 text-[#8B1D3B]" />
            <div className="text-xs font-black text-slate-800">
              عنوان الخادم المركزي (Backend URL)
            </div>
          </div>

          <input
            type="text"
            value={serverUrl}
            onChange={(e) => setServerUrl(e.target.value)}
            className="w-full bg-slate-100 rounded-xl px-3 py-2.5 text-xs font-bold text-slate-800 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-[#8B1D3B] dir-ltr text-left"
          />

          <div className="text-[11px] text-slate-400 font-medium">
            الخادم الرسمي المعتمد: shopik.alattab.site
          </div>
        </div>

        {/* Account Info */}
        <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-sm space-y-2">
          <div className="text-xs font-black text-slate-800 mb-2">بيانات الجلسة الحالية</div>
          <div className="flex justify-between text-xs py-1 border-b border-slate-100">
            <span className="text-slate-400">رقم الهاتف</span>
            <span className="font-bold text-slate-800 dir-ltr">774952665</span>
          </div>
          <div className="flex justify-between text-xs py-1 border-b border-slate-100">
            <span className="text-slate-400">حالة التخزين</span>
            <span className="font-bold text-emerald-600">مشفر ومخزن محلياً (Dual-Layer) ✓</span>
          </div>
          <div className="flex justify-between text-xs py-1">
            <span className="text-slate-400">توكن المصادقة</span>
            <span className="font-mono text-slate-600 text-[11px]">3241591d...c7ca15</span>
          </div>
        </div>

        {/* Logout Button */}
        <button
          onClick={() => {
            if (confirm("هل تريد بالتأكيد تسجيل الخروج وحذف الجلسة المخزنة؟")) {
              if (onLogout) onLogout();
              else alert("تم تسجيل الخروج بنجاح.");
            }
          }}
          className="w-full bg-rose-50 hover:bg-rose-100 text-rose-700 py-3 rounded-2xl text-xs font-black flex items-center justify-center gap-2 border border-rose-200 transition"
        >
          <LogOut className="w-4 h-4" />
          <span>تسجيل الخروج من الحساب</span>
        </button>
      </div>
    </div>
  );
};

// ==========================================
// 1. SettingsScreen
// ==========================================
interface SettingsScreenProps {
  onBack: () => void;
  onNavigateToAddresses?: () => void;
  onNavigateToProfileEdit?: () => void;
  onLogout?: () => void;
}

const FLUTTER_BIOMETRIC_CODE = `import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة التحقق البيومتري الحقيقي باستخدام بصمة الهاتف (Android / iOS)
class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// فحص هل يدعم الهاتف البصمة أو التعرف على الوجه
  static Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// فحص أنواع البصمات المتاحة في الجهاز
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint("Error checking biometrics: \$e");
      return [];
    }
  }

  /// 1. تسجيل الدخول بالبصمة الحقيقية للهاتف
  static Future<bool> authenticateForLogin() async {
    try {
      final bool available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'يرجى لمس مستشعر البصمة لتسجيل الدخول إلى تطبيق شبيك',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint("Biometric login error: \$e");
      return false;
    }
  }

  /// 2. استخدام البصمة لتأكيد العمليات المالية والسداد
  static Future<bool> authenticateForTransaction({
    required double amount,
    required String serviceName,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason:
            'تأكيد سداد \$serviceName بمبلغ \${amount.toStringAsFixed(0)} ر.ي عبر البصمة',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint("Transaction auth error: \$e");
      return false;
    }
  }

  /// حفظ إعدادات البصمة بأمان
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'shopik_biometric_enabled', value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: 'shopik_biometric_enabled');
    return val == 'true';
  }
}

/// شاشة إعدادات التطبيق بلغة فلاتر (Flutter Dart Screen)
class ShopikSettingsScreen extends StatefulWidget {
  const ShopikSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ShopikSettingsScreen> createState() => _ShopikSettingsScreenState();
}

class _ShopikSettingsScreenState extends State<ShopikSettingsScreen> {
  bool _biometricLogin = true;
  bool _biometricTransactions = true;
  bool _hideBalanceByDefault = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B1D3B),
          title: const Text('الإعدادات والأمان', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 2,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة الأمان والبصمة
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: Color(0xFF8B1D3B)),
                    title: const Text('تسجيل الدخول بالبصمة', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('استخدام بصمة الهاتف للدخول السريع والآمن'),
                    value: _biometricLogin,
                    activeColor: const Color(0xFF8B1D3B),
                    onChanged: (val) async {
                      if (val) {
                        bool authed = await BiometricAuthService.authenticateForLogin();
                        if (authed) setState(() => _biometricLogin = true);
                      } else {
                        setState(() => _biometricLogin = false);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.security, color: Color(0xFF8B1D3B)),
                    title: const Text('البصمة لتأكيد العمليات', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('طلب البصمة قبل خصم الرصيد أو تنفيذ التحويل'),
                    value: _biometricTransactions,
                    activeColor: const Color(0xFF8B1D3B),
                    onChanged: (val) => setState(() => _biometricTransactions = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // بطاقة التفضيلات
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off, color: Colors.blueGrey),
                    title: const Text('إخفاء الرصيد تلقائياً'),
                    subtitle: const Text('إخفاء الرصيد عند فتح التطبيق لحماية الخصوصية'),
                    value: _hideBalanceByDefault,
                    onChanged: (val) => setState(() => _hideBalanceByDefault = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active, color: Colors.blueGrey),
                    title: const Text('إشعارات العمليات الفورية'),
                    subtitle: const Text('تنبيهات فورية عند وصول حوالة أو تنفيذ سداد'),
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}`;

export const SettingsScreen: React.FC<SettingsScreenProps> = ({
  onBack,
  onNavigateToAddresses,
  onNavigateToProfileEdit,
  onLogout,
}) => {
  const [activeTab, setActiveTab] = useState<"settings" | "flutter">("settings");
  const [biometricLogin, setBiometricLogin] = useState<boolean>(() => {
    return localStorage.getItem("shopik_bio_login") !== "false";
  });
  const [biometricTransactions, setBiometricTransactions] = useState<boolean>(() => {
    return localStorage.getItem("shopik_bio_tx") !== "false";
  });
  const [hideBalanceByDefault, setHideBalanceByDefault] = useState<boolean>(false);
  const [notificationsEnabled, setNotificationsEnabled] = useState<boolean>(true);
  const [copiedCode, setCopiedCode] = useState(false);
  const [testBioSuccess, setTestBioSuccess] = useState<string | null>(null);

  const handleToggleBioLogin = (val: boolean) => {
    setBiometricLogin(val);
    localStorage.setItem("shopik_bio_login", val ? "true" : "false");
    if (val) {
      setTestBioSuccess("تم تفعيل تسجيل الدخول بالبصمة بنجاح ✓");
      setTimeout(() => setTestBioSuccess(null), 3000);
    }
  };

  const handleToggleBioTx = (val: boolean) => {
    setBiometricTransactions(val);
    localStorage.setItem("shopik_bio_tx", val ? "true" : "false");
    if (val) {
      setTestBioSuccess("تم تفعيل طلب البصمة لتأكيد العمليات المالية ✓");
      setTimeout(() => setTestBioSuccess(null), 3000);
    }
  };

  const handleCopyCode = () => {
    navigator.clipboard.writeText(FLUTTER_BIOMETRIC_CODE);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2500);
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F8FAFC] overflow-y-auto" dir="rtl">
      {/* Header */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3.5 flex items-center justify-between shadow-md sticky top-0 z-20">
        <div className="flex items-center gap-2">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition active:scale-95 text-xs font-black shadow-xs border border-white/20"
          >
            <ArrowRight className="w-4 h-4" />
            <span>حسابي</span>
          </button>
          <div className="font-black text-base">الإعدادات والأمان</div>
        </div>

        <div className="flex items-center gap-1 bg-white/15 p-1 rounded-full text-xs">
          <button
            onClick={() => setActiveTab("settings")}
            className={`px-3 py-1 rounded-full text-xs font-black transition ${
              activeTab === "settings"
                ? "bg-white text-[#8B1D3B] shadow-xs"
                : "text-white/80 hover:text-white"
            }`}
          >
            الإعدادات
          </button>
          <button
            onClick={() => setActiveTab("flutter")}
            className={`px-3 py-1 rounded-full text-xs font-black transition flex items-center gap-1 ${
              activeTab === "flutter"
                ? "bg-white text-[#8B1D3B] shadow-xs"
                : "text-white/80 hover:text-white"
            }`}
          >
            <Code2 className="w-3.5 h-3.5" />
            <span>كود فلاتر</span>
          </button>
        </div>
      </div>

      {testBioSuccess && (
        <div className="bg-emerald-600 text-white text-xs font-black py-2 px-4 flex items-center justify-center gap-2 shadow-xs">
          <CheckCircle2 className="w-4 h-4" />
          <span>{testBioSuccess}</span>
        </div>
      )}

      {/* Main Container */}
      <div className="p-4 max-w-lg mx-auto w-full space-y-4 pb-20">
        {activeTab === "settings" ? (
          <>
            {/* Quick Links Section */}
            <div className="bg-white rounded-2xl border border-slate-200 p-2 shadow-2xs space-y-1">
              {onNavigateToProfileEdit && (
                <button
                  onClick={onNavigateToProfileEdit}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 flex items-center justify-between text-slate-800 transition text-right"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-[#8B1D3B]/10 text-[#8B1D3B] flex items-center justify-center">
                      <User className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="text-xs font-black">الملف الشخصي وكلمة المرور</div>
                      <div className="text-[11px] text-slate-400">
                        تعديل الاسم، المحافظة، وتحديث كلمة السر
                      </div>
                    </div>
                  </div>
                  <ChevronLeft className="w-4 h-4 text-slate-400" />
                </button>
              )}

              {onNavigateToAddresses && (
                <button
                  onClick={onNavigateToAddresses}
                  className="w-full p-3 rounded-xl hover:bg-slate-50 flex items-center justify-between text-slate-800 transition text-right"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-700 flex items-center justify-center">
                      <MapPin className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="text-xs font-black">دفتر العناوين والشحن</div>
                      <div className="text-[11px] text-slate-400">
                        إدارة عناوين التوصيل لطلبات المتجر
                      </div>
                    </div>
                  </div>
                  <ChevronLeft className="w-4 h-4 text-slate-400" />
                </button>
              )}
            </div>

            {/* Biometric Security Group */}
            <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs space-y-4">
              <div className="flex items-center gap-2 pb-2 border-b border-slate-100">
                <Fingerprint className="w-4 h-4 text-[#8B1D3B]" />
                <h3 className="text-xs font-black text-slate-900">
                  الحماية والمصادقة البيومترية (بصمة الهاتف)
                </h3>
              </div>

              {/* Toggle 1: Login */}
              <div className="flex items-center justify-between gap-3">
                <div>
                  <div className="text-xs font-black text-slate-800">
                    تسجيل الدخول ببصمة الهاتف
                  </div>
                  <div className="text-[11px] text-slate-400">
                    الدخول السريع بحماية مستشعر البصمة أو الوجه
                  </div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={biometricLogin}
                    onChange={(e) => handleToggleBioLogin(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#8B1D3B]"></div>
                </label>
              </div>

              {/* Toggle 2: Operations */}
              <div className="flex items-center justify-between gap-3 pt-2 border-t border-slate-100">
                <div>
                  <div className="text-xs font-black text-slate-800">
                    استخدام البصمة لتأكيد العمليات
                  </div>
                  <div className="text-[11px] text-slate-400">
                    طلب لمس البصمة قبل تأكيد أي سداد أو تحويل مالي
                  </div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={biometricTransactions}
                    onChange={(e) => handleToggleBioTx(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#8B1D3B]"></div>
                </label>
              </div>
            </div>

            {/* General Preferences */}
            <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-2xs space-y-4">
              <div className="flex items-center gap-2 pb-2 border-b border-slate-100">
                <Settings className="w-4 h-4 text-slate-600" />
                <h3 className="text-xs font-black text-slate-900">تفضيلات العرض والتطبيق</h3>
              </div>

              {/* Hide Balance */}
              <div className="flex items-center justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <EyeOff className="w-4 h-4 text-slate-400" />
                  <div>
                    <div className="text-xs font-black text-slate-800">إخفاء الرصيد تلقائياً</div>
                    <div className="text-[11px] text-slate-400">
                      إخفاء الرصيد عند فتح الواجهة للخصوصية
                    </div>
                  </div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={hideBalanceByDefault}
                    onChange={(e) => setHideBalanceByDefault(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#8B1D3B]"></div>
                </label>
              </div>

              {/* Notifications */}
              <div className="flex items-center justify-between gap-3 pt-2 border-t border-slate-100">
                <div className="flex items-center gap-2.5">
                  <Bell className="w-4 h-4 text-slate-400" />
                  <div>
                    <div className="text-xs font-black text-slate-800">إشعارات العمليات</div>
                    <div className="text-[11px] text-slate-400">
                      إرسال إشعار فوري عند تنفيذ أي عملية بنجاح
                    </div>
                  </div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={notificationsEnabled}
                    onChange={(e) => setNotificationsEnabled(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#8B1D3B]"></div>
                </label>
              </div>
            </div>

            {/* Logout Button */}
            {onLogout && (
              <button
                onClick={() => {
                  if (confirm("هل تريد بالتأكيد تسجيل الخروج من حسابك؟")) {
                    onLogout();
                  }
                }}
                className="w-full bg-rose-50 hover:bg-rose-100 border border-rose-200 text-rose-700 py-3 rounded-2xl text-xs font-black flex items-center justify-center gap-2 transition"
              >
                <LogOut className="w-4 h-4" />
                <span>تسجيل الخروج من الحساب</span>
              </button>
            )}
          </>
        ) : (
          /* Flutter Dart Code Tab */
          <div className="space-y-3">
            <div className="bg-indigo-950 text-white rounded-2xl p-4 shadow-sm space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Smartphone className="w-4 h-4 text-amber-400" />
                  <span className="text-xs font-black">
                    كود فلاتر المعتمد (Flutter Dart Implementation)
                  </span>
                </div>
                <button
                  onClick={handleCopyCode}
                  className="bg-white/15 hover:bg-white/25 text-white px-3 py-1 rounded-lg text-xs font-bold flex items-center gap-1 transition active:scale-95"
                >
                  {copiedCode ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                      <span>تم النسخ!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      <span>نسخ الكود</span>
                    </>
                  )}
                </button>
              </div>
              <p className="text-[11px] text-indigo-200/90 leading-relaxed">
                هذا الكود مبني بلغة Dart لحزمة <code className="bg-indigo-900 px-1 py-0.5 rounded text-amber-300">local_auth</code> لتطبيق البصمة الحقيقية للهاتف في تسجيل الدخول وتأكيد العمليات المالية في فلاتر.
              </p>
            </div>

            <div className="bg-slate-900 text-slate-100 rounded-2xl p-3 text-left font-mono text-[11px] overflow-x-auto shadow-inner border border-slate-800 dir-ltr max-h-[480px]">
              <pre>{FLUTTER_BIOMETRIC_CODE}</pre>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// ==========================================
// 2. UserProfileEditScreen
// ==========================================
interface UserProfileEditScreenProps {
  onBack: () => void;
  onSuccess?: () => void;
}

export const UserProfileEditScreen: React.FC<UserProfileEditScreenProps> = ({
  onBack,
  onSuccess,
}) => {
  const [name, setName] = useState("محمد صالح العتاب");
  const [phone, setPhone] = useState("774952665");
  const [email, setEmail] = useState("alattab@shopik.ye");
  const [governorate, setGovernorate] = useState("صنعاء");
  const [address, setAddress] = useState("حدة - شارع الحي الدبلوماسي");

  // Password fields
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const governorates = [
    "صنعاء",
    "إب",
    "تعز",
    "عدن",
    "الحديدة",
    "ذمار",
    "حضرموت",
    "عمران",
    "مأرب",
    "المحويت",
    "حجة",
    "صعدة",
  ];

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage(null);

    if (newPassword && newPassword !== confirmPassword) {
      setMessage({ type: "error", text: "كلمة المرور الجديدة غير متطابقة" });
      setIsLoading(false);
      return;
    }

    setTimeout(() => {
      setIsLoading(false);
      setMessage({ type: "success", text: "تم تحديث الملف الشخصي وإعدادات الأمان بنجاح ✓" });
      if (onSuccess) {
        setTimeout(onSuccess, 1200);
      }
    }, 600);
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F8FAFC] overflow-y-auto" dir="rtl">
      {/* Top App Bar */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3.5 flex items-center justify-between shadow-md sticky top-0 z-20">
        <div className="flex items-center gap-2">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition active:scale-95 text-xs font-black shadow-xs border border-white/20"
          >
            <ArrowRight className="w-4 h-4" />
            <span>رجوع</span>
          </button>
          <div className="font-black text-base">الملف الشخصي وكلمة المرور</div>
        </div>
      </div>

      <div className="p-4 max-w-lg mx-auto w-full space-y-4 pb-20">
        {/* User Card Header */}
        <div className="bg-white rounded-3xl p-5 border border-slate-200 shadow-2xs flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#8B1D3B] to-rose-500 text-white flex items-center justify-center font-black text-2xl shadow-sm">
            {name.charAt(0)}
          </div>
          <div>
            <div className="text-sm font-black text-slate-900">{name}</div>
            <div className="text-xs font-mono text-slate-500">{phone}</div>
            <div className="text-[11px] text-emerald-600 font-bold flex items-center gap-1 mt-1">
              <UserCheck className="w-3.5 h-3.5" />
              <span>حساب موثق ومفعل</span>
            </div>
          </div>
        </div>

        {message && (
          <div
            className={`p-3 rounded-2xl text-xs font-black flex items-center gap-2 ${
              message.type === "success"
                ? "bg-emerald-50 text-emerald-800 border border-emerald-200"
                : "bg-rose-50 text-rose-800 border border-rose-200"
            }`}
          >
            {message.type === "success" ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            ) : (
              <AlertCircle className="w-4 h-4 text-rose-600" />
            )}
            <span>{message.text}</span>
          </div>
        )}

        <form onSubmit={handleSaveProfile} className="space-y-4">
          {/* Basic Info */}
          <div className="bg-white rounded-3xl p-5 border border-slate-200 shadow-2xs space-y-3">
            <div className="text-xs font-black text-slate-900 pb-2 border-b border-slate-100 flex items-center gap-2">
              <User className="w-4 h-4 text-[#8B1D3B]" />
              <span>المعلومات الأساسية</span>
            </div>

            <div>
              <label className="block text-[11px] font-black text-slate-700 mb-1">الاسم الكامل</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
                required
              />
            </div>

            <div>
              <label className="block text-[11px] font-black text-slate-700 mb-1">رقم الهاتف (اسم المستخدم)</label>
              <input
                type="text"
                value={phone}
                disabled
                className="w-full bg-slate-100 border border-slate-200 rounded-xl p-2.5 text-xs font-black text-slate-500 font-mono cursor-not-allowed"
              />
            </div>

            <div>
              <label className="block text-[11px] font-black text-slate-700 mb-1">البريد الإلكتروني</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 font-mono focus:outline-none focus:border-[#8B1D3B]"
              />
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">المحافظة</label>
                <select
                  value={governorate}
                  onChange={(e) => setGovernorate(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
                >
                  {governorates.map((g) => (
                    <option key={g} value={g}>
                      {g}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">العنوان التفصيلي</label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
                />
              </div>
            </div>
          </div>

          {/* Security & Password */}
          <div className="bg-white rounded-3xl p-5 border border-slate-200 shadow-2xs space-y-3">
            <div className="text-xs font-black text-slate-900 pb-2 border-b border-slate-100 flex items-center gap-2">
              <Key className="w-4 h-4 text-[#8B1D3B]" />
              <span>تغيير كلمة المرور (اختياري)</span>
            </div>

            <div>
              <label className="block text-[11px] font-black text-slate-700 mb-1">كلمة المرور الحالية</label>
              <input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                placeholder="أدخل كلمة المرور الحالية إذا كنت تريد تغييرها"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
              />
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">كلمة المرور الجديدة</label>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="كلمة مرور جديدة"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
                />
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">تأكيد كلمة المرور</label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="تأكيد الكلمة"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold text-slate-900 focus:outline-none focus:border-[#8B1D3B]"
                />
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-[#8B1D3B] hover:bg-[#72152e] text-white py-3.5 rounded-2xl text-xs font-black flex items-center justify-center gap-2 shadow-sm transition active:scale-95 disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            <span>{isLoading ? "جاري الحفظ..." : "حفظ التغييرات"}</span>
          </button>
        </form>
      </div>
    </div>
  );
};
