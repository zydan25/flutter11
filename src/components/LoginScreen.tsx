import React, { useState, useEffect } from "react";
import {
  ShoppingBag,
  Smartphone,
  Lock,
  Eye,
  EyeOff,
  User,
  MapPin,
  Fingerprint,
} from "lucide-react";
import {
  loginUser,
  registerUser,
  checkServerHealth,
  fetchLiveUserProfile,
} from "../services/apiService";
import { authenticateWithBiometrics } from "../services/biometricService";

interface Props {
  onLoginSuccess: (userData: {
    phone: string;
    token?: string;
    name: string;
    governorate?: string;
  }) => void;
}

const GOVERNORATES = [
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
];

export const LoginScreen: React.FC<Props> = ({ onLoginSuccess }) => {
  // Mode: login vs register (identical to _registerMode in Flutter)
  const [registerMode, setRegisterMode] = useState(false);

  // Login form controllers
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [obscure, setObscure] = useState(true);

  // Register form controllers
  const [regName, setRegName] = useState("");
  const [regPhone, setRegPhone] = useState("");
  const [regGovernorate, setRegGovernorate] = useState("صنعاء");
  const [regPassword, setRegPassword] = useState("");
  const [regConfirm, setRegConfirm] = useState("");

  // States
  const [busy, setBusy] = useState(false);
  const [bioBusy, setBioBusy] = useState(false);
  const [checkingServer, setCheckingServer] = useState(true);
  const [serverOnline, setServerOnline] = useState(false);
  const [latency, setLatency] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    checkServer();
  }, []);

  const checkServer = async () => {
    setCheckingServer(true);
    try {
      const res = await checkServerHealth();
      setServerOnline(res.isOnline);
      setCheckingServer(false);
      setLatency(res.latencyMs || 45);
    } catch {
      setServerOnline(false);
      setCheckingServer(false);
    }
  };

  const handleLogin = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!phone.trim() || !password) {
      setError("أدخل رقم الهاتف واسم الحساب وكلمة المرور.");
      return;
    }

    setBusy(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await loginUser(phone.trim(), password);
      setBusy(false);
      if (res.success) {
        localStorage.setItem("shopik_logged_in", "true");
        localStorage.setItem("shopik_user_phone", phone.trim());
        onLoginSuccess({
          phone: phone.trim(),
          token: res.token,
          name: res.user?.full_name || "زيدان محمد العطاب",
          governorate: "إب",
        });
      } else {
        setError(res.message || "تعذر تسجيل الدخول من الخادم.");
      }
    } catch (err: any) {
      setBusy(false);
      setError("حدث خطأ أثناء الاتصال بالخادم: " + (err.message || ""));
    }
  };

  const handleRegister = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const fullName = regName.trim();
    const rPhone = regPhone.trim();
    const pwd = regPassword;
    if (!fullName || !rPhone || !pwd || !regConfirm) {
      setError("يرجى ملء الحقول المطلوبة.");
      return;
    }
    if (pwd.length < 8) {
      setError("كلمة المرور يجب أن تكون 8 أحرف على الأقل.");
      return;
    }
    if (pwd !== regConfirm) {
      setError("تأكيد كلمة المرور غير مطابق.");
      return;
    }

    setBusy(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await registerUser({
        fullName,
        phone: rPhone,
        governorate: regGovernorate,
        password: pwd,
      });
      setBusy(false);
      if (res.success) {
        setSuccess("تم إنشاء الحساب وربطه بخادم شبيك.");
        setRegisterMode(false);
        setPhone(rPhone);
        setPassword(pwd);
      } else {
        setError(res.message || "تعذر إنشاء الحساب.");
      }
    } catch (err: any) {
      setBusy(false);
      setError("حدث خطأ أثناء الاتصال بالخادم: " + (err.message || ""));
    }
  };

  const handleBiometricLogin = async () => {
    setBioBusy(true);
    setError(null);
    setSuccess(null);

    try {
      const savedPhone = localStorage.getItem("shopik_user_phone");
      const savedLogin = localStorage.getItem("shopik_logged_in");
      if (!savedLogin || !savedPhone) {
        throw new Error("سجّل الدخول بكلمة المرور مرة واحدة قبل استخدام البصمة.");
      }

      const res = await authenticateWithBiometrics("تأكيد تسجيل الدخول إلى شبيك");
      if (!res.success) {
        throw new Error(res.message || "لم يتم التحقق من البصمة.");
      }
      
      const profile = await fetchLiveUserProfile();
      localStorage.setItem("shopik_logged_in", "true");
      onLoginSuccess({
        phone: savedPhone,
        token: localStorage.getItem("shopik_auth_token") || undefined,
        name: profile?.fullName || "مستخدم شبيك",
        governorate: profile?.governorate || "صنعاء",
      });
    } catch (err: any) {
      setError(err.message || "تعذر استخدام البصمة.");
    } finally {
      setBioBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F7F9FC] flex flex-col justify-center items-center p-4 selection:bg-[#8B1D3B]/20">
      <div className="w-full max-w-[390px] flex flex-col items-center">
        {/* Server Status Badge - Exactly matching Flutter _serverBadge() */}
        <div className="bg-white border border-slate-200 px-3 py-1.5 rounded-full flex items-center gap-1.5 shadow-2xs mb-3.5">
          <div
            className={`w-2 h-2 rounded-full ${
              checkingServer
                ? "bg-amber-400 animate-pulse"
                : serverOnline
                ? "bg-emerald-500"
                : "bg-rose-500"
            }`}
          />
          <span className="text-[9.5px] font-black text-slate-800">
            {checkingServer
              ? "جاري فحص الاتصال بالخادم..."
              : serverOnline
              ? `الخادم متصل ونشط • ${latency ?? "-"}ms`
              : "تعذر فحص خادم شبيك"}
          </span>
        </div>

        {/* 82x82 Rounded App Icon with burgundy shopping bag - Exactly matching Flutter */}
        <div className="w-[82px] h-[82px] bg-white rounded-[25px] border border-slate-200 flex items-center justify-center shadow-[0_5px_14px_rgba(15,23,42,0.09)] mb-3">
          <ShoppingBag className="w-[46px] h-[46px] text-[#8B1D3B]" strokeWidth={1.75} />
        </div>

        {/* Titles */}
        <h1 className="text-2xl font-black text-slate-900 tracking-tight mb-1">
          تطبيق شبيك | SHOPIK
        </h1>
        <p className="text-[10.5px] text-slate-500 font-bold text-center mb-3.5 px-4">
          البوابة المتكاملة لسداد الاتصالات، المتجر الذكي، وشبكات الوايفاي
        </p>

        {/* Main Card (PageCard in Flutter) */}
        <div className="w-full bg-white rounded-[20px] border border-slate-200 p-3.5 shadow-xs">
          {/* Error Message */}
          {error && (
            <div className="w-full mb-2.5 p-2.5 bg-[#FFF1F2] border border-[#FECACA] rounded-[14px] text-[9.5px] font-extrabold text-[#BE123C] text-right">
              {error}
            </div>
          )}

          {/* Success Message */}
          {success && (
            <div className="w-full mb-2.5 p-2.5 bg-[#ECFDF5] border border-[#A7F3D0] rounded-[14px] text-[9.5px] font-extrabold text-[#047857] text-right">
              {success}
            </div>
          )}

          {/* Tab Selector: تسجيل الدخول / حساب جديد */}
          <div className="bg-[#F1F5F9] p-1 rounded-[14px] flex items-center gap-1 mb-3">
            <button
              type="button"
              onClick={() => {
                setRegisterMode(false);
                setError(null);
              }}
              className={`flex-1 py-2 text-[10px] font-black rounded-[10px] transition-all duration-160 ${
                !registerMode
                  ? "bg-[#8B1D3B] text-white shadow-xs"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              تسجيل الدخول
            </button>
            <button
              type="button"
              onClick={() => {
                setRegisterMode(true);
                setError(null);
              }}
              className={`flex-1 py-2 text-[10px] font-black rounded-[10px] transition-all duration-160 ${
                registerMode
                  ? "bg-[#8B1D3B] text-white shadow-xs"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              حساب جديد
            </button>
          </div>

          {/* Forms */}
          {!registerMode ? (
            /* Login Fields - Identical to Flutter _loginFields() */
            <form onSubmit={handleLogin} className="space-y-2.5">
              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <Smartphone className="w-4 h-4" />
                </div>
                <input
                  type="text"
                  dir="ltr"
                  inputMode="numeric"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))}
                  placeholder="رقم الهاتف / اسم الحساب"
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
              </div>

              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type={obscure ? "password" : "text"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="كلمة المرور"
                  className="w-full pr-9 pl-9 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
                <button
                  type="button"
                  onClick={() => setObscure(!obscure)}
                  className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400 hover:text-slate-600"
                >
                  {obscure ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>

              <div className="pt-1 space-y-2">
                {/* Primary Button: تسجيل الدخول المباشر (Burgundy, h-[47px], rounded-[15px]) */}
                <button
                  type="submit"
                  disabled={busy}
                  className="w-full h-[47px] bg-[#8B1D3B] hover:bg-[#72152f] text-white rounded-[15px] font-black text-[11px] shadow-xs active:scale-[0.98] transition flex items-center justify-center disabled:opacity-60"
                >
                  {busy ? (
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    "تسجيل الدخول المباشر"
                  )}
                </button>

                {/* Biometric Button: Outlined h-[44px], rounded-[15px] */}
                <button
                  type="button"
                  onClick={handleBiometricLogin}
                  disabled={bioBusy}
                  className="w-full h-[44px] bg-white hover:bg-slate-50 border border-slate-200 text-slate-800 rounded-[15px] font-black text-[10px] shadow-2xs active:scale-[0.98] transition flex items-center justify-center gap-1.5 disabled:opacity-60"
                >
                  {bioBusy ? (
                    <div className="w-4 h-4 border-2 border-[#8B1D3B] border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <>
                      <Fingerprint className="w-4 h-4 text-[#8B1D3B]" />
                      <span>تسجيل الدخول بالبصمة الحيوية</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          ) : (
            /* Register Fields - Identical to Flutter _registerFields() */
            <form onSubmit={handleRegister} className="space-y-2">
              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <User className="w-4 h-4" />
                </div>
                <input
                  type="text"
                  value={regName}
                  onChange={(e) => setRegName(e.target.value)}
                  placeholder="الاسم الكامل / الرباعي"
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
              </div>

              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <Smartphone className="w-4 h-4" />
                </div>
                <input
                  type="text"
                  dir="ltr"
                  inputMode="numeric"
                  maxLength={9}
                  value={regPhone}
                  onChange={(e) => setRegPhone(e.target.value.replace(/\D/g, "").slice(0, 9))}
                  placeholder="رقم الهاتف (9 أرقام)"
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
              </div>

              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <MapPin className="w-4 h-4" />
                </div>
                <select
                  value={regGovernorate}
                  onChange={(e) => setRegGovernorate(e.target.value)}
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right appearance-none"
                >
                  {GOVERNORATES.map((g) => (
                    <option key={g} value={g}>
                      {g}
                    </option>
                  ))}
                </select>
              </div>

              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type="password"
                  value={regPassword}
                  onChange={(e) => setRegPassword(e.target.value)}
                  placeholder="كلمة المرور (8 أحرف على الأقل)"
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
              </div>

              <div className="relative">
                <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type="password"
                  value={regConfirm}
                  onChange={(e) => setRegConfirm(e.target.value)}
                  placeholder="تأكيد كلمة المرور"
                  className="w-full pr-9 pl-3 py-2 text-xs font-bold bg-white border border-slate-200 rounded-xl focus:border-[#8B1D3B] focus:ring-1 focus:ring-[#8B1D3B] outline-hidden text-right"
                />
              </div>

              <div className="pt-1">
                <button
                  type="submit"
                  disabled={busy}
                  className="w-full h-[47px] bg-[#8B1D3B] hover:bg-[#72152f] text-white rounded-[15px] font-black text-[11px] shadow-xs active:scale-[0.98] transition flex items-center justify-center disabled:opacity-60"
                >
                  {busy ? (
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    "إنشاء الحساب والتسجيل"
                  )}
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Footer Attribution Badge - Exactly matching StatusBadge in Flutter */}
        <div className="mt-3 px-3 py-1 rounded-full bg-slate-200/60 text-[9px] font-black text-slate-500">
          برمجة وتطوير: يمن كود للتقنيات الذكية
        </div>
      </div>
    </div>
  );
};
