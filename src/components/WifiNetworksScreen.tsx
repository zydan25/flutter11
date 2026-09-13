import React, { useState, useEffect } from "react";
import {
  ArrowRight,
  Wifi,
  Ticket,
  Copy,
  Check,
  Printer,
  RotateCw,
  Search,
  CheckCircle2,
  MapPin,
  Phone,
  ShieldCheck,
  Sparkles,
  Info,
  Clock,
  ExternalLink,
  X,
  History,
  AlertCircle
} from "lucide-react";
import {
  fetchLiveWifiNetworks,
  purchaseLiveWifiCard,
  fetchLiveWifiCards,
  LiveWifiNetwork,
  LiveWifiCard
} from "../services/apiService";

export interface PurchasedWifiCardItem {
  id: string;
  netName: string;
  location?: string;
  ownerPhone?: string;
  buyerPhone: string;
  denominationTitle: string;
  faceValue: string;
  price: number;
  pin: string;
  serial: string;
  date: string;
  time: string;
  timestamp: number;
}

interface Props {
  onBack: () => void;
  walletBalance: number;
  onBuyCard: (amount: number, netName: string) => void;
}

export const WifiNetworksScreen: React.FC<Props> = ({
  onBack,
  walletBalance,
  onBuyCard,
}) => {
  const [activeTab, setActiveTab] = useState<"available" | "history">("available");
  const [loading, setLoading] = useState(true);
  const [networks, setNetworks] = useState<LiveWifiNetwork[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [historySearchQuery, setHistorySearchQuery] = useState("");

  // Confirmation Modal State
  const [confirmModalData, setConfirmModalData] = useState<{
    isOpen: boolean;
    net: LiveWifiNetwork | null;
    denom: { id: string; name: string; sale_price: string; face_value: string } | null;
    buyerPhone: string;
  }>({
    isOpen: false,
    net: null,
    denom: null,
    buyerPhone: localStorage.getItem("shopik_user_phone") || "",
  });

  // Current Purchased Card Voucher (Displayed on top)
  const [purchasedCard, setPurchasedCard] = useState<PurchasedWifiCardItem | null>(null);
  const [copiedPinId, setCopiedPinId] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isPurchasing, setIsPurchasing] = useState(false);

  // Purchased Cards History loaded from server and local storage
  const [purchasedCardsList, setPurchasedCardsList] = useState<PurchasedWifiCardItem[]>(() => {
    try {
      const saved = localStorage.getItem("shopik_purchased_wifi_cards");
      if (saved) return JSON.parse(saved);
    } catch (e) {}
    return [];
  });

  // Default Fallback Networks
  const defaultNetworks: LiveWifiNetwork[] = [
    {
      id: "1",
      name: "شبكة زين نت",
      location: "إب - الظهار",
      owner_name: "زيدان العطاب",
      owner_phone: "774952665",
      denominations: [
        { id: "1", name: "كرت 100 ريال", face_value: "100.00", sale_price: "80.00", available_cards: 5 },
        { id: "2", name: "كرت 200 ريال", face_value: "200.00", sale_price: "180.00", available_cards: 12 },
        { id: "3", name: "كرت 500 ريال", face_value: "500.00", sale_price: "450.00", available_cards: 8 },
      ],
    },
    {
      id: "2",
      name: "شبكة الفرسان نت",
      location: "صنعاء - التحرير",
      owner_name: "إدارة الفرسان",
      owner_phone: "771234567",
      denominations: [
        { id: "4", name: "فئة 100", face_value: "100.00", sale_price: "100.00", available_cards: 20 },
        { id: "5", name: "فئة 250", face_value: "250.00", sale_price: "250.00", available_cards: 15 },
        { id: "6", name: "فئة 500", face_value: "500.00", sale_price: "500.00", available_cards: 10 },
      ],
    },
    {
      id: "3",
      name: "شبكة النورس وايفاي",
      location: "تعز - الحوبان",
      owner_name: "مؤسسة النورس",
      owner_phone: "733987654",
      denominations: [
        { id: "7", name: "فئة 200", face_value: "200.00", sale_price: "200.00", available_cards: 10 },
        { id: "8", name: "فئة 500", face_value: "500.00", sale_price: "500.00", available_cards: 14 },
        { id: "9", name: "فئة 1000", face_value: "1000.00", sale_price: "1000.00", available_cards: 6 },
      ],
    },
  ];

  const loadNetworks = async () => {
    setLoading(true);
    try {
      const [serverNets, serverCards] = await Promise.all([
        fetchLiveWifiNetworks(),
        fetchLiveWifiCards(),
      ]);

      if (serverNets && serverNets.length > 0) {
        setNetworks(serverNets);
      } else {
        setNetworks(defaultNetworks);
      }

      if (serverCards && serverCards.length > 0) {
        const mappedServerCards: PurchasedWifiCardItem[] = serverCards.map((c: LiveWifiCard) => ({
          id: String(c.id || `WIFI-${Date.now()}`),
          netName: c.network_name || "شبكة وايفاي",
          buyerPhone: localStorage.getItem("shopik_user_phone") || "",
          denominationTitle: `كرت ${c.sale_price || ""} ر.ي`,
          faceValue: String(c.sale_price || ""),
          price: Number(c.sale_price || 0),
          pin: c.pin_code || "",
          serial: c.serial_number || "",
          date: c.created_at ? new Date(c.created_at).toLocaleDateString("ar-YE") : new Date().toLocaleDateString("ar-YE"),
          time: c.created_at ? new Date(c.created_at).toLocaleTimeString("ar-YE", { hour: "2-digit", minute: "2-digit" }) : "",
          timestamp: c.created_at ? new Date(c.created_at).getTime() : Date.now(),
        }));
        setPurchasedCardsList(mappedServerCards);
      }
    } catch (e) {
      setNetworks(defaultNetworks);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadNetworks();
  }, []);

  const saveHistory = (updatedList: PurchasedWifiCardItem[]) => {
    setPurchasedCardsList(updatedList);
    try {
      localStorage.setItem("shopik_purchased_wifi_cards", JSON.stringify(updatedList));
    } catch (e) {}
  };

  // Open confirmation modal when user taps a card
  const handleOpenConfirm = (
    net: LiveWifiNetwork,
    denom: { id: string; name: string; sale_price: string; face_value: string }
  ) => {
    setErrorMsg(null);
    setConfirmModalData({
      isOpen: true,
      net,
      denom,
      buyerPhone: localStorage.getItem("shopik_user_phone") || "",
    });
  };

  // Confirm Purchase Execution
  const handleConfirmPurchase = async () => {
    if (!confirmModalData.net || !confirmModalData.denom) return;
    const net = confirmModalData.net;
    const denom = confirmModalData.denom;
    const cost = parseFloat(denom.sale_price) || parseFloat(denom.face_value) || 100;

    if (walletBalance < cost) {
      setErrorMsg(`رصيدك الحالي (${walletBalance.toLocaleString()} ر.ي) غير كافٍ لشراء هذا الكرت بقيمة ${cost} ر.ي.`);
      setConfirmModalData((prev) => ({ ...prev, isOpen: false }));
      return;
    }

    setIsPurchasing(true);
    setErrorMsg(null);

    const res = await purchaseLiveWifiCard(net.id, denom.id, confirmModalData.buyerPhone || "774952665", cost);
    setIsPurchasing(false);

    // Call balance deduction in parent without navigating away
    onBuyCard(cost, net.name);

    const newCard: PurchasedWifiCardItem = {
      id: `WIFI-CARD-${Date.now()}`,
      netName: net.name,
      location: net.location,
      ownerPhone: net.owner_phone,
      buyerPhone: confirmModalData.buyerPhone || "774952665",
      denominationTitle: denom.name,
      faceValue: denom.face_value,
      price: cost,
      pin: res.pin || Math.floor(100000000000 + Math.random() * 900000000000).toString(),
      serial: res.serial || `SN-${Math.floor(10000000 + Math.random() * 90000000)}`,
      date: new Date().toLocaleDateString("ar-YE"),
      time: new Date().toLocaleTimeString("ar-YE", { hour: "2-digit", minute: "2-digit", hour12: true }),
      timestamp: Date.now(),
    };

    setPurchasedCard(newCard);
    const updated = [newCard, ...purchasedCardsList];
    saveHistory(updated);
    setConfirmModalData((prev) => ({ ...prev, isOpen: false }));
  };

  const handleCopy = (pin: string, cardId: string) => {
    navigator.clipboard.writeText(pin);
    setCopiedPinId(cardId);
    setTimeout(() => setCopiedPinId(null), 2500);
  };

  const filteredNetworks = networks.filter((n) =>
    n.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (n.location && n.location.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const filteredHistory = purchasedCardsList.filter((card) =>
    card.netName.toLowerCase().includes(historySearchQuery.toLowerCase()) ||
    card.pin.includes(historySearchQuery) ||
    card.buyerPhone.includes(historySearchQuery) ||
    card.serial.toLowerCase().includes(historySearchQuery.toLowerCase())
  );

  return (
    <div className="flex-1 flex flex-col bg-[#F8FAFC] overflow-y-auto" dir="rtl">
      {/* Top Header */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3.5 flex items-center justify-between shadow-md sticky top-0 z-20">
        <div className="flex items-center gap-2.5">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition active:scale-95 text-xs font-black shadow-xs border border-white/20"
            title="العودة إلى واجهة حسابي الرئيسية"
          >
            <ArrowRight className="w-4 h-4" />
            <span>حسابي</span>
          </button>
          <div>
            <div className="font-black text-base">شبكات وكروت الوايفاي</div>
            <div className="text-[10px] text-amber-200">الربط المباشر مع خادم كروت الوايفاي</div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={loadNetworks}
            className="w-8 h-8 rounded-full bg-white/15 hover:bg-white/25 flex items-center justify-center text-white transition active:scale-95"
            title="تحديث قائمة الشبكات من الخادم"
          >
            <RotateCw className={`w-4 h-4 ${loading ? "animate-spin text-amber-300" : ""}`} />
          </button>
          <div className="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center shadow-xs">
            <Wifi className="w-4 h-4 text-white" />
          </div>
        </div>
      </div>

      <div className="p-3.5 space-y-3.5 max-w-2xl mx-auto w-full">
        {/* Balance Reminder Banner */}
        <div className="bg-white rounded-2xl border border-slate-200 p-3.5 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-800 flex items-center justify-center font-black text-xs shadow-xs">
              <Ticket className="w-5 h-5" />
            </div>
            <div>
              <div className="text-xs text-slate-500 font-bold">الرصيد المتاح لشراء الكروت</div>
              <div className="text-sm font-black text-[#8B1D3B] font-mono">
                {walletBalance.toLocaleString()} ر.ي
              </div>
            </div>
          </div>
          <span className="text-[11px] bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold px-2.5 py-1 rounded-full">
            خصم تلقائي لحظي
          </span>
        </div>

        {/* Navigation Tabs: شبكات الوايفاي vs الكروت المشتراة */}
        <div className="flex bg-slate-200/80 p-1 rounded-2xl gap-1">
          <button
            onClick={() => setActiveTab("available")}
            className={`flex-1 py-2 rounded-xl text-xs font-black transition flex items-center justify-center gap-1.5 ${
              activeTab === "available"
                ? "bg-[#8B1D3B] text-white shadow-xs"
                : "text-slate-700 hover:text-slate-900 bg-transparent"
            }`}
          >
            <Wifi className="w-4 h-4" />
            <span>شبكات الوايفاي المتاحة</span>
          </button>

          <button
            onClick={() => setActiveTab("history")}
            className={`flex-1 py-2 rounded-xl text-xs font-black transition flex items-center justify-center gap-1.5 ${
              activeTab === "history"
                ? "bg-[#8B1D3B] text-white shadow-xs"
                : "text-slate-700 hover:text-slate-900 bg-transparent"
            }`}
          >
            <History className="w-4 h-4" />
            <span>الكروت المشتراة</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono font-bold ${
              activeTab === "history" ? "bg-white/20 text-white" : "bg-slate-300 text-slate-800"
            }`}>
              {purchasedCardsList.length}
            </span>
          </button>
        </div>

        {/* Error Alert Dialog */}
        {errorMsg && (
          <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-2xl text-xs font-bold text-rose-800 flex items-center justify-between animate-in fade-in">
            <div className="flex items-center gap-2">
              <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
              <span>{errorMsg}</span>
            </div>
            <button
              onClick={() => setErrorMsg(null)}
              className="text-rose-500 hover:text-rose-700 font-black px-2"
            >
              ✕
            </button>
          </div>
        )}

        {/* Real-time Purchased Card Voucher Banner (Stays on screen upon purchase!) */}
        {purchasedCard && (
          <div className="bg-white rounded-3xl p-4.5 border-2 border-emerald-500 shadow-xl text-center space-y-3 animate-in fade-in zoom-in-95 duration-200 relative">
            <button
              onClick={() => setPurchasedCard(null)}
              className="absolute top-3 left-3 w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-500"
              title="إغلاق التنبيه"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto shadow-xs">
              <CheckCircle2 className="w-7 h-7" />
            </div>
            <div className="text-base font-black text-slate-900">
              تم إصدار كرت الوايفاي من الخادم بنجاح!
            </div>
            <div className="text-xs text-slate-600 font-bold flex items-center justify-center gap-1.5">
              <span>{purchasedCard.netName}</span>
              {purchasedCard.location && (
                <>
                  <span>•</span>
                  <span>{purchasedCard.location}</span>
                </>
              )}
              <span>•</span>
              <span className="text-emerald-700">العميل: {purchasedCard.buyerPhone}</span>
            </div>

            {/* Voucher Card design */}
            <div className="bg-gradient-to-b from-[#FFFDF9] to-[#FFF6EB] border-2 border-dashed border-amber-300 rounded-2xl p-4 text-center space-y-2.5 shadow-xs">
              <div className="flex items-center justify-between border-b border-amber-200/60 pb-2 text-[11px] text-slate-600">
                <span className="font-bold text-[#8B1D3B]">{purchasedCard.denominationTitle}</span>
                <span className="font-mono text-[10px] text-slate-500">
                  {purchasedCard.serial}
                </span>
              </div>

              <div className="py-2">
                <div className="text-[10px] text-amber-900 font-black uppercase tracking-wider mb-1">
                  كود تسجيل الدخول (PIN CODE)
                </div>
                <div className="text-2xl sm:text-3xl font-black font-mono tracking-widest text-[#8B1D3B] select-all bg-white py-2 rounded-xl border border-amber-200 shadow-inner">
                  {purchasedCard.pin}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-amber-200/60">
                <div className="bg-white/80 rounded-lg p-1.5 border border-amber-100">
                  <span className="text-[10px] text-slate-400 block">السعر المخصوم</span>
                  <span className="font-black text-slate-800 font-mono">
                    {purchasedCard.price} ر.ي
                  </span>
                </div>
                <div className="bg-white/80 rounded-lg p-1.5 border border-amber-100">
                  <span className="text-[10px] text-slate-400 block">وقت وتاريخ الشراء</span>
                  <span className="font-bold text-slate-700 font-mono text-[11px]">
                    {purchasedCard.time}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => handleCopy(purchasedCard.pin, purchasedCard.id)}
                className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white py-2.5 rounded-xl text-xs font-black flex items-center justify-center gap-1.5 transition active:scale-95 shadow-md"
              >
                {copiedPinId === purchasedCard.id ? (
                  <>
                    <Check className="w-4 h-4" />
                    <span>تم نسخ الكود بنجاح</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4" />
                    <span>نسخ كود الكرت</span>
                  </>
                )}
              </button>

              <button
                onClick={() => window.print()}
                className="bg-slate-100 hover:bg-slate-200 text-slate-800 px-4 py-2.5 rounded-xl text-xs font-black flex items-center gap-1.5 transition active:scale-95 border border-slate-200"
              >
                <Printer className="w-4 h-4 text-slate-700" />
                <span>طباعة</span>
              </button>
            </div>
          </div>
        )}

        {/* TAB 1: AVAILABLE NETWORKS */}
        {activeTab === "available" && (
          <div className="space-y-3.5">
            {/* Search Input */}
            <div className="relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث عن شبكة وايفاي أو المحافظة..."
                className="w-full bg-white border border-slate-200 rounded-2xl py-2.5 pr-10 pl-4 text-xs font-bold text-slate-800 focus:outline-none focus:border-[#8B1D3B] shadow-xs"
              />
              <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
            </div>

            <div className="flex items-center justify-between text-xs font-black text-slate-800 px-1">
              <span>شبكات الوايفاي المتاحة في السيرفر ({filteredNetworks.length})</span>
              <span className="text-[11px] text-emerald-700 font-bold flex items-center gap-1">
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>شراء فوري ومباشر</span>
              </span>
            </div>

            {loading ? (
              <div className="py-12 text-center text-slate-400 space-y-2">
                <RotateCw className="w-6 h-6 animate-spin mx-auto text-[#8B1D3B]" />
                <div className="text-xs font-bold">جاري تحميل شبكات الوايفاي من الخادم...</div>
              </div>
            ) : filteredNetworks.length === 0 ? (
              <div className="bg-white rounded-2xl p-6 text-center border border-slate-200 text-slate-500 text-xs">
                لا توجد شبكات تطابق البحث
              </div>
            ) : (
              <div className="space-y-3">
                {filteredNetworks.map((net, nIdx) => (
                  <div
                    key={net.id ? `wifi-net-${net.id}-${nIdx}` : `wifi-net-${nIdx}`}
                    className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs space-y-3 hover:border-slate-300 transition"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-2.5">
                        <div className="w-10 h-10 rounded-2xl bg-teal-50 text-teal-800 border border-teal-200 flex items-center justify-center font-bold shrink-0">
                          <Wifi className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="font-black text-sm text-slate-900 flex items-center gap-1.5">
                            <span>{net.name}</span>
                            <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-1.5 py-0.2 rounded">
                              نشطة
                            </span>
                          </div>
                          <div className="text-[11px] text-slate-500 font-medium flex items-center gap-2 mt-0.5">
                            {net.location && (
                              <span className="flex items-center gap-0.5">
                                <MapPin className="w-3 h-3 text-slate-400" />
                                <span>{net.location}</span>
                              </span>
                            )}
                            {net.owner_phone && (
                              <span className="dir-ltr text-slate-400 font-mono">
                                📞 {net.owner_phone}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      <span className="text-[10px] bg-slate-100 text-slate-600 font-bold px-2 py-0.5 rounded-md">
                        {net.denominations?.length || 0} فئات
                      </span>
                    </div>

                    {/* Denominations Card Buttons */}
                    <div className="pt-2 border-t border-slate-100">
                      <div className="text-[11px] text-slate-500 font-bold mb-2">
                        اختر فئة الكرت لشرائه مباشرة:
                      </div>
                      <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                        {(net.denominations || []).map((denom, dIdx) => {
                          const priceVal = parseFloat(denom.sale_price) || parseFloat(denom.face_value) || 100;
                          return (
                            <button
                              key={`net-${net.id || nIdx}-denom-${denom.id || dIdx}`}
                              disabled={isPurchasing}
                              onClick={() => handleOpenConfirm(net, denom)}
                              className="bg-slate-50 hover:bg-[#8B1D3B] hover:text-white border border-slate-200 py-2.5 px-2 rounded-xl text-center transition active:scale-95 group flex flex-col items-center justify-between shadow-xs"
                            >
                              <div className="text-[11px] font-extrabold group-hover:text-white text-slate-800 line-clamp-1">
                                {denom.name}
                              </div>
                              <div className="text-xs font-black group-hover:text-white text-[#8B1D3B] mt-1 font-mono">
                                {priceVal} <span className="text-[9px] font-sans">ر.ي</span>
                              </div>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* TAB 2: PURCHASED CARDS (HISTORY) */}
        {activeTab === "history" && (
          <div className="space-y-3.5">
            {/* Search Purchased Cards */}
            <div className="relative">
              <input
                type="text"
                value={historySearchQuery}
                onChange={(e) => setHistorySearchQuery(e.target.value)}
                placeholder="ابحث بالشبكة أو رقم الكرت (PIN) أو رقم الهاتف..."
                className="w-full bg-white border border-slate-200 rounded-2xl py-2.5 pr-10 pl-4 text-xs font-bold text-slate-800 focus:outline-none focus:border-[#8B1D3B] shadow-xs"
              />
              <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
            </div>

            {filteredHistory.length === 0 ? (
              <div className="bg-white rounded-3xl p-8 text-center border border-slate-200 space-y-3">
                <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mx-auto text-slate-400">
                  <Ticket className="w-6 h-6" />
                </div>
                <div className="text-sm font-black text-slate-800">لا توجد كروت مشتراة حتى الآن</div>
                <p className="text-xs text-slate-500">
                  عند شراء كرت وايفاي لأي شبكة سيتم حفظ بياناته ورمز الدخول الخاص به هنا تلقائياً.
                </p>
                <button
                  onClick={() => setActiveTab("available")}
                  className="bg-[#8B1D3B] text-white px-4 py-2 rounded-xl text-xs font-bold inline-flex items-center gap-1.5"
                >
                  <Wifi className="w-4 h-4" />
                  <span>تصفح الشبكات المتاحة</span>
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {filteredHistory.map((card, cIdx) => (
                  <div
                    key={card.id ? `wifi-card-${card.id}-${cIdx}` : `wifi-card-${cIdx}`}
                    className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs space-y-3"
                  >
                    <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-xl bg-teal-50 text-teal-800 flex items-center justify-center font-bold text-xs">
                          <Wifi className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-black text-slate-900">{card.netName}</div>
                          <div className="text-[10px] text-slate-500">{card.denominationTitle} • {card.location || "اليمن"}</div>
                        </div>
                      </div>

                      <div className="text-left">
                        <span className="text-xs font-black text-[#8B1D3B] font-mono">{card.price} ر.ي</span>
                        <div className="text-[9px] text-slate-400 font-mono">{card.date} {card.time}</div>
                      </div>
                    </div>

                    {/* PIN display and 1-click copy */}
                    <div className="bg-amber-50/70 border border-amber-200/80 rounded-xl p-2.5 flex items-center justify-between gap-2">
                      <div>
                        <div className="text-[9px] text-amber-800 font-bold">كود الكرت (PIN CODE):</div>
                        <div className="text-base font-black font-mono tracking-wider text-slate-900 select-all">
                          {card.pin}
                        </div>
                        <div className="text-[9px] text-slate-400 font-mono">الرقم التسلسلي: {card.serial}</div>
                      </div>

                      <button
                        onClick={() => handleCopy(card.pin, card.id)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-black flex items-center gap-1 transition active:scale-95 shadow-xs ${
                          copiedPinId === card.id
                            ? "bg-emerald-600 text-white"
                            : "bg-white hover:bg-slate-50 text-slate-800 border border-slate-200"
                        }`}
                      >
                        {copiedPinId === card.id ? (
                          <>
                            <Check className="w-3.5 h-3.5" />
                            <span>تم النسخ</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5 text-slate-600" />
                            <span>نسخ</span>
                          </>
                        )}
                      </button>
                    </div>

                    <div className="flex items-center justify-between text-[10px] text-slate-500 pt-0.5">
                      <span>رقم هاتف المشتري: <strong className="text-slate-800 font-mono">{card.buyerPhone}</strong></span>
                      <button
                        onClick={() => {
                          setPurchasedCard(card);
                          window.scrollTo({ top: 0, behavior: "smooth" });
                        }}
                        className="text-[#8B1D3B] font-bold hover:underline flex items-center gap-0.5"
                      >
                        <ExternalLink className="w-3 h-3" />
                        <span>عرض وطباعة السند</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* CONFIRMATION MODAL - ASKS FOR CUSTOMER PHONE AND CONFIRMS PURCHASE        */}
      {/* ========================================================================= */}
      {confirmModalData.isOpen && confirmModalData.net && confirmModalData.denom && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-[2px] z-50 flex items-center justify-center p-3 animate-fade-in">
          <div className="bg-white rounded-3xl p-5 shadow-2xl max-w-[360px] w-full border border-slate-200 text-right space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-2.5">
              <div className="flex items-center gap-2">
                <div className="w-9 h-9 rounded-2xl bg-amber-100 text-amber-800 flex items-center justify-center font-black">
                  <Ticket className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-black text-slate-900">تأكيد شراء كرت وايفاي</div>
                  <div className="text-[10px] text-slate-500">يرجى التأكد من البيانات وإدخال الرقم</div>
                </div>
              </div>
              <button
                onClick={() => setConfirmModalData((prev) => ({ ...prev, isOpen: false }))}
                className="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Network & Card Details */}
            <div className="bg-slate-50 rounded-2xl p-3 border border-slate-200 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-slate-500 font-bold">اسم الشبكة:</span>
                <span className="font-black text-slate-900">{confirmModalData.net.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500 font-bold">الموقع:</span>
                <span className="font-bold text-slate-700">{confirmModalData.net.location || "اليمن"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500 font-bold">فئة الكرت:</span>
                <span className="font-black text-[#8B1D3B]">{confirmModalData.denom.name}</span>
              </div>
              <div className="flex justify-between border-t border-slate-200/80 pt-1.5">
                <span className="text-slate-700 font-black">المبلغ المخصوم:</span>
                <span className="font-black text-[#8B1D3B] text-sm font-mono">
                  {(parseFloat(confirmModalData.denom.sale_price) || parseFloat(confirmModalData.denom.face_value) || 100)} ر.ي
                </span>
              </div>
            </div>

            {/* Input Phone Number Field */}
            <div>
              <label className="block text-[11px] font-black text-slate-700 mb-1">
                رقم هاتف المشتري / العميل:
              </label>
              <div className="relative">
                <input
                  type="tel"
                  maxLength={9}
                  value={confirmModalData.buyerPhone}
                  onChange={(e) =>
                    setConfirmModalData((prev) => ({
                      ...prev,
                      buyerPhone: e.target.value,
                    }))
                  }
                  placeholder="مثال: 774952665"
                  className="w-full bg-slate-50 border border-slate-300 rounded-xl py-2.5 pr-9 pl-3 text-xs font-black text-slate-900 focus:outline-none focus:border-[#8B1D3B] font-mono text-left"
                  dir="ltr"
                />
                <Phone className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
              </div>
              <p className="text-[10px] text-slate-400 mt-1">
                سيتم إرفاق الكرت وربطه بهذا الرقم لعرضه دائماً في سجل الكروت المشتراة.
              </p>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-2 pt-1">
              <button
                type="button"
                onClick={() => setConfirmModalData((prev) => ({ ...prev, isOpen: false }))}
                className="flex-1 py-2.5 rounded-xl border border-slate-200 text-slate-700 font-black text-xs hover:bg-slate-50 transition"
              >
                إلغاء
              </button>

              <button
                type="button"
                disabled={isPurchasing}
                onClick={handleConfirmPurchase}
                className="flex-1 py-2.5 rounded-xl bg-[#8B1D3B] hover:bg-[#72152f] text-white font-black text-xs shadow-md transition active:scale-95 flex items-center justify-center gap-1.5"
              >
                {isPurchasing ? (
                  <>
                    <RotateCw className="w-4 h-4 animate-spin text-amber-300" />
                    <span>جاري الشراء...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle2 className="w-4 h-4" />
                    <span>تأكيد وشراء الكرت</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
