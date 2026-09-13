import React, { useState } from "react";
import {
  CreditCard,
  History,
  FileText,
  BarChart3,
  Send,
  Wifi,
  Gamepad2,
  Fingerprint,
  RotateCw,
  Eye,
  EyeOff,
  CheckCircle2,
  Clock,
  ShieldCheck,
  ChevronLeft,
  ArrowRight,
  Sparkles,
  Smartphone,
  PlusCircle,
  HelpCircle,
  UserCheck,
  Check,
  X,
  ShoppingBag,
  LogOut,
  Settings,
  MapPin,
  Coins
} from "lucide-react";
import { OperationItem, UserProfile } from "../types";
import { submitLiveFeedAccount } from "../services/apiService";

interface Props {
  walletBalance: number;
  userProfile?: UserProfile | null;
  onRefreshBalance: () => void;
  onNavigate: (screen: string) => void;
  operations: OperationItem[];
  onSelectOperation: (op: OperationItem) => void;
  onFeedSuccess?: (amount: number) => void;
  onLogout?: () => void;
}

export const MainHomeScreen: React.FC<Props> = ({
  walletBalance,
  userProfile,
  onRefreshBalance,
  onNavigate,
  operations,
  onSelectOperation,
  onFeedSuccess,
  onLogout,
}) => {
  const [showBalance, setShowBalance] = useState(true);
  const [isRotating, setIsRotating] = useState(false);
  const [showFeedModal, setShowFeedModal] = useState(false);
  const [feedPhone, setFeedPhone] = useState(userProfile?.phone || "774952665");
  const [feedAmount, setFeedAmount] = useState("5000");
  const [feedCode, setFeedCode] = useState("892104");
  const [feedLoading, setFeedLoading] = useState(false);
  const [feedSuccessMsg, setFeedSuccessMsg] = useState<string | null>(null);

  const handleManualRefresh = () => {
    setIsRotating(true);
    onRefreshBalance();
    setTimeout(() => {
      setIsRotating(false);
    }, 800);
  };

  const handleFeedSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const amt = parseFloat(feedAmount);
    if (!amt || amt <= 0) return;

    setFeedLoading(true);
    const res = await submitLiveFeedAccount(feedPhone, amt, feedCode);
    setFeedLoading(false);

    if (res.success) {
      setFeedSuccessMsg(res.message);
      if (onFeedSuccess) onFeedSuccess(amt);
      setTimeout(() => {
        setFeedSuccessMsg(null);
        setShowFeedModal(false);
      }, 2000);
    }
  };

  // Currency calculation
  const getDisplayBalance = () => {
    if (!showBalance) return "••••••••";
    return `${walletBalance.toLocaleString()} ر.ي`;
  };

  // Core navigation items in "حسابي في تطبيق شبيك"
  const servicesGrid = [
    {
      id: "store",
      title: "متجر شبيك (سوق بلس)",
      subtitle: "تصفح المنتجات، السلة، والطلبات",
      icon: ShoppingBag,
      color: "bg-[#059669]",
      textColor: "text-white",
      badge: "المتجر",
      description: "الواجهات السابقة للمتجر كاملة مع المنتجات والسلة",
    },
    {
      id: "payment",
      title: "شبكة السداد",
      subtitle: "يمن موبايل، سبأفون، يو، 4G، نت",
      icon: CreditCard,
      color: "bg-[#8B1D3B]",
      textColor: "text-white",
      badge: "الرئيسية",
      description: "سداد رصيد وباقات جميع شبكات الاتصالات اليمنية",
    },
    {
      id: "operations",
      title: "سجل العمليات",
      subtitle: "متابعة وفحص العمليات الحقيقية",
      icon: History,
      color: "bg-[#0284C7]",
      textColor: "text-white",
      badge: "بيانات الخادم",
      description: "عرض العمليات المسترجعة من API الخادم",
    },
    {
      id: "statement",
      title: "كشف الحساب",
      subtitle: "حركات الرصيد والقيود اليومية",
      icon: FileText,
      color: "bg-emerald-600",
      textColor: "text-white",
      badge: "مالي",
      description: "كشف الحركات المدينة والدائنة ومطابقة الرصيد",
    },
    {
      id: "reports",
      title: "التقارير والإحصائيات",
      subtitle: "مبيعات الشبكات والأرباح",
      icon: BarChart3,
      color: "bg-indigo-600",
      textColor: "text-white",
      description: "تقارير الحركات ومؤشرات الأداء",
    },
    {
      id: "transfer",
      title: "تحويل لمشترك",
      subtitle: "إرسال رصيد لمشترك شبيك",
      icon: Send,
      color: "bg-amber-500",
      textColor: "text-white",
      description: "تحويل فوري بين حسابات المشتركين برقم الهاتف",
    },
    {
      id: "wifi",
      title: "كروت الوايفاي (WiFi)",
      subtitle: "كروت وشبكات الإنترنت المحلية",
      icon: Wifi,
      color: "bg-teal-600",
      textColor: "text-white",
      description: "شراء وتوليد كروت الشبكات المحلية",
    },
    {
      id: "games",
      title: "شحن الألعاب والبرامج",
      subtitle: "ببجي، فري فاير، برامج رقمية",
      icon: Gamepad2,
      color: "bg-purple-600",
      textColor: "text-white",
      description: "شحن بطائق الألعاب والتطبيقات الرقمية فورياً",
    },
    {
      id: "settings",
      title: "الإعدادات وبصمة الهاتف",
      subtitle: "خيارات الحساب وبصمة فلاتر الحقيقية",
      icon: Settings,
      color: "bg-slate-700",
      textColor: "text-white",
      badge: "فلاتر",
      description: "إعدادات التطبيق وبصمة الجهاز للهاتف والعمليات",
    },
    {
      id: "addresses",
      title: "عناوين التوصيل",
      subtitle: "إدارة عناوين الشحن والاستلام",
      icon: MapPin,
      color: "bg-blue-600",
      textColor: "text-white",
      badge: "شحن",
      description: "إضافة وتعديل العناوين حسب متطلبات الخادم",
    },
  ];

  return (
    <div className="flex-1 flex flex-col bg-[#F7F9FC] overflow-y-auto">
      {/* Top Header Bar - Matches JeebAccountScreen */}
      <div className="bg-white border-b border-slate-200 px-4 py-3 flex items-center justify-between shadow-xs sticky top-0 z-20">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-[#8B1D3B] text-white flex items-center justify-center font-black text-sm shadow-sm">
            ز
          </div>
          <div>
            <div className="text-xs text-slate-500 font-medium">تطبيق شبيك وسوق بلس</div>
            <div className="text-sm font-black text-slate-800 flex items-center gap-1.5">
              <span>حسابي الرقمي</span>
              <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-1.5 py-0.5 rounded-md flex items-center gap-0.5">
                <CheckCircle2 className="w-3 h-3" />
                موثق
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-1.5">
          {/* Button to Return to the Store (المتجر) */}
          <button
            onClick={() => onNavigate("store")}
            className="flex items-center gap-1 bg-emerald-600 hover:bg-emerald-700 text-white px-2.5 py-1.5 rounded-full text-xs font-black shadow-xs active:scale-95 transition"
            title="العودة لواجهة المتجر كاملة"
          >
            <ShoppingBag className="w-3.5 h-3.5" />
            <span>المتجر</span>
          </button>

          {/* Quick shortcut to Payment Network */}
          <button
            onClick={() => onNavigate("payment")}
            className="flex items-center gap-1 bg-[#8B1D3B] text-white px-2.5 py-1.5 rounded-full text-xs font-black shadow-xs active:scale-95 transition"
            title="الانتقال لشبكة السداد"
          >
            <CreditCard className="w-3.5 h-3.5" />
            <span>السداد</span>
          </button>

          {/* Refresh balance */}
          <button
            onClick={handleManualRefresh}
            className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-700 flex items-center justify-center transition active:scale-95"
            title="تحديث البيانات من السيرفر"
          >
            <RotateCw className={`w-4 h-4 ${isRotating ? "animate-spin text-[#8B1D3B]" : ""}`} />
          </button>
        </div>
      </div>

      <div className="px-3.5 py-3.5 space-y-3.5">
        {/* User Session & Verified Profile Banner */}
        <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-3 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-emerald-600 text-white flex items-center justify-center font-bold text-sm shadow-xs shrink-0">
              <UserCheck className="w-5 h-5" />
            </div>
            <div>
              <div className="text-xs font-black text-emerald-950">
                {userProfile?.fullName || "زيدان محمد عبدالله العطاب (محمد العطاب)"}
              </div>
              <div className="text-[11px] text-emerald-700 font-semibold flex items-center gap-2">
                <span>الهاتف: {userProfile?.phone || "771642093"}</span>
                <span>•</span>
                <span>المحافظة: {userProfile?.governorate || "إب"}</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="bg-emerald-600 text-white text-[10px] font-extrabold px-2 py-1 rounded-lg">
              عميل معتمد ✅
            </span>
            {onLogout && (
              <button
                onClick={onLogout}
                className="bg-rose-100 hover:bg-rose-200 text-rose-800 border border-rose-200 text-[10px] font-black px-2 py-1 rounded-lg flex items-center gap-1 transition active:scale-95 shadow-xs"
                title="تسجيل الخروج من الحساب"
              >
                <LogOut className="w-3 h-3" />
                <span>خروج</span>
              </button>
            )}
          </div>
        </div>

        {/* Refined Crimson-Burgundy & Gold Balance Card (Lighter, slightly smaller, elegant font size) */}
        <div className="rounded-2xl overflow-hidden shadow-xs bg-gradient-to-br from-[#9E1F3D] via-[#8B1D3B] to-[#78142F] text-white p-3 sm:p-3.5 relative border border-amber-300/30">
          {/* Subtle background glow circle */}
          <div className="absolute -top-10 -left-10 w-28 h-28 bg-amber-400/15 rounded-full blur-xl pointer-events-none" />

          <div className="flex items-center justify-between mb-2 relative z-10">
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-amber-400/25 text-amber-300 flex items-center justify-center border border-amber-400/40">
                <CreditCard className="w-3 h-3" />
              </div>
              <div>
                <div className="text-[10px] font-black text-amber-200">بطاقة الرصيد الرقمية</div>
                <div className="text-[9px] text-white/90 font-bold">
                  {userProfile?.fullName || "زيدان محمد العطاب"}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-1.5">
              <button
                onClick={handleManualRefresh}
                className="w-6 h-6 rounded-full bg-white/15 hover:bg-white/25 flex items-center justify-center text-amber-300 transition active:scale-95"
                title="تحديث الرصيد"
              >
                <RotateCw className={`w-3 h-3 ${isRotating ? "animate-spin" : ""}`} />
              </button>
              <button
                onClick={() => setShowBalance(!showBalance)}
                className="w-6 h-6 rounded-full bg-white/15 hover:bg-white/25 flex items-center justify-center text-white/90 transition active:scale-95"
                title="إظهار/إخفاء الرصيد"
              >
                {showBalance ? <EyeOff className="w-3 h-3" /> : <Eye className="w-3 h-3" />}
              </button>
            </div>
          </div>

          {/* Balance Amount */}
          <div className="mt-1 pt-1 border-t border-white/15 relative z-10 flex items-center justify-between">
            <div>
              <div className="text-[9px] text-amber-200/90 font-medium mb-0.5">الرصيد المتاح للعمليات</div>
              <div className="text-xl sm:text-2xl font-bold tracking-tight text-white font-mono">
                {getDisplayBalance()}
              </div>
            </div>
            <div className="flex items-center gap-1.5 bg-black/20 backdrop-blur-xs px-2.5 py-1 rounded-full border border-white/10 text-[9px] font-bold text-emerald-300">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span>مزامنة ذاتية نشطة</span>
            </div>
          </div>

          {/* Circular Progress Widgets */}
          <div className="grid grid-cols-2 gap-2 mt-2 pt-2 border-t border-white/15 relative z-10">
            {/* Left: رصيد المحفظة */}
            <div className="bg-white/10 rounded-lg p-1.5 flex items-center gap-2 border border-white/10">
              <div className="relative w-7 h-7 shrink-0 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                  <path
                    className="text-white/20"
                    strokeWidth="3.5"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                  <path
                    className="text-amber-400"
                    strokeDasharray="86, 100"
                    strokeWidth="3.5"
                    strokeLinecap="round"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                </svg>
                <span className="absolute text-[8px] font-black text-amber-300 font-mono">86%</span>
              </div>
              <div className="min-w-0">
                <div className="text-[8px] text-white/80 font-bold">الرصيد الفعلي</div>
                <div className="text-[10px] font-bold text-white font-mono truncate">
                  {showBalance ? `${walletBalance.toLocaleString()} ر.ي` : "••••••"}
                </div>
              </div>
            </div>

            {/* Right: الأرباح */}
            <div className="bg-white/10 rounded-lg p-1.5 flex items-center gap-2 border border-white/10">
              <div className="relative w-7 h-7 shrink-0 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                  <path
                    className="text-white/20"
                    strokeWidth="3.5"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                  <path
                    className="text-emerald-400"
                    strokeDasharray="10, 100"
                    strokeWidth="3.5"
                    strokeLinecap="round"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                </svg>
                <span className="absolute text-[8px] font-black text-emerald-300 font-mono">0%</span>
              </div>
              <div className="min-w-0">
                <div className="text-[8px] text-white/80 font-bold">الأرباح</div>
                <div className="text-[10px] font-bold text-emerald-300 font-mono truncate">
                  {showBalance ? "0.00 ر.ي" : "••••••"}
                </div>
              </div>
            </div>
          </div>

          <div className="mt-1.5 pt-1.5 border-t border-white/15 flex items-center justify-between text-[9px] relative z-10">
            <div className="flex items-center gap-1 text-emerald-300 font-semibold">
              <CheckCircle2 className="w-3 h-3" />
              <span>محفظة معتمدة</span>
            </div>
            <div className="text-amber-300 font-bold">
              نقاط الولاء: {userProfile?.pointsBalance || 0}
            </div>
          </div>
        </div>

        {/* Quick Actions Row */}
        <div className="grid grid-cols-3 gap-2">
          {/* Feed Account */}
          <button
            onClick={() => setShowFeedModal(true)}
            className="bg-white hover:bg-slate-50 border border-slate-200 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center gap-1 active:scale-95 transition"
          >
            <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center shadow-xs">
              <PlusCircle className="w-5 h-5" />
            </div>
            <span className="text-xs font-black text-slate-800">تغذية الحساب</span>
            <span className="text-[9px] text-slate-400 font-medium">إيداع فوري</span>
          </button>

          {/* Transfer */}
          <button
            onClick={() => onNavigate("transfer")}
            className="bg-white hover:bg-slate-50 border border-slate-200 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center gap-1 active:scale-95 transition"
          >
            <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center shadow-xs">
              <Send className="w-5 h-5" />
            </div>
            <span className="text-xs font-black text-slate-800">تحويل مالي</span>
            <span className="text-[9px] text-slate-400 font-medium">بين المشتركين</span>
          </button>

          {/* Telecom Payment Network */}
          <button
            onClick={() => onNavigate("payment")}
            className="bg-[#8B1D3B] hover:bg-[#72152f] text-white rounded-2xl p-2.5 text-center shadow-md flex flex-col items-center justify-center gap-1 active:scale-95 transition"
          >
            <div className="w-9 h-9 rounded-xl bg-white/20 text-white flex items-center justify-center shadow-xs">
              <CreditCard className="w-5 h-5" />
            </div>
            <span className="text-xs font-black">شبكة السداد</span>
            <span className="text-[9px] text-white/80 font-medium">يمن موبايل، يو..</span>
          </button>
        </div>

        {/* Main Services Navigation Grid */}
        <div>
          <div className="flex items-center justify-between mb-2 px-0.5">
            <h2 className="text-sm font-black text-slate-800 flex items-center gap-1.5">
              <span>واجهات وخدمات تطبيق شبيك</span>
            </h2>
            <span className="text-[11px] text-slate-500 font-semibold">انقر للفتح المباشر</span>
          </div>

          <div className="grid grid-cols-2 gap-2.5">
            {servicesGrid.map((item, idx) => {
              const Icon = item.icon;
              return (
                <div
                  key={`home-svc-${item.id || idx}`}
                  onClick={() => onNavigate(item.id)}
                  className="bg-white hover:bg-slate-50 border border-slate-200/90 rounded-2xl p-3 shadow-xs hover:shadow transition-all cursor-pointer flex flex-col justify-between h-[108px] relative active:scale-[0.98]"
                >
                  {item.badge && (
                    <span className="absolute top-2.5 left-2.5 bg-amber-100 text-amber-900 text-[9px] font-black px-1.5 py-0.5 rounded-md">
                      {item.badge}
                    </span>
                  )}
                  <div className="flex items-center gap-2">
                    <div
                      className={`w-9 h-9 rounded-xl ${item.color} ${item.textColor} flex items-center justify-center shadow-xs shrink-0`}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                  </div>

                  <div>
                    <div className="text-xs font-black text-slate-800 line-clamp-1">{item.title}</div>
                    <div className="text-[10px] text-slate-500 font-medium line-clamp-1">
                      {item.subtitle}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Real Server Operations Section */}
        <div className="pt-1">
          <div className="flex items-center justify-between mb-2 px-0.5">
            <h2 className="text-sm font-black text-slate-800 flex items-center gap-1.5">
              <History className="w-4 h-4 text-[#8B1D3B]" />
              <span>أحدث العمليات وسجل السداد</span>
            </h2>
            <button
              onClick={() => onNavigate("operations")}
              className="text-[11px] text-[#8B1D3B] font-black flex items-center gap-0.5 hover:underline"
            >
              <span>فتح سجل العمليات الكامل</span>
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="space-y-2">
            {operations.slice(0, 4).map((op, idx) => (
              <div
                key={op.id ? `home-op-${op.id}-${idx}` : `home-op-${idx}`}
                onClick={() => onSelectOperation(op)}
                className="bg-white p-3 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between gap-3 cursor-pointer hover:bg-slate-50 transition active:scale-[0.99]"
              >
                <div className="flex items-center gap-2.5">
                  <div
                    className={`w-9 h-9 rounded-xl flex items-center justify-center text-white text-xs font-black shrink-0 ${
                      op.status === "success"
                        ? "bg-emerald-600"
                        : op.status === "pending"
                        ? "bg-amber-500"
                        : "bg-rose-600"
                    }`}
                  >
                    {op.status === "success" ? (
                      <CheckCircle2 className="w-5 h-5" />
                    ) : (
                      <Clock className="w-5 h-5" />
                    )}
                  </div>

                  <div>
                    <div className="text-xs font-black text-slate-800 flex items-center gap-1">
                      <span>{op.packageName}</span>
                      <span className="text-[9px] text-slate-400 font-mono">#{op.operationNumber}</span>
                    </div>
                    <div className="text-[11px] font-bold text-slate-500 dir-ltr">{op.phone}</div>
                  </div>
                </div>

                <div className="text-left">
                  <div className="text-xs font-black text-[#8B1D3B]">{op.amount} ر.ي</div>
                  <div className="text-[10px] text-emerald-600 font-extrabold flex items-center gap-0.5 justify-end">
                    <span>معتمدة ✓</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Developer & Smart Technologies Branding Footer */}
        <div className="pt-2 pb-6 text-center space-y-1">
          <div className="inline-flex items-center gap-1.5 bg-white px-3.5 py-1.5 rounded-full border border-slate-200 text-[11px] font-black text-slate-700 shadow-xs">
            <span>برمجة وتطوير: <strong className="text-[#8B1D3B]">يمن كود للتقنيات الذكية</strong></span>
          </div>
          <div className="text-[10px] text-slate-400 font-medium">
            Yemen Code for Smart Technologies © 2026 • جميع الحقوق محفوظة
          </div>
        </div>
      </div>

      {/* Feed Account Modal (تغذية الحساب) */}
      {showFeedModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-5 max-w-sm w-full shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between mb-4 border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center">
                  <PlusCircle className="w-5 h-5" />
                </div>
                <div className="font-black text-slate-900 text-base">تغذية رصيد الحساب</div>
              </div>
              <button
                onClick={() => setShowFeedModal(false)}
                className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-500"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {feedSuccessMsg ? (
              <div className="py-6 text-center space-y-2">
                <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
                  <Check className="w-6 h-6" />
                </div>
                <div className="text-sm font-black text-emerald-800">{feedSuccessMsg}</div>
                <div className="text-xs text-slate-500">تم تحديث رصيد محفظتك الرقمية الآن.</div>
              </div>
            ) : (
              <form onSubmit={handleFeedSubmit} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">رقم الهاتف المرتبط</label>
                  <input
                    type="tel"
                    value={feedPhone}
                    onChange={(e) => setFeedPhone(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm font-bold dir-ltr focus:outline-none focus:border-emerald-500"
                    placeholder="77XXXXXXX"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">المبلغ المراد تغذيته (ريال يمني)</label>
                  <input
                    type="number"
                    value={feedAmount}
                    onChange={(e) => setFeedAmount(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm font-black dir-ltr focus:outline-none focus:border-emerald-500"
                    placeholder="5000"
                    min="100"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">كود التحقق / الإيداع المرجعي</label>
                  <input
                    type="text"
                    value={feedCode}
                    onChange={(e) => setFeedCode(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono font-bold focus:outline-none focus:border-emerald-500"
                    placeholder="892104"
                    required
                  />
                </div>

                <div className="pt-2">
                  <button
                    type="submit"
                    disabled={feedLoading}
                    className="w-full py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-sm shadow-md transition active:scale-98 flex items-center justify-center gap-2"
                  >
                    {feedLoading ? (
                      <>
                        <RotateCw className="w-4 h-4 animate-spin" />
                        <span>جاري التحقق والتغذية...</span>
                      </>
                    ) : (
                      <>
                        <CheckCircle2 className="w-4 h-4" />
                        <span>غذي حسابك الآن</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
