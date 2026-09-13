import React, { useState, useEffect } from "react";
import {
  ArrowRight,
  User,
  Phone,
  Mail,
  MapPin,
  Shield,
  KeyRound,
  CheckCircle2,
  Save,
  Edit3,
  Camera,
  Star,
  Award,
  Wallet,
  Clock,
  Sparkles,
  Lock,
} from "lucide-react";
import { triggerHeadsUpNotification } from "./HeadsUpNotification";

interface Props {
  onBack: () => void;
  walletBalance: number;
}

const YEMEN_GOVERNORATES = [
  "صنعاء - الأمانة",
  "صنعاء - المحافظة",
  "عدن",
  "تعز",
  "الحديدة",
  "إب",
  "حضرموت - المكلا",
  "حضرموت - سيئون",
  "مأرب",
  "ذمار",
  "عمران",
  "صعدة",
  "حجة",
  "البيضاء",
  "شبوة",
  "الجوف",
  "المهرة",
  "سقطرى",
  "لحج",
  "أبين",
  "الضالع",
  "ريمة",
];

export const UserProfileScreen: React.FC<Props> = ({ onBack, walletBalance }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [activeTab, setActiveTab] = useState<"profile" | "security">("profile");

  // Profile fields state
  const [name, setName] = useState("زيدان أحمد المهدي");
  const [phone, setPhone] = useState("777123456");
  const [email, setEmail] = useState("zidan.mahdi@shopik.ye");
  const [governorate, setGovernorate] = useState("صنعاء - الأمانة");
  const [address, setAddress] = useState("حدة - شارع الستين الجنوبي - جوار مركز النور");
  const [storeName, setStoreName] = useState("نقطة شبيك للخدمات الإلكترونية");

  // Security fields
  const [currentPin, setCurrentPin] = useState("");
  const [newPin, setNewPin] = useState("");
  const [confirmPin, setConfirmPin] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState<{ text: string; type: "success" | "error" } | null>(null);

  // Load stored profile from localStorage on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem("shopik_user_profile");
      if (saved) {
        const data = JSON.parse(saved);
        if (data.name) setName(data.name);
        if (data.phone) setPhone(data.phone);
        if (data.email) setEmail(data.email);
        if (data.governorate) setGovernorate(data.governorate);
        if (data.address) setAddress(data.address);
        if (data.storeName) setStoreName(data.storeName);
      }
    } catch {}
  }, []);

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !phone.trim()) {
      setFeedbackMessage({ text: "الرجاء تعبئة الاسم ورقم الهاتف على الأقل", type: "error" });
      return;
    }

    setIsSaving(true);
    setTimeout(() => {
      const profileData = { name, phone, email, governorate, address, storeName };
      localStorage.setItem("shopik_user_profile", JSON.stringify(profileData));
      setIsSaving(false);
      setIsEditing(false);
      setFeedbackMessage({ text: "تم تحديث البيانات بنجاح في النظام ✓", type: "success" });

      // Trigger High Priority Heads-up Notification
      triggerHeadsUpNotification({
        title: "تم حفظ وتحديث بيانات الملف الشخصي",
        body: `تم تحديث بيانات العميل (${name}) ورقم الهاتف (${phone}) في السجل المعتمد.`,
        type: "success",
        channelName: "إشعارات الحساب والأمان",
      });
    }, 450);
  };

  const handleUpdatePin = (e: React.FormEvent) => {
    e.preventDefault();
    if (newPin.length !== 4 || isNaN(Number(newPin))) {
      setFeedbackMessage({ text: "رقم PIN يجب أن يتكون من 4 أرقام", type: "error" });
      return;
    }
    if (newPin !== confirmPin) {
      setFeedbackMessage({ text: "تأكيد رقم PIN غير متطابق", type: "error" });
      return;
    }

    localStorage.setItem("shopik_quick_pin", newPin);
    setCurrentPin("");
    setNewPin("");
    setConfirmPin("");
    setFeedbackMessage({ text: "تم تغيير رمز السداد PIN بنجاح ✓", type: "success" });

    triggerHeadsUpNotification({
      title: "تم تحديث رمز الحماية السري PIN",
      body: "تم تحديث رمز الأمان لعمليات السداد والمشتريات بنجاح.",
      type: "success",
      channelName: "إشعارات الحساب والأمان",
    });
  };

  return (
    <div className="flex-1 flex flex-col bg-[#F7F9FC] overflow-y-auto" dir="rtl">
      {/* Top App Bar matching Burgundy Identity */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3 flex items-center justify-between sticky top-0 z-30 shadow-md">
        <div className="flex items-center gap-2">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition active:scale-95 text-xs font-black shadow-xs border border-white/20"
          >
            <ArrowRight className="w-4 h-4" />
            <span>رجوع</span>
          </button>
          <div className="font-black text-base">الملف الشخصي والحساب</div>
        </div>

        <button
          onClick={() => {
            setIsEditing(!isEditing);
            setFeedbackMessage(null);
          }}
          className={`px-3 py-1.5 rounded-full text-xs font-black transition active:scale-95 flex items-center gap-1.5 ${
            isEditing
              ? "bg-amber-400 text-slate-900"
              : "bg-white/20 hover:bg-white/30 text-white"
          }`}
        >
          <Edit3 className="w-3.5 h-3.5" />
          <span>{isEditing ? "إلغاء التعديل" : "تعديل البيانات"}</span>
        </button>
      </div>

      <div className="p-4 space-y-4 max-w-lg mx-auto w-full">
        {/* User Hero Identity Card */}
        <div className="bg-white rounded-3xl p-5 border border-slate-200/90 shadow-xs relative overflow-hidden">
          <div className="absolute top-0 left-0 right-0 h-16 bg-gradient-to-r from-[#8B1D3B] via-[#9E1A42] to-[#B91C4A]" />

          <div className="relative pt-6 flex flex-col sm:flex-row items-center sm:items-end gap-3.5 text-center sm:text-right">
            <div className="relative">
              <div className="w-20 h-20 rounded-2xl bg-white p-1 shadow-md border border-slate-200">
                <div className="w-full h-full rounded-xl bg-[#8B1D3B] text-white flex items-center justify-center font-black text-2xl shadow-inner">
                  {name.charAt(0)}
                </div>
              </div>
              <button
                className="absolute -bottom-1 -left-1 w-7 h-7 rounded-full bg-amber-400 text-slate-900 flex items-center justify-center shadow-xs hover:bg-amber-300 transition"
                title="تغيير الصورة الشخصية"
              >
                <Camera className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-center sm:justify-start gap-1.5">
                <h2 className="text-base font-black text-slate-900 truncate">{name}</h2>
                <span className="bg-amber-100 text-amber-800 text-[10px] font-black px-2 py-0.5 rounded-full flex items-center gap-0.5 shrink-0">
                  <Star className="w-2.5 h-2.5 fill-amber-500 text-amber-500" />
                  عميل موثق
                </span>
              </div>
              <p className="text-xs text-slate-500 font-bold mt-0.5" dir="ltr">
                {phone}
              </p>
              <div className="text-[11px] text-slate-400 font-medium flex items-center justify-center sm:justify-start gap-1 mt-1">
                <MapPin className="w-3 h-3 text-[#8B1D3B]" />
                <span>{governorate}</span>
              </div>
            </div>
          </div>

          {/* Quick Metrics Strip */}
          <div className="grid grid-cols-2 gap-2 pt-4 mt-4 border-t border-slate-100">
            <div className="bg-slate-50 rounded-2xl p-2.5 text-center border border-slate-100">
              <div className="text-[10px] text-slate-400 font-bold">الرصيد المتاح</div>
              <div className="text-sm font-black text-[#8B1D3B] mt-0.5">
                {walletBalance.toLocaleString()} ر.ي
              </div>
            </div>
            <div className="bg-slate-50 rounded-2xl p-2.5 text-center border border-slate-100">
              <div className="text-[10px] text-slate-400 font-bold">فئة الحساب</div>
              <div className="text-sm font-black text-slate-800 mt-0.5 flex items-center justify-center gap-1">
                <Award className="w-3.5 h-3.5 text-amber-500" />
                <span>الماسية المميزة</span>
              </div>
            </div>
          </div>
        </div>

        {/* Feedback notification toast */}
        {feedbackMessage && (
          <div
            className={`p-3 rounded-2xl text-xs font-black flex items-center gap-2 animate-in fade-in duration-200 ${
              feedbackMessage.type === "success"
                ? "bg-emerald-50 text-emerald-800 border border-emerald-200"
                : "bg-rose-50 text-rose-800 border border-rose-200"
            }`}
          >
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{feedbackMessage.text}</span>
          </div>
        )}

        {/* Tabs: Profile Data vs Security */}
        <div className="flex bg-white p-1 rounded-2xl border border-slate-200 shadow-2xs">
          <button
            onClick={() => setActiveTab("profile")}
            className={`flex-1 py-2 text-xs font-black rounded-xl transition flex items-center justify-center gap-1.5 ${
              activeTab === "profile"
                ? "bg-[#8B1D3B] text-white shadow-xs"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <User className="w-3.5 h-3.5" />
            <span>البيانات الشخصية</span>
          </button>
          <button
            onClick={() => setActiveTab("security")}
            className={`flex-1 py-2 text-xs font-black rounded-xl transition flex items-center justify-center gap-1.5 ${
              activeTab === "security"
                ? "bg-[#8B1D3B] text-white shadow-xs"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <KeyRound className="w-3.5 h-3.5" />
            <span>رمز PIN والأمان</span>
          </button>
        </div>

        {/* Profile Tab */}
        {activeTab === "profile" && (
          <div className="bg-white rounded-3xl p-5 border border-slate-200 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-black text-slate-900 flex items-center gap-1.5">
                <User className="w-4 h-4 text-[#8B1D3B]" />
                <span>{isEditing ? "تعديل البيانات الشخصية" : "تفاصيل البيانات المسجلة"}</span>
              </h3>
              {!isEditing && (
                <span className="text-[10px] text-emerald-700 bg-emerald-50 border border-emerald-200 font-black px-2 py-0.5 rounded-full">
                  بيانات معتمدة نشطة
                </span>
              )}
            </div>

            <form onSubmit={handleSaveProfile} className="space-y-3.5">
              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  الاسم الكامل (رباعي)
                </label>
                <div className="relative">
                  <User className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    disabled={!isEditing}
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-2xl pr-9 pl-3 py-2.5 text-xs font-bold text-slate-800 disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                    placeholder="أدخل اسمك الرباعي الكامل"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  رقم الهاتف المعتمد
                </label>
                <div className="relative">
                  <Phone className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="tel"
                    dir="ltr"
                    disabled={!isEditing}
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-2xl pr-9 pl-3 py-2.5 text-xs font-bold text-slate-800 text-right disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                    placeholder="777123456"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  البريد الإلكتروني
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="email"
                    dir="ltr"
                    disabled={!isEditing}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-2xl pr-9 pl-3 py-2.5 text-xs font-bold text-slate-800 text-right disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                    placeholder="name@example.com"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  المحافظة / المدينة
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                  <select
                    disabled={!isEditing}
                    value={governorate}
                    onChange={(e) => setGovernorate(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-2xl pr-9 pl-3 py-2.5 text-xs font-bold text-slate-800 disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                  >
                    {YEMEN_GOVERNORATES.map((gov) => (
                      <option key={gov} value={gov}>
                        {gov}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  العنوان بالتفصيل
                </label>
                <input
                  type="text"
                  disabled={!isEditing}
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-3 py-2.5 text-xs font-bold text-slate-800 disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                  placeholder="الشارع، الحي، أقرب معلم بارز"
                />
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  اسم نقطة البيع / المتجر التجاري (اختياري)
                </label>
                <input
                  type="text"
                  disabled={!isEditing}
                  value={storeName}
                  onChange={(e) => setStoreName(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-3 py-2.5 text-xs font-bold text-slate-800 disabled:opacity-75 focus:outline-none focus:border-[#8B1D3B] focus:bg-white transition"
                  placeholder="اسم المحل أو النقطة"
                />
              </div>

              {isEditing && (
                <div className="pt-2 flex items-center gap-2">
                  <button
                    type="submit"
                    disabled={isSaving}
                    className="flex-1 bg-[#8B1D3B] hover:bg-[#72152f] text-white py-3 rounded-2xl text-xs font-black flex items-center justify-center gap-2 transition active:scale-95 shadow-md"
                  >
                    <Save className="w-4 h-4" />
                    <span>{isSaving ? "جاري الحفظ والمزامنة..." : "حفظ التعديلات في النظام"}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsEditing(false)}
                    className="px-4 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-2xl text-xs font-black transition active:scale-95"
                  >
                    إلغاء
                  </button>
                </div>
              )}
            </form>
          </div>
        )}

        {/* Security Tab */}
        {activeTab === "security" && (
          <div className="bg-white rounded-3xl p-5 border border-slate-200 shadow-xs space-y-4">
            <h3 className="text-sm font-black text-slate-900 flex items-center gap-1.5">
              <Shield className="w-4 h-4 text-[#8B1D3B]" />
              <span>تغيير رمز الحماية السري PIN</span>
            </h3>
            <p className="text-[11px] text-slate-500 font-medium">
              يُطلب رمز PIN لتأكيد عمليات السداد وشحن الرصيد والتحويلات المالية لحماية رصيد محفظتك.
            </p>

            <form onSubmit={handleUpdatePin} className="space-y-3.5 pt-1">
              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  رمز PIN الحالي (إن وجد)
                </label>
                <input
                  type="password"
                  maxLength={4}
                  value={currentPin}
                  onChange={(e) => setCurrentPin(e.target.value)}
                  placeholder="••••"
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-3 py-2.5 text-sm font-mono tracking-widest text-center text-slate-800 focus:outline-none focus:border-[#8B1D3B] focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  رمز PIN الجديد (4 أرقام)
                </label>
                <input
                  type="password"
                  maxLength={4}
                  value={newPin}
                  onChange={(e) => setNewPin(e.target.value)}
                  placeholder="••••"
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-3 py-2.5 text-sm font-mono tracking-widest text-center text-slate-800 focus:outline-none focus:border-[#8B1D3B] focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-[11px] font-black text-slate-700 mb-1">
                  تأكيد رمز PIN الجديد
                </label>
                <input
                  type="password"
                  maxLength={4}
                  value={confirmPin}
                  onChange={(e) => setConfirmPin(e.target.value)}
                  placeholder="••••"
                  className="w-full bg-slate-50 border border-slate-200 rounded-2xl px-3 py-2.5 text-sm font-mono tracking-widest text-center text-slate-800 focus:outline-none focus:border-[#8B1D3B] focus:bg-white"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-[#8B1D3B] hover:bg-[#72152f] text-white py-3 rounded-2xl text-xs font-black flex items-center justify-center gap-2 transition active:scale-95 shadow-md"
              >
                <Lock className="w-4 h-4" />
                <span>حفظ وتحديث رمز PIN</span>
              </button>
            </form>
          </div>
        )}
      </div>
    </div>
  );
};
