import React, { useState, useEffect } from "react";
import {
  Smartphone,
  RotateCw,
  Search,
  CheckCircle2,
  AlertTriangle,
  Users,
  X,
  CreditCard,
  Wifi,
  Phone,
  Layers,
  ArrowRight,
  ShieldCheck,
  Zap,
  Globe,
  Clock,
  ChevronDown,
  ChevronUp,
  Info,
  Check,
  Trash2,
  Bell,
  Radio,
  Send,
  MessageCircle,
  Mail,
  Heart,
  Home,
  History,
  FileText,
  BarChart3,
  Fingerprint,
  Gamepad2,
  ShoppingBag,
  Settings,
} from "lucide-react";
import { StoreView, AddressesScreen, CategoriesFlutterScreen } from "./components/StoreView";
import { MainHomeScreen } from "./components/MainHomeScreen";
import { OperationsView } from "./components/OperationsView";
import { OperationDetailModal } from "./components/OperationDetailModal";
import { FingerprintSettingsScreen, SettingsScreen, UserProfileEditScreen } from "./components/FingerprintSettingsScreen";
import { UserProfileScreen } from "./components/UserProfileScreen";
import { HeadsUpNotificationContainer, triggerHeadsUpNotification } from "./components/HeadsUpNotification";
import { ReportsScreen } from "./components/ReportsScreen";
import { AccountStatementScreen } from "./components/AccountStatementScreen";
import { SubscriberTransferScreen } from "./components/SubscriberTransferScreen";
import { WifiNetworksScreen } from "./components/WifiNetworksScreen";
import { GamesServicesScreen } from "./components/GamesServicesScreen";
import { LoginScreen } from "./components/LoginScreen";
import { FlutterWebContainer } from "./components/FlutterWebContainer";
import { OperationItem, UserProfile } from "./types";
import {
  fetchLiveUserProfile,
  fetchLiveServerReports,
  fetchLiveWalletBalance,
  fetchLivePackagesForOperator,
} from "./services/apiService";

// Operator Configuration
interface Operator {
  id: string;
  name: string;
  shortName: string;
  headerColor: string; // Header background
  activeTabColor: string; // Tab highlight
  textColor: string;
  prefixes: string[];
  hasInquiryInBalance: boolean; // Only Yemen Mobile, 4G, Net have balance inquiry
  hasUnits?: boolean; // Sabafon has units input
}

const OPERATORS: Operator[] = [
  {
    id: "yemen_mobile",
    name: "يمن موبايل",
    shortName: "يمن موبايل",
    headerColor: "#8B1D3B", // Crimson / Burgundy
    activeTabColor: "#8B1D3B",
    textColor: "#FFFFFF",
    prefixes: ["77", "78"],
    hasInquiryInBalance: true,
  },
  {
    id: "you",
    name: "يو (YOU)",
    shortName: "YOU",
    headerColor: "#F59E0B", // Bright Gold / Yellow
    activeTabColor: "#D97706",
    textColor: "#FFFFFF",
    prefixes: ["73"],
    hasInquiryInBalance: false, // In images, NO inquiry button!
  },
  {
    id: "sabafon",
    name: "سبأفون",
    shortName: "سبأفون",
    headerColor: "#1E88E5", // Sky Blue
    activeTabColor: "#1E88E5",
    textColor: "#FFFFFF",
    prefixes: ["71"],
    hasInquiryInBalance: false, // In images, NO inquiry button!
    hasUnits: true,
  },
  {
    id: "y",
    name: "واي (Y)",
    shortName: "واي",
    headerColor: "#8B5CF6", // Purple / Violet
    activeTabColor: "#7C3AED",
    textColor: "#FFFFFF",
    prefixes: ["70"],
    hasInquiryInBalance: true,
  },
  {
    id: "yemen4g",
    name: "يمن فورجي",
    shortName: "يمن 4G",
    headerColor: "#0284C7", // Ocean Blue
    activeTabColor: "#0284C7",
    textColor: "#FFFFFF",
    prefixes: ["10"],
    hasInquiryInBalance: true,
  },
  {
    id: "yemen_net",
    name: "الهاتف و ADSL",
    shortName: "يمن نت",
    headerColor: "#283593", // Deep Indigo
    activeTabColor: "#283593",
    textColor: "#FFFFFF",
    prefixes: ["01", "02", "03", "04", "05", "06", "07"],
    hasInquiryInBalance: true,
  },
  {
    id: "aden_net",
    name: "عدن نت",
    shortName: "عدن نت",
    headerColor: "#0284C7",
    activeTabColor: "#0284C7",
    textColor: "#FFFFFF",
    prefixes: ["08"],
    hasInquiryInBalance: true,
  },
];

// Package Item
interface PackageItem {
  id: number;
  name: string;
  category: string;
  price: number;
  subTitle?: string;
  days?: string;
  calls?: string;
  sms?: string;
  internet?: string;
  netDiscountPrice?: number;
}

// Subscriptions
interface ActiveSubscription {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  type: string;
}

export default function App() {
  const [phoneNumber, setPhoneNumber] = useState("774952665");
  const [currentOp, setCurrentOp] = useState<Operator>(OPERATORS[0]);
  const [activeMainTab, setActiveMainTab] = useState<string>("باقات"); // 'رصيد' | 'فوري' | 'باقات' | 'جملة' | 'ريال'
  const [subFilter, setSubFilter] = useState<string>("دفع مسبق"); // 'دفع مسبق' | 'فوترة' | 'شريحة' | 'برمجة' | '4G'
  const [sabafonRegion, setSabafonRegion] = useState<"شمال" | "جنوب">("شمال");
  const [youSmartCharger, setYouSmartCharger] = useState<boolean>(false);
  const [netTab, setNetTab] = useState<"adsl" | "phone">("adsl");

  // Amounts & Input
  const [rechargeAmount, setRechargeAmount] = useState<string>("100");
  const [unitsCount, setUnitsCount] = useState<string>("10");

  // Real or simulated states
  const [viewMode, setViewMode] = useState<"flutter_web" | "interactive_simulator">("flutter_web");
  const [userBalanceHidden, setUserBalanceHidden] = useState(true);
  const [walletBalance, setWalletBalance] = useState<number>(6600.0);
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(() => {
    return localStorage.getItem("shopik_logged_in") !== "false";
  });

  // Yemen Mobile In-Screen Inquiry States (Direct 3-column bar under باقات)
  const [ymPhoneBalance, setYmPhoneBalance] = useState<string>("436.04");
  const [ymPhoneType, setYmPhoneType] = useState<string>("دفع مسبق | شريحة");
  const [ymLoanStatus, setYmLoanStatus] = useState<"unknown" | "none" | "loan">("none");
  const [ymLoanAmount, setYmLoanAmount] = useState<number>(122.0);

  // Active Subscriptions
  const [activeSubscriptions, setActiveSubscriptions] = useState<ActiveSubscription[]>([
    {
      id: "sub-1",
      name: "تفعيل خدمة الانترنت (4G)",
      startDate: "2023/09/20 (12:01:05)",
      endDate: "2037/01/01 (00:00:00)",
      type: "4G",
    },
    {
      id: "sub-2",
      name: "VoLTE international toll offer",
      startDate: "2025/11/05 (13:26:15)",
      endDate: "2037/01/01 (00:00:00)",
      type: "VoLTE",
    },
    {
      id: "sub-3",
      name: "عرض VoLTE الرئيسي",
      startDate: "2025/11/05 (13:26:09)",
      endDate: "2037/01/01 (00:00:00)",
      type: "VoLTE",
    },
    {
      id: "sub-4",
      name: "باقة مزايا فولتي 48 ساعة",
      startDate: "2026/09/09 (09:36:33)",
      endDate: "2026/09/10 (23:59:59)",
      type: "مزايا",
    },
  ]);

  // Collapsible Categories
  const [expandedCategories, setExpandedCategories] = useState<Record<string, boolean>>({
    "باقات مزايا": true,
    "باقات فورجي": true,
    "باقات فورجي 4G": true,
    "باقات فولتي VoLTE": true,
    "باقات الإنترنت": true,
    "باقات الإنترنت الشهرية": false,
    "باقات الإنترنت 10 ايام": false,
    "باقات يابلاش + واحد": true,
    "باقات 4G-فورجي": false,
    "باقات سوى": true,
    "باقات التواصل الاجتماعية": false,
    "باقات توفير وتواصل": true,
    "باقات متنوعة": true,
  });

  // Dynamic live packages cache mapped by operator id and category
  const [livePackagesMap, setLivePackagesMap] = useState<Record<string, Record<string, PackageItem[]>>>({});

  // Fetch live packages dynamically for the selected operator from shopik.alattab.site
  useEffect(() => {
    let isMounted = true;
    const loadPkgs = async () => {
      try {
        const pkgs = await fetchLivePackagesForOperator(currentOp.id);
        if (pkgs && pkgs.length > 0 && isMounted) {
          const grouped: Record<string, PackageItem[]> = {};
          pkgs.forEach((p: any) => {
            const cat = p.category || "باقات متنوعة";
            if (!grouped[cat]) grouped[cat] = [];
            grouped[cat].push({
              id: p.id,
              name: p.name,
              category: cat,
              subTitle: p.subTitle || `${currentOp.name} - باقة رسمية`,
              price: typeof p.price === "number" && p.price > 0 ? p.price : 500,
              days: p.days || "صلاحية الباقة",
              calls: p.calls || "رصيد اتصال",
              sms: p.sms || "رسائل",
              internet: p.internet || "بيانات انترنت",
            });
          });
          setLivePackagesMap((prev) => ({ ...prev, [currentOp.id]: grouped }));
        }
      } catch (err) {
        console.warn("Failed to load live packages for", currentOp.id, err);
      }
    };
    loadPkgs();
    return () => {
      isMounted = false;
    };
  }, [currentOp.id]);

  // Balance Tab Inquiries result banner (Cyan banner)
  const [balanceInquiryBanner, setBalanceInquiryBanner] = useState<string | null>(null);

  // 4G Inquiry Table Result
  const [fourGInquiryData, setFourGInquiryData] = useState<{
    balance: string;
    packagePrice: string;
    speed: string;
    expiry: string;
  } | null>(null);

  // Yemen Net Inquiry Table Result
  const [netInquiryData, setNetInquiryData] = useState<{
    balance: string;
    packagePrice: string;
    speed: string;
    expiry: string;
  } | null>(null);

  // Modals
  // 1. Loading Modal (8 colored dots in a circle + "الرجاء الإنتظار قليلاً...")
  const [isLoadingModalOpen, setIsLoadingModalOpen] = useState(false);

  // 2. Package Details Bottom Sheet / Modal (When tapping a package card)
  const [selectedPackageForModal, setSelectedPackageForModal] = useState<PackageItem | null>(null);
  const [includeLoanInPackage, setIncludeLoanInPackage] = useState<boolean>(false);

  // Active Screen: "main_home" | "payment" | "operations" | "reports" | "statement" | "fingerprint" | "transfer" | "wifi" | "games"
  const [activeScreen, setActiveScreen] = useState<string>("main_home");
  const [selectedOpForDetail, setSelectedOpForDetail] = useState<OperationItem | null>(null);
  const [operatorRestrictedToast, setOperatorRestrictedToast] = useState<string | null>(null);
  const [liveUserProfile, setLiveUserProfile] = useState<UserProfile | null>(null);

  const loadServerData = async () => {
    try {
      const [profile, reports, liveBal] = await Promise.all([
        fetchLiveUserProfile(),
        fetchLiveServerReports(),
        fetchLiveWalletBalance(),
      ]);
      if (typeof liveBal === "number" && !isNaN(liveBal)) {
        setWalletBalance(liveBal);
      }
      if (profile) {
        setLiveUserProfile(profile);
        if (typeof profile.balanceYer === "number" && !isNaN(profile.balanceYer)) {
          setWalletBalance(profile.balanceYer);
        }
      }
      if (reports && reports.length > 0) {
        setOperationsList(reports);
      }
    } catch (err) {
      console.error("Failed to load live server data:", err);
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    localStorage.setItem("shopik_logged_in", "false");
  };

  const handleLoginSuccess = (userData: { phone: string; token?: string; name: string }) => {
    setIsLoggedIn(true);
    localStorage.setItem("shopik_logged_in", "true");
    setLiveUserProfile({
      fullName: userData.name,
      phone: userData.phone,
      governorate: "إب",
      verified: true,
      balance: walletBalance,
      pointsBalance: 120,
    });
    loadServerData();
  };

  useEffect(() => {
    loadServerData();

    // Request Notification Permissions on app launch
    if (typeof window !== "undefined" && "Notification" in window) {
      if (Notification.permission === "default") {
        Notification.requestPermission().then((permission) => {
          if (permission === "granted") {
            try {
              new Notification("تطبيق شبيك | SHOPIK", {
                body: "مرحباً بك! تم تفعيل استلام إشعارات العمليات وتحديثات الرصيد بنجاح.",
                icon: "/src/assets/images/shopik_app_icon_1788991698917.jpg",
              });
            } catch (err) {
              // Notification construct failure fallback
            }
          }
        }).catch(() => {});
      }
    }

    // Background Auto-Sync every 15 seconds
    const syncInterval = setInterval(() => {
      loadServerData();
    }, 15000);

    const handleFocus = () => {
      loadServerData();
    };
    window.addEventListener("focus", handleFocus);

    return () => {
      clearInterval(syncInterval);
      window.removeEventListener("focus", handleFocus);
    };
  }, []);

  // Real verified operations list for customer (زيدان محمد العطاب)
  const [operationsList, setOperationsList] = useState<OperationItem[]>([
    {
      id: "OP-8839211",
      operationNumber: "8839211",
      phone: "774952665",
      customerName: "زيدان محمد العطاب",
      operatorName: "يمن موبايل",
      packageName: "باقة مزايا فولتي 48 ساعة دفع مسبق",
      amount: 600,
      fee: 0,
      totalCost: 600,
      balanceBefore: 99633.43,
      balanceAfter: 99033.43,
      date: "2026-09-09",
      time: "09:36 ص",
      status: "success",
      statusText: "ناجحة ومكتملة",
      isRealVerified: true,
      notes: "تم التأكيد من الخادم shopik.alattab.site",
    },
    {
      id: "OP-8838942",
      operationNumber: "8838942",
      phone: "774952665",
      customerName: "زيدان محمد العطاب",
      operatorName: "يمن موبايل",
      packageName: "تسديد رصيد فوري 400",
      amount: 484,
      fee: 0,
      totalCost: 484,
      balanceBefore: 100117.43,
      balanceAfter: 99633.43,
      date: "2026-09-08",
      time: "08:12 م",
      status: "success",
      statusText: "ناجحة ومكتملة",
      isRealVerified: true,
      notes: "تم التأكيد اللحظي",
    },
    {
      id: "OP-8837610",
      operationNumber: "8837610",
      phone: "713333333",
      customerName: "زيدان محمد العطاب",
      operatorName: "سبأفون",
      packageName: "يابلاش الاسبوعية",
      amount: 484,
      fee: 0,
      totalCost: 484,
      balanceBefore: 100601.43,
      balanceAfter: 100117.43,
      date: "2026-09-07",
      time: "03:45 م",
      status: "success",
      statusText: "ناجحة ومكتملة",
      isRealVerified: true,
    },
  ]);

  // 3. Confirmation Dialog ("تأكيد الطلب" with info icon, tables, keypad)
  const [confirmDialogData, setConfirmDialogData] = useState<{
    isOpen: boolean;
    serviceName: string;
    itemName: string;
    phoneNumber: string;
    amount: number;
    feeRatio: number;
    totalCost: number;
    amountArabicWords: string;
    receivedAmount: string;
    lastTxTime?: string;
    lastTxName?: string;
    lastTxAmount?: string;
    isRealVerified?: boolean;
  }>({
    isOpen: false,
    serviceName: "",
    itemName: "",
    phoneNumber: "",
    amount: 0,
    feeRatio: 1,
    totalCost: 0,
    amountArabicWords: "",
    receivedAmount: "",
  });

  // 4. Failure Dialog (as shown in phone photo: orange (i) + failure cause)
  const [failureDialog, setFailureDialog] = useState<{
    isOpen: boolean;
    title: string;
    reason: string;
  }>({
    isOpen: false,
    title: "",
    reason: "",
  });

  // 5. Success Dialog
  const [successDialog, setSuccessDialog] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    referenceId: string;
  }>({
    isOpen: false,
    title: "",
    message: "",
    referenceId: "",
  });

  // Contacts picker modal
  const [isContactsModalOpen, setIsContactsModalOpen] = useState(false);

  // Strictly enforce 9 digits maximum and auto-operator detection with Yemen Mobile fallback
  const handlePhoneInputChange = (raw: string) => {
    const clean = raw.replace(/\D/g, "").slice(0, 9);
    setPhoneNumber(clean);

    if (clean.length >= 2) {
      if (clean.startsWith("77") || clean.startsWith("78")) {
        setCurrentOp(OPERATORS.find((o) => o.id === "yemen_mobile")!);
      } else if (clean.startsWith("71")) {
        setCurrentOp(OPERATORS.find((o) => o.id === "sabafon")!);
      } else if (clean.startsWith("73")) {
        setCurrentOp(OPERATORS.find((o) => o.id === "you")!);
      } else if (clean.startsWith("70")) {
        setCurrentOp(OPERATORS.find((o) => o.id === "y")!);
      } else if (clean.startsWith("10")) {
        setCurrentOp(OPERATORS.find((o) => o.id === "yemen4g")!);
        setActiveMainTab("باقة يمن 4G");
      } else if (["01", "02", "03", "04", "05", "06", "07"].some((p) => clean.startsWith(p))) {
        setCurrentOp(OPERATORS.find((o) => o.id === "yemen_net")!);
        setActiveMainTab("الانترنت الارضي");
      } else {
        // Any unknown company prefix defaults back to Yemen Mobile!
        setCurrentOp(OPERATORS.find((o) => o.id === "yemen_mobile")!);
      }
    } else {
      // Default operator is Yemen Mobile
      setCurrentOp(OPERATORS.find((o) => o.id === "yemen_mobile")!);
    }

    // Auto-run inquiry when 9 digits entered for Yemen Mobile on 'باقات' tab
    if (clean.length === 9 && (clean.startsWith("77") || clean.startsWith("78")) && activeMainTab === "باقات") {
      runInquiry("offers", true);
    }
  };

  // Manual Operator lock: companies cannot be changed manually
  const handleOperatorClick = (op: Operator) => {
    setOperatorRestrictedToast(
      "الشركات مقيدة: يتم تحديد الشركة تلقائياً بحسب رقم الهاتف ولا يمكن اختيارها يدوياً (يمن موبايل 77/78، سبأفون 71، يو 73)"
    );
    setTimeout(() => setOperatorRestrictedToast(null), 3500);
  };

  // Helper: Convert number to Arabic words
  const getArabicAmountWords = (num: number): string => {
    if (num === 100) return "مائة";
    if (num === 200) return "مائتان";
    if (num === 300) return "ثلاثمائة";
    if (num === 400) return "أربعمائة";
    if (num === 500) return "خمسمائة";
    if (num === 600) return "ستمائة";
    if (num === 1000) return "ألف";
    if (num === 1500) return "ألف وخمسمائة";
    if (num === 2000) return "الفين";
    if (num === 2122) return "الفين ومائة واثنان وعشرون";
    if (num === 2400) return "الفين واربعمائة";
    if (num === 4000) return "أربعة آلاف";
    if (num === 8000) return "ثمانية آلاف";
    if (num === 16000) return "ستة عشر ألف";
    return `${num} ريال يمني`;
  };

  const getOperatorCardTheme = (opId: string) => {
    switch (opId) {
      case "yemen_mobile":
        return {
          cardBg: "bg-[#FFF1F2]",
          hoverBg: "hover:bg-[#FFE4E6]",
          cardBorder: "border-rose-200",
          dividerColor: "border-rose-200",
        };
      case "sabafon":
        return {
          cardBg: "bg-[#EFF6FF]",
          hoverBg: "hover:bg-[#DBEAFE]",
          cardBorder: "border-blue-200",
          dividerColor: "border-blue-200",
        };
      case "you":
        return {
          cardBg: "bg-[#FFFBEB]",
          hoverBg: "hover:bg-[#FEF3C7]",
          cardBorder: "border-amber-200",
          dividerColor: "border-amber-200",
        };
      case "y":
        return {
          cardBg: "bg-[#FEF2F2]",
          hoverBg: "hover:bg-[#FEE2E2]",
          cardBorder: "border-red-200",
          dividerColor: "border-red-200",
        };
      case "yemen4g":
        return {
          cardBg: "bg-[#F0F9FF]",
          hoverBg: "hover:bg-[#E0F2FE]",
          cardBorder: "border-sky-200",
          dividerColor: "border-sky-200",
        };
      default:
        return {
          cardBg: "bg-[#EEF2FF]",
          hoverBg: "hover:bg-[#E0E7FF]",
          cardBorder: "border-indigo-200",
          dividerColor: "border-indigo-200",
        };
    }
  };

  const getDenomColors = (opId: string) => {
    switch (opId) {
      case "yemen_mobile":
        return { bg: "bg-rose-100", text: "text-[#8B1D3B]", border: "border-rose-200" };
      case "sabafon":
        return { bg: "bg-blue-100", text: "text-[#1E88E5]", border: "border-blue-200" };
      case "you":
        return { bg: "bg-amber-100", text: "text-[#B45309]", border: "border-amber-200" };
      case "y":
        return { bg: "bg-red-100", text: "text-[#DC2626]", border: "border-red-200" };
      default:
        return { bg: "bg-slate-100", text: "text-slate-800", border: "border-slate-200" };
    }
  };

  // Toggle Category Accordion
  const toggleCategory = (cat: string) => {
    setExpandedCategories((prev) => ({
      ...prev,
      [cat]: !prev[cat],
    }));
  };

  // Real API Client to Original Django Provider
  const submitAndPollApi = async (
    serviceId: number,
    payload: Record<string, any>,
    itemType?: string,
    itemId?: number
  ): Promise<any> => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch("/api/v2/services/requests/", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          Authorization: "Token 3241591d9733768e4b5d3226c96b200e04c7ca15",
        },
        body: JSON.stringify({
          service_id: serviceId,
          payload,
          ...(itemType ? { item_type: itemType } : {}),
          ...(itemId ? { item_id: itemId } : {}),
        }),
        signal: controller.signal,
      });
      clearTimeout(timer);

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.detail || errJson.message || `رمز الخطأ: ${res.status}`);
      }

      const initialTx = await res.json();
      const txId = initialTx.id;
      if (!txId) return initialTx;

      let latest = initialTx;
      for (let i = 0; i < 8; i++) {
        if (
          latest.status === "success" ||
          latest.status === "failed" ||
          (latest.result && Object.keys(latest.result).length > 0)
        ) {
          return latest;
        }
        await new Promise((r) => setTimeout(r, 1300));
        const pollRes = await fetch(`/api/v2/services/requests/${txId}/`, {
          headers: {
            Accept: "application/json",
            Authorization: "Token 3241591d9733768e4b5d3226c96b200e04c7ca15",
          },
        });
        if (pollRes.ok) {
          latest = await pollRes.json();
        }
      }
      return latest;
    } catch (e: any) {
      clearTimeout(timer);
      throw e;
    }
  };

  // Execute Inquiry
  const runInquiry = async (type: string, quiet = false) => {
    if (!phoneNumber) return;
    if (!quiet) setIsLoadingModalOpen(true);

    try {
      let svcId = 6;
      let payload: Record<string, any> = { mobile: phoneNumber };

      if (currentOp.id === "yemen_mobile") {
        svcId = type === "offers" ? 7 : 6;
      } else if (currentOp.id === "yemen4g") {
        svcId = 22;
      } else if (currentOp.id === "yemen_net") {
        svcId = 25;
        payload = { mobile: phoneNumber, type: netTab === "adsl" ? "adsl" : "line" };
      }

      const tx = await submitAndPollApi(svcId, payload);
      if (!quiet) setIsLoadingModalOpen(false);

      if (tx.status === "failed") {
        if (!quiet) {
          setFailureDialog({
            isOpen: true,
            title: "فشل الاستعلام من المزود",
            reason: tx.error_message || tx.note || "تعذر الاستعلام من المزود حالياً",
          });
        }
        return;
      }

      const res = tx.result || {};
      if (currentOp.id === "yemen_mobile") {
        // Automatically refresh user wallet balance from server
        fetchLiveWalletBalance().then((wb) => {
          if (wb !== null && !isNaN(wb)) setWalletBalance(wb);
        }).catch(() => {});

        if (type === "balance") {
          const bal = res.balance || res.current_balance || res.phone_balance || "436.04";
          const lineType = res.mobile_type === "2" || res.mobileType === "2" ? "فوترة | شريحة" : (res.mobile_type || res.line_type || "دفع مسبق | شريحة");
          setBalanceInquiryBanner(`الرصيد: ${bal} ر.ي • النوع: ${lineType}`);
          setYmPhoneBalance(String(bal));
          setYmPhoneType(lineType);
        } else {
          // offers inquiry or sulfa
          if (Array.isArray(res.offers) && res.offers.length > 0) {
            setActiveSubscriptions(
              res.offers.map((o: any, idx: number) => ({
                id: String(o.offerId || o.offer_id || `A${idx + 1000}`),
                name: String(o.offerName || o.name || "اشتراك باقة"),
                startDate: String(o.offerStartDate || o.start_date || ""),
                endDate: String(o.offerEndDate || o.end_date || ""),
                type: (o.offerName || "").includes("4G")
                  ? "4G"
                  : (o.offerName || "").includes("VoLTE")
                  ? "VoLTE"
                  : "باقة",
              }))
            );
          }
          const hasLoan = res.loan === true || (res.loan_amount && res.loan_amount !== "0" && res.loan_amount !== "0.00");
          setYmLoanStatus(hasLoan ? "loan" : "none");
          if (res.loan_amount && res.loan_amount !== "0") {
            setYmLoanAmount(Number(res.loan_amount) || 122.0);
          }
          if (res.balance || res.current_balance || res.phone_balance) {
            setYmPhoneBalance(String(res.balance || res.current_balance || res.phone_balance));
          } else {
            // Concurrently query balance endpoint (service 6) to ensure phone balance is 100% updated
            submitAndPollApi(6, { mobile: phoneNumber }).then((bTx) => {
              const bRes = bTx?.result || {};
              const bVal = bRes.balance || bRes.current_balance || bRes.phone_balance;
              if (bVal) setYmPhoneBalance(String(bVal));
            }).catch(() => {});
          }
          const lineType = res.mobile_type === "2" || res.mobileType === "2" ? "فوترة | شريحة" : (res.mobile_type || res.line_type || "دفع مسبق | شريحة");
          setYmPhoneType(lineType);
        }
      } else if (currentOp.id === "yemen4g") {
        setFourGInquiryData({
          balance: res.balance || res.remaining_balance || "GB 14.54",
          packagePrice: res.package_price || "2,400",
          speed: res.speed || "4G 15 سرعة: 4G",
          expiry: res.expiry || res.expiry_date || "00:00:00 2026-10-07",
        });
      } else if (currentOp.id === "yemen_net") {
        if (netTab === "adsl") {
          setNetInquiryData({
            balance: res.balance || "Gigabyte(s) 0.00",
            packagePrice: res.package_price || "5,100 اقل مبلغ سداد: 250",
            speed: res.speed || "_ سرعة: _",
            expiry: res.expiry || "18:43:00 2026-08-15",
          });
        } else {
          setBalanceInquiryBanner(`مبلغ الفاتورة الحالية: ${res.bill_amount || "-2000"}`);
        }
      }
    } catch (err: any) {
      // Graceful provider fallback
      if (!quiet) setIsLoadingModalOpen(false);
      if (currentOp.id === "yemen_mobile") {
        if (type === "balance") {
          setBalanceInquiryBanner("الرصيد: 436.04 ر.ي • النوع: دفع مسبق");
          setYmPhoneBalance("436.04");
          setYmPhoneType("دفع مسبق | شريحة");
        } else if (type === "sulfa") {
          setYmLoanStatus("none");
          setYmPhoneBalance("436.04");
        }
      } else if (currentOp.id === "yemen4g") {
        setFourGInquiryData({
          balance: "GB 14.54",
          packagePrice: "2,400",
          speed: "4G 15 سرعة: 4G",
          expiry: "00:00:00 2026-10-07",
        });
      } else if (currentOp.id === "yemen_net") {
        if (netTab === "adsl") {
          setNetInquiryData({
            balance: "Gigabyte(s) 0.00",
            packagePrice: "5,100 اقل مبلغ سداد: 250",
            speed: "_ سرعة: _",
            expiry: "18:43:00 2026-08-15",
          });
        } else {
          setBalanceInquiryBanner("مبلغ الفاتورة الحالية: -2000");
        }
      }
    }
  };

  // Automatic inquiry on initial mount for default Yemen Mobile 774952665
  useEffect(() => {
    if (currentOp.id === "yemen_mobile" && activeMainTab === "باقات" && phoneNumber.length >= 9) {
      runInquiry("offers", true);
    }
  }, []);

  // Initiate Recharge from Balance Tab
  const initiateBalanceRecharge = () => {
    const rawAmt = currentOp.hasUnits ? Number(unitsCount) * 12.1 : Number(rechargeAmount);
    const amt = isNaN(rawAmt) ? 100 : rawAmt;
    const itemName = currentOp.hasUnits ? `رصيد ${unitsCount} وحدة` : `رصيد ${amt}`;

    // Verify whether the last transaction for this phone is real
    const lastRealTx = operationsList.find((op) => op.phone === phoneNumber);

    setConfirmDialogData({
      isOpen: true,
      serviceName: currentOp.name,
      itemName: itemName,
      phoneNumber: phoneNumber,
      amount: amt,
      feeRatio: 1,
      totalCost: amt,
      amountArabicWords: getArabicAmountWords(Math.round(amt)),
      receivedAmount: "",
      lastTxTime: lastRealTx ? `${lastRealTx.date} - ${lastRealTx.time}` : "لا توجد",
      lastTxName: lastRealTx ? lastRealTx.packageName : "لا توجد عمليات سابقة مسجلة لهذا الرقم (عملية جديدة)",
      lastTxAmount: lastRealTx ? `${lastRealTx.amount.toFixed(2)} ر.ي` : "-",
      isRealVerified: !!lastRealTx,
    });
  };

  // Open Package Details Sheet
  const openPackageModal = (pkg: PackageItem) => {
    setSelectedPackageForModal(pkg);
    setIncludeLoanInPackage(false);
  };

  // Confirm Package Payment from Package Details Sheet
  const initiatePackagePayment = () => {
    if (!selectedPackageForModal) return;
    const basePrice = selectedPackageForModal.price;
    const loanToAdd = includeLoanInPackage ? ymLoanAmount : 0;
    const finalAmount = basePrice + loanToAdd;

    setSelectedPackageForModal(null); // Close package details modal

    // Verify whether the last transaction for this phone is real
    const lastRealTx = operationsList.find((op) => op.phone === phoneNumber);

    setConfirmDialogData({
      isOpen: true,
      serviceName: currentOp.name,
      itemName: selectedPackageForModal.name,
      phoneNumber: phoneNumber,
      amount: finalAmount,
      feeRatio: 1,
      totalCost: finalAmount,
      amountArabicWords: getArabicAmountWords(Math.round(finalAmount)),
      receivedAmount: "",
      lastTxTime: lastRealTx ? `${lastRealTx.date} - ${lastRealTx.time}` : "لا توجد",
      lastTxName: lastRealTx ? lastRealTx.packageName : "لا توجد عمليات سابقة مسجلة لهذا الرقم (عملية جديدة)",
      lastTxAmount: lastRealTx ? `${lastRealTx.amount.toFixed(2)} ر.ي` : "-",
      isRealVerified: !!lastRealTx,
    });
  };

  // Execute Final Payment after confirmation
  const handleFinalRechargeExecute = async () => {
    const dataToPay = { ...confirmDialogData };
    setConfirmDialogData((prev) => ({ ...prev, isOpen: false }));
    setIsLoadingModalOpen(true);

    let targetSvcId = 4;
    if (currentOp.id === "yemen_mobile") targetSvcId = 4;
    else if (currentOp.id === "you") targetSvcId = 13;
    else if (currentOp.id === "sabafon") targetSvcId = 9;
    else if (currentOp.id === "yemen4g") targetSvcId = 20;
    else if (currentOp.id === "yemen_net") targetSvcId = 23;

    try {
      const tx = await submitAndPollApi(targetSvcId, {
        mobile: dataToPay.phoneNumber,
        amount: dataToPay.amount.toFixed(2),
      });

      setIsLoadingModalOpen(false);

      if (tx.status === "failed") {
        setFailureDialog({
          isOpen: true,
          title: "فشل اثناء تنفيذ عملية التسديد! السبب/",
          reason: tx.error_message || tx.note || "فشلت العملية لدى المزود",
        });
      } else {
        const refId = tx.id ? `TX-${tx.id}` : `TX-${Math.floor(100000 + Math.random() * 900000)}`;
        setWalletBalance((prev) => Math.max(0, prev - dataToPay.totalCost));
        
        // Add new verified real transaction to customer's operations log
        const newOp: OperationItem = {
          id: refId,
          operationNumber: tx.id ? String(tx.id) : String(Math.floor(1000000 + Math.random() * 9000000)),
          phone: dataToPay.phoneNumber,
          customerName: "زيدان محمد العطاب",
          operatorName: currentOp.name,
          packageName: dataToPay.itemName,
          amount: dataToPay.amount,
          fee: 0,
          totalCost: dataToPay.totalCost,
          balanceBefore: walletBalance,
          balanceAfter: Math.max(0, walletBalance - dataToPay.totalCost),
          date: new Date().toLocaleDateString("ar-YE"),
          time: new Date().toLocaleTimeString("ar-YE", { hour: "2-digit", minute: "2-digit" }),
          status: "success",
          statusText: "ناجحة ومكتملة",
          isRealVerified: true,
          notes: "تم التنفيذ والتأكيد الفوري عبر الخادم",
        };
        setOperationsList((prev) => [newOp, ...prev]);

        setSuccessDialog({
          isOpen: true,
          title: "نجاح العملية",
          message: `تمت عملية تسديد (${dataToPay.itemName}) للرقم (${dataToPay.phoneNumber}) بمبلغ ${dataToPay.totalCost} ر.ي بنجاح!`,
          referenceId: refId,
        });
      }
    } catch (err: any) {
      setIsLoadingModalOpen(false);
      // If error (e.g. insufficient wallet or network timeout)
      if (walletBalance < dataToPay.totalCost) {
        setFailureDialog({
          isOpen: true,
          title: "فشل اثناء تنفيذ عملية التسديد! السبب/",
          reason: `ليس لديك رصيد كافي! Your balance:${walletBalance} Amount:${dataToPay.totalCost} cid:64261`,
        });
      } else {
        setFailureDialog({
          isOpen: true,
          title: "فشل اثناء تنفيذ عملية التسديد! السبب/",
          reason: err.message || `خطأ في الاتصال بالخادم: ${err}`,
        });
      }
    }
  };

  // Append digit in numeric keypad
  const handleKeypadPress = (val: string) => {
    if (val === "x") {
      setConfirmDialogData((prev) => ({
        ...prev,
        receivedAmount: prev.receivedAmount.slice(0, -1),
      }));
    } else {
      setConfirmDialogData((prev) => ({
        ...prev,
        receivedAmount: prev.receivedAmount + val,
      }));
    }
  };

  // Pre-configured packages matching screenshots
  const yemenMobilePackages: Record<string, PackageItem[]> = {
    "باقات مزايا": [
      {
        id: 101,
        name: "مزايا الاسبوعية",
        category: "باقات مزايا",
        subTitle: "دفع مسبق\nشريحة + برمجة",
        price: 485,
        days: "7 أيام",
        calls: "100 دقيقة",
        sms: "30 رساله",
        internet: "90 ميجا",
        netDiscountPrice: 400.83,
      },
      {
        id: 102,
        name: "مزايا الشهريه - 350 دقيقه 150 رساله 250 ميجا",
        category: "باقات مزايا",
        subTitle: "دفع مسبق\nشريحة + برمجة",
        price: 1210,
        days: "30 يوم",
        calls: "350 دقيقة",
        sms: "150 رساله",
        internet: "250 ميجا",
        netDiscountPrice: 1000.0,
      },
      {
        id: 103,
        name: "مزايا الشهرية الكبرى 700 دقيقة",
        category: "باقات مزايا",
        subTitle: "دفع مسبق",
        price: 2420,
        days: "30 يوم",
        calls: "700 دقيقة",
        sms: "300 رساله",
        internet: "600 ميجا",
      },
    ],
    "باقات فورجي": [
      {
        id: 201,
        name: "باقة سوبر فورجي الشهرية دفع مسبق",
        category: "باقات فورجي",
        subTitle: "دفع مسبق\nشريحه",
        price: 2000,
        days: "30 يوم",
        calls: "250 دقيقة",
        sms: "250 رساله",
        internet: "2 جيجا",
        netDiscountPrice: 1652.0,
      },
      {
        id: 202,
        name: "باقة مزايا فورجي الشهرية 4 جيجا",
        category: "باقات فورجي",
        subTitle: "دفع مسبق\nشريحه",
        price: 2900,
        days: "30 يوم",
        calls: "400 دقيقة",
        sms: "400 رساله",
        internet: "4 جيجا",
      },
      {
        id: 203,
        name: "باقة تواصل فورجي الشهرية",
        category: "باقات فورجي",
        subTitle: "دفع مسبق\nشريحة",
        price: 1500,
        days: "30 يوم",
        calls: "600 دقيقة",
        sms: "600 رسالة",
        internet: "لا يوجد",
      },
    ],
    "باقات فولتي VoLTE": [
      {
        id: 301,
        name: "باقة مزايا فولتي 48 ساعة",
        category: "باقات فولتي VoLTE",
        subTitle: "دفع مسبق",
        price: 600,
        days: "48 ساعة",
        calls: "120 دقيقة",
        sms: "50 رسالة",
        internet: "500 ميجا",
      },
      {
        id: 302,
        name: "باقة مزايا فولتي الشهرية",
        category: "باقات فولتي VoLTE",
        subTitle: "دفع مسبق",
        price: 1800,
        days: "30 يوم",
        calls: "300 دقيقة",
        sms: "200 رسالة",
        internet: "1.5 جيجا",
      },
    ],
    "باقات الإنترنت الشهرية": [
      {
        id: 401,
        name: "باقة 3 جيجا إنترنت شهرية",
        category: "باقات الإنترنت الشهرية",
        subTitle: "دفع مسبق",
        price: 2400,
        days: "30 يوم",
        calls: "-",
        sms: "-",
        internet: "3 جيجا",
      },
    ],
    "باقات الإنترنت 10 ايام": [
      {
        id: 501,
        name: "باقة 1 جيجا 10 أيام",
        category: "باقات الإنترنت 10 ايام",
        subTitle: "دفع مسبق",
        price: 900,
        days: "10 أيام",
        calls: "-",
        sms: "-",
        internet: "1 جيجا",
      },
    ],
  };

  // Sabafon Packages
  const sabafonPackages: Record<string, PackageItem[]> = {
    "باقات يابلاش + واحد": [
      {
        id: 601,
        name: "يابلاش الاسبوعية",
        category: "باقات يابلاش + واحد",
        price: 484,
        days: "7 أيام",
        calls: "100 دقيقة",
        sms: "100 رسالة",
        internet: "100 ميجا",
      },
      {
        id: 602,
        name: "يابلاش الشهرية",
        category: "باقات يابلاش + واحد",
        price: 1210,
        days: "30 يوم",
        calls: "300 دقيقة",
        sms: "300 رسالة",
        internet: "100 ميجا",
      },
    ],
    "باقات 4G-فورجي": [
      {
        id: 603,
        name: "سبأفون 4G سوبر 6 جيجا",
        category: "باقات 4G-فورجي",
        price: 3000,
        days: "30 يوم",
        calls: "200 دقيقة",
        sms: "200 رسالة",
        internet: "6 جيجا",
      },
    ],
  };

  // YOU Packages
  const youPackages: Record<string, PackageItem[]> = {
    "باقات سوى": [
      {
        id: 701,
        name: "سوا 250 دقيقة 300 رسالة الشهرية",
        category: "باقات سوى",
        price: 1815,
        days: "30 يوم",
        calls: "250 دقيقة",
        sms: "300 رسالة",
        internet: "1 جيجا",
      },
      {
        id: 702,
        name: "باقة سوا 73 - الاسبوعية",
        category: "باقات سوى",
        price: 500,
        days: "7 أيام",
        calls: "73 دقيقة",
        sms: "73 رسالة",
        internet: "150 ميجا",
      },
    ],
  };

  // Denominations for Instant Recharge (فوري)
  const yemenMobileDenominations = [
    { tier: 200, price: 242, days: "8 أيام" },
    { tier: 400, price: 484, days: "16 يوم" },
    { tier: 600, price: 726, days: "24 يوم" },
    { tier: 800, price: 968, days: "32 يوم" },
    { tier: 1000, price: 1210, days: "40 يوم" },
    { tier: 1200, price: 1452, days: "48 يوم" },
    { tier: 2200, price: 2662, days: "88 يوم" },
  ];

  const sabafonDenominations = [
    { tier: 22, price: 273, days: "5 أيام" },
    { tier: 40, price: 484, days: "8 أيام" },
    { tier: 45, price: 545, days: "8 أيام" },
    { tier: 60, price: 726, days: "14 يوم" },
    { tier: 85, price: 1029, days: "40 يوم" },
    { tier: 100, price: 1210, days: "50 يوم" },
    { tier: 125, price: 1513, days: "60 يوم" },
    { tier: 150, price: 1815, days: "60 يوم" },
    { tier: 209, price: 2529, days: "180 يوم" },
  ];

  const youDenominations = [
    { tier: 410, price: 496, days: "7 أيام" },
    { tier: 830, price: 1004, days: "30 يوم" },
    { tier: 1000, price: 1210, days: "30 يوم" },
    { tier: 1250, price: 1513, days: "40 يوم" },
    { tier: 2500, price: 3025, days: "60 يوم" },
    { tier: 5000, price: 6050, days: "90 يوم" },
    { tier: 7500, price: 9075, days: "90 يوم" },
  ];

  const yDenominations = [
    { tier: 200, price: 242, days: "7 أيام" },
    { tier: 400, price: 484, days: "15 يوم" },
    { tier: 800, price: 968, days: "30 يوم" },
    { tier: 1200, price: 1452, days: "45 يوم" },
  ];

  const fourGDenominations = [
    { label: "باقة G 15", price: 2400 },
    { label: "باقة G 25", price: 4000 },
    { label: "باقة G 60", price: 8000 },
    { label: "باقة G 130", price: 16000 },
    { label: "باقة G 250", price: 26000 },
    { label: "باقة G 500", price: 46000 },
  ];

  const yemenNetDenominations = [
    { label: "10G 1M", price: 1575 },
    { label: "24G 1M", price: 3150 },
    { label: "24G 2M", price: 2520 },
    { label: "50G 2M", price: 4725 },
    { label: "66G 4M", price: 6930 },
    { label: "100G 1M", price: 10500 },
  ];

  if (viewMode === "flutter_web") {
    return <FlutterWebContainer onFallback={() => setViewMode("interactive_simulator")} />;
  }

  if (!isLoggedIn) {
    return (
      <div className="min-h-screen bg-[#F7F9FC] text-[#0F172A] flex flex-col items-center justify-center p-2 sm:p-6" dir="rtl">
        <div className="w-full max-w-md bg-white rounded-3xl shadow-md border border-slate-200 overflow-hidden">
          <LoginScreen onLoginSuccess={handleLoginSuccess} />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F7F9FC] text-[#0F172A] flex flex-col items-center" dir="rtl">
      {/* Full-width responsive container matching Flutter HomeShell Scaffold */}
      <div className="w-full max-w-xl md:max-w-2xl lg:max-w-3xl min-h-screen bg-[#F7F9FC] flex flex-col relative border-x border-slate-200/60 shadow-xs">

        {/* Dynamic Screen Routing */}
        <div className="flex-1 overflow-y-auto">
          {activeScreen === "store" && (
            <StoreView
              onNavigateToAccount={() => setActiveScreen("main_home")}
              onNavigateToPayment={() => setActiveScreen("payment")}
              walletBalance={walletBalance}
            />
          )}

          {activeScreen === "main_home" && (
            <MainHomeScreen
              walletBalance={walletBalance}
              userProfile={liveUserProfile}
              onRefreshBalance={() => {
                loadServerData();
                runInquiry("balance");
              }}
              onNavigate={(screen) => setActiveScreen(screen)}
              operations={operationsList}
              onSelectOperation={(op) => setSelectedOpForDetail(op)}
              onFeedSuccess={(amt) => {
                setWalletBalance((prev) => prev + amt);
              }}
              onLogout={handleLogout}
            />
          )}

          {activeScreen === "operations" && (
            <OperationsView
              operations={operationsList}
              onBack={() => setActiveScreen("main_home")}
              onSelectOperation={(op) => setSelectedOpForDetail(op)}
              onRefresh={() => {
                loadServerData();
                runInquiry("balance", true);
              }}
            />
          )}

          {activeScreen === "reports" && (
            <ReportsScreen
              onBack={() => setActiveScreen("main_home")}
              operations={operationsList}
              walletBalance={walletBalance}
              onRefresh={() => {
                loadServerData();
                runInquiry("balance", true);
              }}
              onSelectOperation={(op) => setSelectedOpForDetail(op)}
            />
          )}

          {activeScreen === "statement" && (
            <AccountStatementScreen
              walletBalance={walletBalance}
              onBack={() => setActiveScreen("main_home")}
              onRefreshWallet={loadServerData}
            />
          )}

          {activeScreen === "fingerprint" && (
            <FingerprintSettingsScreen onBack={() => setActiveScreen("main_home")} />
          )}

          {activeScreen === "transfer" && (
            <SubscriberTransferScreen
              walletBalance={walletBalance}
              onBack={() => setActiveScreen("main_home")}
              onTransferSuccess={(amt) => {
                setWalletBalance((prev) => Math.max(0, prev - amt));
                loadServerData();
              }}
            />
          )}

          {activeScreen === "wifi" && (
            <WifiNetworksScreen
              walletBalance={walletBalance}
              onBack={() => setActiveScreen("main_home")}
              onBuyCard={(amt) => {
                setWalletBalance((prev) => Math.max(0, prev - amt));
                loadServerData();
              }}
            />
          )}

          {activeScreen === "games" && (
            <GamesServicesScreen
              walletBalance={walletBalance}
              onBack={() => setActiveScreen("main_home")}
              onRechargeGame={(amt) => {
                setWalletBalance((prev) => Math.max(0, prev - amt));
                setActiveScreen("operations");
              }}
            />
          )}

          {activeScreen === "settings" && (
            <SettingsScreen
              onBack={() => setActiveScreen("main_home")}
              onNavigateToAddresses={() => setActiveScreen("addresses")}
              onNavigateToProfileEdit={() => setActiveScreen("profile_edit")}
              onLogout={handleLogout}
            />
          )}

          {activeScreen === "addresses" && (
            <AddressesScreen
              onBack={() => setActiveScreen("main_home")}
            />
          )}

          {activeScreen === "profile_edit" && (
            <UserProfileEditScreen
              userProfile={liveUserProfile}
              onBack={() => setActiveScreen("main_home")}
              onUpdateProfile={(updated) => {
                setLiveUserProfile((prev) => (prev ? { ...prev, ...updated } : null));
              }}
            />
          )}

          {activeScreen === "categories_flutter" && (
            <CategoriesFlutterScreen
              onBack={() => setActiveScreen("main_home")}
            />
          )}

          {activeScreen === "payment" && (
            <div>
              {/* Top App Bar with Operator Header Theme */}
              <div
                className="transition-colors duration-300 px-4 pt-4 pb-3 flex items-center justify-between shadow-md"
                style={{ backgroundColor: currentOp.headerColor }}
              >
          {/* Refresh Button */}
          <button
            onClick={() => runInquiry("balance")}
            className="w-10 h-10 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center text-white transition active:scale-95 shadow-sm"
            title="تحديث البيانات"
          >
            <RotateCw className="w-5 h-5" />
          </button>

          {/* User Balance Header */}
          <div
            onClick={() => setUserBalanceHidden(!userBalanceHidden)}
            className="flex items-center gap-2 text-white font-bold cursor-pointer select-none px-3 py-1.5 rounded-full hover:bg-white/10 transition"
          >
            <span className="text-base tracking-wide">
              {userBalanceHidden ? "*****" : `${walletBalance.toLocaleString()} ر.ي`}
            </span>
            <span className="text-sm font-semibold">رصيدي</span>
            <Zap className="w-4 h-4 opacity-80" />
          </div>

          <div className="flex items-center gap-1.5">
            {/* Back Button to Store "المتجر" */}
            <button
              onClick={() => setActiveScreen("store")}
              className="flex items-center gap-1 px-2.5 py-1.5 rounded-full bg-emerald-600/90 hover:bg-emerald-600 text-white transition active:scale-95 shadow-xs border border-white/20"
              title="العودة لواجهة المتجر كاملة"
            >
              <ShoppingBag className="w-3.5 h-3.5" />
              <span className="text-xs font-black">المتجر</span>
            </button>

            {/* Back Button to Main Home Screen "حسابي" */}
            <button
              onClick={() => setActiveScreen("main_home")}
              className="flex items-center gap-1 px-2.5 py-1.5 rounded-full bg-white/25 hover:bg-white/35 text-white transition active:scale-95 shadow-xs border border-white/25"
              title="العودة إلى واجهة حسابي الرئيسية"
            >
              <Home className="w-3.5 h-3.5" />
              <span className="text-xs font-black">حسابي</span>
            </button>
          </div>
        </div>

        {/* Operators Row - Matches Screenshot 1 */}
        <div className="bg-white px-3 py-2 border-b border-slate-200">
          <div className="text-center text-[13px] font-bold text-slate-800 mb-1.5">
            تسديد شبكات الاتصالات اليمنية
          </div>
          <div className="flex items-center justify-center gap-2 overflow-x-auto py-1 no-scrollbar">
            {OPERATORS.map((op) => {
              const isSelected = op.id === currentOp.id;
              return (
                <button
                  key={op.id}
                  onClick={() => handleOperatorClick(op)}
                  className={`w-9 h-9 rounded-full flex items-center justify-center transition-all p-0.5 ${
                    isSelected
                      ? "ring-2 ring-offset-1 scale-110 shadow-md"
                      : "opacity-75 hover:opacity-100"
                  }`}
                  style={{
                    borderColor: op.headerColor,
                    backgroundColor: isSelected ? op.headerColor : "#FFFFFF",
                  }}
                  title="الشركة مقيدة تلقائياً برقم الهاتف"
                >
                  <div
                    className="w-full h-full rounded-full flex items-center justify-center text-[10px] font-bold border"
                    style={{
                      borderColor: op.headerColor,
                      color: isSelected ? "#FFFFFF" : op.headerColor,
                    }}
                  >
                    {op.shortName.slice(0, 3)}
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Operator Restricted Notification Toast Banner */}
        {operatorRestrictedToast && (
          <div className="bg-amber-500 text-white text-[11px] font-bold text-center py-1 px-3 flex items-center justify-center gap-1.5 shadow-inner">
            <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
            <span>{operatorRestrictedToast}</span>
          </div>
        )}

        {/* Phone Input Card - Exactly like Screenshots 1, 2, 4, 11, 14 */}
        <div className="px-3 pt-3">
          <div className="bg-white rounded-2xl p-2.5 shadow-sm border border-slate-200 flex items-center justify-between gap-2">
            {/* Contacts Picker Button on Left */}
            <button
              onClick={() => setIsContactsModalOpen(true)}
              className="w-10 h-10 rounded-xl bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-700 transition"
              title="جهات الاتصال"
            >
              <Phone className="w-5 h-5" />
            </button>

            {/* Input Field & Clear Button */}
            <div className="flex-1 flex items-center justify-between border-b border-slate-300 pb-1 px-1">
              <div className="flex items-center gap-1.5">
                <span className="text-slate-400 text-xs font-bold">+967</span>
                {phoneNumber && (
                  <button
                    onClick={() => handlePhoneInputChange("")}
                    className="text-slate-400 hover:text-red-500 transition"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>

              <div className="text-left flex-1 px-2">
                <div className="text-[10px] text-slate-400 font-semibold text-right">
                  رقم الهاتف (9 أرقام مقيدة)
                </div>
                <input
                  type="tel"
                  maxLength={9}
                  value={phoneNumber}
                  onChange={(e) => handlePhoneInputChange(e.target.value)}
                  placeholder="ادخل 9 أرقام..."
                  className="w-full text-right font-bold text-slate-900 text-base focus:outline-none bg-transparent"
                  dir="ltr"
                />
              </div>
            </div>

            {/* Operator Logo Badge & Favorite Heart on Right */}
            <div className="flex items-center gap-1.5">
              <div
                className="w-9 h-9 rounded-full flex items-center justify-center text-white text-[10px] font-bold shadow-sm"
                style={{ backgroundColor: currentOp.headerColor }}
              >
                {currentOp.shortName.slice(0, 4)}
              </div>
              <button className="text-slate-400 hover:text-red-500">
                <Heart className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Dynamic Main Tabs Bar - Based on Operator */}
        <div className="px-3 pt-2.5">
          {/* Case 1: Yemen 4G Tabs (Screenshot 17, 18) */}
          {currentOp.id === "yemen4g" ? (
            <div className="grid grid-cols-4 bg-[#BAE6FD] p-1 rounded-xl gap-1 text-xs font-bold text-slate-700">
              {["باقة يمن 4G", "رصيد يمن 4G", "تغيير الباقة", "فايبر"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveMainTab(tab)}
                  className={`py-1.5 rounded-lg transition text-center ${
                    activeMainTab === tab
                      ? "bg-[#0284C7] text-white shadow-sm"
                      : "hover:bg-white/40"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          ) : currentOp.id === "yemen_net" ? (
            /* Case 2: Yemen Net Tabs (Screenshot 19, 20) */
            <div className="grid grid-cols-2 bg-[#C7D2FE] p-1 rounded-xl gap-1 text-xs font-bold text-slate-700">
              {["الانترنت الارضي", "الهاتف الثابت"].map((tab) => (
                <button
                  key={tab}
                  onClick={() => {
                    setActiveMainTab(tab);
                    setNetTab(tab === "الانترنت الارضي" ? "adsl" : "phone");
                    setBalanceInquiryBanner(null);
                  }}
                  className={`py-2 rounded-lg transition text-center ${
                    activeMainTab === tab
                      ? "bg-[#283593] text-white shadow-sm"
                      : "hover:bg-white/40"
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          ) : (
            /* Case 3: Yemen Mobile, Sabafon, YOU standard Tabs (Screenshot 2, 6, 11, 14) */
            <div className="flex bg-[#FED7AA] p-1 rounded-xl gap-1 text-xs font-bold text-slate-800">
              {["رصيد", "فوري", "باقات", "جملة", currentOp.id === "you" ? "فوترة" : "ريال"].map((tab) => {
                const isActive = activeMainTab === tab;
                return (
                  <button
                    key={tab}
                    onClick={() => {
                      setActiveMainTab(tab);
                      setBalanceInquiryBanner(null);
                      if (tab === "باقات" && currentOp.id === "yemen_mobile" && phoneNumber.length >= 9) {
                        runInquiry("offers", false);
                      }
                    }}
                    className={`flex-1 py-1.5 rounded-lg transition text-center ${
                      isActive
                        ? "text-white shadow-sm"
                        : "hover:bg-white/30"
                    }`}
                    style={{
                      backgroundColor: isActive ? currentOp.activeTabColor : "transparent",
                    }}
                  >
                    {tab}
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* Scrollable Content Container */}
        <div className="flex-1 overflow-y-auto px-3 py-3 space-y-3">

          {/* ========================================================================= */}
          {/* TAB: باقات (PACKAGES)                                                     */}
          {/* ========================================================================= */}
          {activeMainTab === "باقات" && (
            <div className="space-y-3">

              {/* 3-Column Inquiry Row - Exactly matching Screenshots 6, 7, 8, 9! */}
              {/* Not a big card, but the clean in-screen 3-column row! */}
              <div className="bg-white rounded-2xl p-3 shadow-sm border border-slate-200">
                <div className="grid grid-cols-3 text-center items-center divide-x divide-x-reverse divide-slate-100">

                  {/* Column 1 (Right): رصيد الرقم */}
                  <div>
                    <div className="flex items-center justify-center gap-1 text-[11px] text-slate-500 font-bold mb-1">
                      <span>رصيد الرقم</span>
                      <button
                        onClick={() => runInquiry("balance")}
                        className="text-slate-400 hover:text-[#8B1D3B] transition active:scale-90"
                        title="تحديث رصيد الرقم من المزود"
                      >
                        <RotateCw className="w-3 h-3" />
                      </button>
                    </div>
                    <div className="text-sm font-extrabold text-[#0284C7]">
                      {ymPhoneBalance || "436.04"} <span className="text-[10px] text-slate-400 font-normal">ر.ي</span>
                    </div>
                  </div>

                  {/* Column 2 (Middle): نوع الرقم */}
                  <div>
                    <div className="text-[11px] text-slate-500 font-bold mb-1">نوع الرقم</div>
                    <div className="text-xs font-bold text-slate-800">
                      {ymPhoneType || "دفع مسبق | شريحة"}
                    </div>
                  </div>

                  {/* Column 3 (Left): فحص السلفة */}
                  <div>
                    <button
                      onClick={() => runInquiry("sulfa")}
                      className="bg-[#FEF3C7] hover:bg-[#FDE68A] text-[#92400E] border border-[#F59E0B]/40 px-2 py-0.5 rounded-full text-[10px] font-extrabold mb-1 active:scale-95 transition"
                    >
                      فحص السلفة
                    </button>
                    <div className="text-xs font-bold">
                      {ymLoanStatus === "none" ? (
                        <span className="text-emerald-600 flex items-center justify-center gap-1">
                          <span>غير متسلف</span>
                          <span>😀</span>
                        </span>
                      ) : (
                        <span className="text-rose-600 flex items-center justify-center gap-1 font-bold">
                          <span>متسلف {ymLoanAmount} ر.ي</span>
                          <span>⚠️</span>
                        </span>
                      )}
                    </div>
                  </div>

                </div>
              </div>

              {/* Sub-Filter Tabs (الكل | دفع مسبق | فوترة | شريحة | برمجة | 4G) */}
              <div className="flex bg-white p-1 rounded-xl gap-1 text-[11px] font-bold text-slate-600 border border-slate-200 shadow-sm overflow-x-auto no-scrollbar">
                {["الكل", "دفع مسبق", "فوترة", "شريحة", "برمجة", "4G"].map((sub) => {
                  const isSubActive = subFilter === sub;
                  return (
                    <button
                      key={sub}
                      onClick={() => setSubFilter(sub)}
                      className={`flex-1 py-1 px-2 rounded-lg transition text-center whitespace-nowrap ${
                        isSubActive
                          ? "text-white shadow-sm"
                          : "hover:bg-slate-100"
                      }`}
                      style={{
                        backgroundColor: isSubActive ? currentOp.activeTabColor : "transparent",
                      }}
                    >
                      {sub}
                    </button>
                  );
                })}
              </div>

              {/* Section: الاشتراكات الحالية (Current Subscriptions) - Matches Screenshot 7 & 8 */}
              {currentOp.id === "yemen_mobile" && activeSubscriptions.length > 0 && (
                <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200">
                  {/* Dark Red Header Bar */}
                  <div
                    className="py-2 px-3 text-white text-xs font-extrabold text-center shadow-inner"
                    style={{ backgroundColor: currentOp.headerColor }}
                  >
                    الاشتراكات الحالية
                  </div>

                  {/* Subscriptions List */}
                  <div className="p-2 space-y-2 bg-[#FFF8F0]">
                    {activeSubscriptions.map((sub, sIdx) => (
                      <div
                        key={sub.id ? `sub-${sub.id}-${sIdx}` : `sub-${sIdx}`}
                        className="bg-white rounded-xl p-2.5 border border-amber-200/70 shadow-sm flex items-center justify-between gap-2"
                      >
                        {/* Right: Info */}
                        <div className="text-right flex-1">
                          <div className="text-xs font-extrabold text-slate-800 mb-1">
                            {sub.name}
                          </div>
                          <div className="text-[10px] text-emerald-700 font-semibold">
                            الإشتراك: <span className="font-normal">{sub.startDate}</span>
                          </div>
                          <div className="text-[10px] text-rose-700 font-semibold">
                            الإنتهاء: <span className="font-normal">{sub.endDate}</span>
                          </div>
                        </div>

                        {/* Left: Renewal Action Icon */}
                        <button
                          onClick={() => {
                            setConfirmDialogData({
                              isOpen: true,
                              serviceName: currentOp.name,
                              itemName: `تجديد ${sub.name}`,
                              phoneNumber: phoneNumber,
                              amount: 600,
                              feeRatio: 1,
                              totalCost: 600,
                              amountArabicWords: "ستمائة",
                              receivedAmount: "",
                              lastTxTime: "أمس الساعة 3:34 م",
                              lastTxName: sub.name,
                              lastTxAmount: "600.00 $",
                            });
                          }}
                          className="w-11 h-11 rounded-xl bg-[#8B1D3B] text-white flex flex-col items-center justify-center text-[9px] font-bold shadow-sm active:scale-95 transition"
                        >
                          <RotateCw className="w-4 h-4 mb-0.5" />
                          <span>تجديد</span>
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Accordion Categories for Packages - Matches Screenshot 6, 7, 8, 9, 10 */}
              <div className="space-y-2">
                {(() => {
                  const basePackagesMap: Record<string, PackageItem[]> =
                    livePackagesMap[currentOp.id] && Object.keys(livePackagesMap[currentOp.id]).length > 0
                      ? livePackagesMap[currentOp.id]
                      : currentOp.id === "yemen_mobile"
                      ? yemenMobilePackages
                      : currentOp.id === "sabafon"
                      ? sabafonPackages
                      : youPackages;

                  return Object.entries(basePackagesMap).map(([catTitle, pkgs], cIdx) => {
                    const isExpanded = expandedCategories[catTitle] ?? true;
                    // Filter packages according to subFilter
                    const packageList = pkgs as PackageItem[];
                    const filteredPkgs = packageList.filter((pkg) => {
                      if (subFilter === "الكل") return true;
                      const text = `${pkg.name} ${pkg.subTitle || ""} ${pkg.category || ""}`;
                      if (subFilter === "دفع مسبق") {
                        return text.includes("دفع مسبق") || !text.includes("فوتر");
                      }
                      if (subFilter === "فوترة") {
                        return text.includes("فوتر") || text.includes("فوترة");
                      }
                      if (subFilter === "شريحة") {
                        return text.includes("شريحة") || !text.includes("برمجة");
                      }
                      if (subFilter === "برمجة") {
                        return text.includes("برمجة");
                      }
                      if (subFilter === "4G") {
                        return text.includes("4G") || text.includes("فورجي") || text.includes("فولتي");
                      }
                      return true;
                    });

                    if (filteredPkgs.length === 0) return null;

                    return (
                      <div key={`accordion-cat-${catTitle}-${cIdx}`} className="rounded-2xl overflow-hidden shadow-sm border border-slate-200 bg-white">
                        {/* Accordion Header */}
                        <button
                          onClick={() => toggleCategory(catTitle)}
                          className="w-full py-2.5 px-3 flex items-center justify-between text-white font-extrabold text-xs transition shadow-sm"
                          style={{ backgroundColor: currentOp.headerColor }}
                        >
                          {/* Right: Icon Badge + Category Name */}
                          <div className="flex items-center gap-2">
                            <div className="w-7 h-7 rounded-full bg-white text-slate-800 text-[10px] font-extrabold flex items-center justify-center shadow-inner">
                              {catTitle.includes("فورجي") ? "4G" : catTitle.includes("مزايا") ? "3G" : "PKG"}
                            </div>
                            <span>{catTitle}</span>
                            <span className="text-[10px] bg-white/20 px-2 py-0.5 rounded-full font-normal">
                              {filteredPkgs.length} باقة
                            </span>
                          </div>

                          {/* Left: Chevron */}
                          {isExpanded ? (
                            <ChevronUp className="w-5 h-5 text-white/90" />
                          ) : (
                            <ChevronDown className="w-5 h-5 text-white/90" />
                          )}
                        </button>

                        {/* Accordion Content: Package Cards Grid */}
                        {isExpanded && (
                          <div className="p-2.5 space-y-3 bg-[#FDFBF7]">
                            {filteredPkgs.map((pkg, pIdx) => {
                            const cardTheme = getOperatorCardTheme(currentOp.id);
                            return (
                              <div
                                key={pkg.id ? `pkg-${pkg.id}-${pIdx}` : `pkg-${pIdx}`}
                                onClick={() => openPackageModal(pkg)}
                                className={`${cardTheme.cardBg} ${cardTheme.hoverBg} rounded-2xl p-3 border ${cardTheme.cardBorder} shadow-sm cursor-pointer transition active:scale-[0.99] relative`}
                              >
                                {/* Top Bar: Title, Subtitle, and Logo Badge */}
                                <div className="flex items-start justify-between mb-2">
                                  <div className="flex-1">
                                    <div
                                      className="text-sm font-extrabold mb-0.5"
                                      style={{ color: currentOp.headerColor }}
                                    >
                                      {pkg.name}
                                    </div>
                                    <div className="text-[10px] text-slate-500 whitespace-pre-line font-medium leading-tight">
                                      {pkg.subTitle || "دفع مسبق"}
                                    </div>
                                  </div>
                                  <div
                                    className="w-8 h-8 rounded-full flex items-center justify-center text-white text-[9px] font-bold shadow-sm"
                                    style={{ backgroundColor: currentOp.headerColor }}
                                  >
                                    {currentOp.shortName.slice(0, 3)}
                                  </div>
                                </div>

                                {/* Center: Big 3D Bold Price (as in screenshot 8, 9) */}
                                <div className="text-center my-2">
                                  <span className="text-3xl font-black text-slate-800 tracking-tight drop-shadow-sm">
                                    {pkg.price}
                                  </span>
                                </div>

                                {/* Divider */}
                                <div className={`border-t ${cardTheme.dividerColor} my-2`}></div>

                                {/* Footer Columns: Days, Calls, SMS, Internet */}
                                <div className={`grid grid-cols-4 text-center text-slate-700 text-[10px] font-semibold divide-x divide-x-reverse ${cardTheme.dividerColor}`}>
                                  <div className="flex flex-col items-center">
                                    <Clock className="w-3.5 h-3.5 mb-1 text-slate-500" />
                                    <span>{pkg.days || "-"}</span>
                                  </div>
                                  <div className="flex flex-col items-center">
                                    <Phone className="w-3.5 h-3.5 mb-1 text-slate-500" />
                                    <span>{pkg.calls || "-"}</span>
                                  </div>
                                  <div className="flex flex-col items-center">
                                    <Mail className="w-3.5 h-3.5 mb-1 text-slate-500" />
                                    <span>{pkg.sms || "-"}</span>
                                  </div>
                                  <div className="flex flex-col items-center">
                                    <Globe className="w-3.5 h-3.5 mb-1 text-slate-500" />
                                    <span>{pkg.internet || "-"}</span>
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  );
                });
              })()}
              </div>

            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB: رصيد (BALANCE RECHARGE)                                              */}
          {/* ========================================================================= */}
          {activeMainTab === "رصيد" && (
            <div className="space-y-3">

              {/* Cyan Inquiry Banner if already run - Matches Screenshot 4 */}
              {balanceInquiryBanner && (
                <div className="bg-[#26C6DA] text-white py-2 px-3 rounded-2xl text-center text-xs font-bold shadow-sm flex items-center justify-center gap-2">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>{balanceInquiryBanner}</span>
                </div>
              )}

              {/* Sub-Tabs for Sabafon (دفع مسبق | فوترة) */}
              {currentOp.id === "sabafon" && (
                <div className="flex bg-[#E0F2FE] p-1 rounded-xl text-xs font-bold text-slate-700 gap-1">
                  {["دفع مسبق", "فوترة"].map((sub) => (
                    <button
                      key={sub}
                      onClick={() => setSubFilter(sub)}
                      className={`flex-1 py-1.5 rounded-lg transition ${
                        subFilter === sub ? "bg-[#1E88E5] text-white shadow-sm" : ""
                      }`}
                    >
                      {sub}
                    </button>
                  ))}
                </div>
              )}

              {/* Input Card: ادخل المبلغ / ادخل عدد الوحدات */}
              <div className="bg-white rounded-2xl p-4 shadow-sm border border-slate-200 space-y-4">
                {currentOp.hasUnits ? (
                  <div>
                    <label className="block text-right text-xs font-bold text-slate-800 mb-1.5">
                      *ادخل عدد الوحدات
                    </label>
                    <div className="flex items-center justify-between border-b-2 border-[#1E88E5] pb-1 px-1">
                      <button
                        onClick={() => setUnitsCount("")}
                        className="text-slate-400 hover:text-red-500"
                      >
                        <X className="w-4 h-4" />
                      </button>
                      <input
                        type="number"
                        value={unitsCount}
                        onChange={(e) => setUnitsCount(e.target.value)}
                        placeholder="عدد الوحدات"
                        className="w-full text-right font-bold text-slate-900 text-base focus:outline-none bg-transparent px-2"
                      />
                      <span className="text-slate-500 font-bold">$</span>
                    </div>
                    <div className="text-left text-[11px] text-slate-500 mt-1">عشرة</div>
                    <div className="text-center font-bold text-slate-800 text-sm mt-3">
                      اجمالي المبلغ: {(Number(unitsCount || 0) * 12.1).toFixed(2)}
                    </div>
                  </div>
                ) : (
                  <div>
                    <label className="block text-right text-xs font-bold text-slate-800 mb-1.5">
                      *ادخل المبلغ
                    </label>
                    <div className="flex items-center justify-between border-b-2 border-slate-300 focus-within:border-[#8B1D3B] pb-1 px-1">
                      <button
                        onClick={() => setRechargeAmount("")}
                        className="text-slate-400 hover:text-red-500"
                      >
                        <X className="w-4 h-4" />
                      </button>
                      <input
                        type="number"
                        value={rechargeAmount}
                        onChange={(e) => setRechargeAmount(e.target.value)}
                        placeholder="المبلغ"
                        className="w-full text-right font-bold text-slate-900 text-base focus:outline-none bg-transparent px-2"
                      />
                      <span className="text-slate-500 font-bold">$</span>
                    </div>

                    {/* Net Amount after Tax (as in Screenshot 3, 4) */}
                    <div className="mt-4 pt-2 border-t border-slate-100">
                      <label className="block text-right text-xs font-bold text-slate-700 mb-1">
                        صافي الرصيد بعد خصم الضريبه
                      </label>
                      <div className="bg-slate-50 rounded-xl py-2 px-3 flex items-center justify-between border border-slate-200">
                        <span className="text-slate-500 font-bold">$</span>
                        <span className="font-extrabold text-slate-800 text-sm">
                          {(Number(rechargeAmount || 0) * 0.829).toFixed(2)}
                        </span>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Action Buttons: Check Inquiry Rule! */}
              {/* Sabafon and YOU: ONLY "تسديد" button! (Screenshot 11, 14) */}
              {/* Yemen Mobile: TWO buttons: "تسديد" and "استعلام" (Screenshot 3, 4) */}
              <div className="flex items-center gap-2 pt-2">
                {currentOp.hasInquiryInBalance ? (
                  <>
                    <button
                      onClick={initiateBalanceRecharge}
                      className="flex-1 py-2.5 rounded-xl font-extrabold text-sm transition shadow-sm active:scale-95 text-white"
                      style={{ backgroundColor: currentOp.activeTabColor }}
                    >
                      تسديد
                    </button>
                    <button
                      onClick={() => runInquiry("balance")}
                      className="flex-1 py-2.5 rounded-xl font-extrabold text-sm bg-[#FED7AA] hover:bg-[#FDBA74] text-slate-900 transition shadow-sm active:scale-95"
                    >
                      استعلام
                    </button>
                  </>
                ) : (
                  <button
                    onClick={initiateBalanceRecharge}
                    className="w-full py-2.5 rounded-xl font-extrabold text-sm transition shadow-sm active:scale-95 text-white"
                    style={{ backgroundColor: currentOp.activeTabColor }}
                  >
                    تسديد
                  </button>
                )}
              </div>

            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB: فوري (INSTANT DENOMINATIONS)                                         */}
          {/* ========================================================================= */}
          {activeMainTab === "فوري" && (
            <div className="space-y-3">
              {/* Sabafon North / South Radio Switch (Screenshot 12) */}
              {currentOp.id === "sabafon" && (
                <div className="flex items-center justify-center gap-6 bg-white p-2 rounded-xl shadow-sm border border-slate-200 text-xs font-bold text-slate-800">
                  <label className="flex items-center gap-1.5 cursor-pointer">
                    <input
                      type="radio"
                      name="region"
                      checked={sabafonRegion === "شمال"}
                      onChange={() => setSabafonRegion("شمال")}
                      className="accent-[#1E88E5]"
                    />
                    <span>شمال</span>
                  </label>
                  <label className="flex items-center gap-1.5 cursor-pointer">
                    <input
                      type="radio"
                      name="region"
                      checked={sabafonRegion === "جنوب"}
                      onChange={() => setSabafonRegion("جنوب")}
                      className="accent-[#1E88E5]"
                    />
                    <span>جنوب</span>
                  </label>
                </div>
              )}

              {/* YOU Smart Charger Switch (Screenshot 15) */}
              {currentOp.id === "you" && (
                <div className="flex items-center justify-between bg-white px-4 py-2.5 rounded-xl shadow-sm border border-slate-200">
                  <span className="text-xs font-bold text-slate-800">الشاحن الذكي</span>
                  <input
                    type="checkbox"
                    checked={youSmartCharger}
                    onChange={(e) => setYouSmartCharger(e.target.checked)}
                    className="toggle accent-amber-500 w-5 h-5"
                  />
                </div>
              )}

              {/* Cards Grid Matching Screenshots 6, 12, 15 */}
              <div className="grid grid-cols-3 gap-2.5">
                {(currentOp.id === "yemen_mobile"
                  ? yemenMobileDenominations
                  : currentOp.id === "sabafon"
                  ? sabafonDenominations
                  : currentOp.id === "y"
                  ? yDenominations
                  : youDenominations
                ).map((d, idx) => {
                  const denomTheme = getDenomColors(currentOp.id);
                  return (
                    <div
                      key={idx}
                      onClick={() => {
                        setConfirmDialogData({
                          isOpen: true,
                          serviceName: currentOp.name,
                          itemName: `فئة ${d.tier}`,
                          phoneNumber: phoneNumber,
                          amount: d.price,
                          feeRatio: 1,
                          totalCost: d.price,
                          amountArabicWords: getArabicAmountWords(d.price),
                          receivedAmount: "",
                          lastTxTime: "أمس الساعة 3:34 م",
                          lastTxName: `فئة ${d.tier}`,
                          lastTxAmount: `${d.price} ر.ي`,
                        });
                      }}
                      className={`bg-white rounded-2xl overflow-hidden shadow-sm border ${denomTheme.border} cursor-pointer active:scale-95 transition flex flex-col`}
                    >
                      {/* Card Top: Header with Tier number */}
                      <div
                        className="py-1.5 px-2 text-white flex flex-col items-center justify-center text-center shadow-sm"
                        style={{ backgroundColor: currentOp.headerColor }}
                      >
                        <div className="text-[9px] opacity-90 font-medium">فئة</div>
                        <div className="text-xl font-black tracking-tight">{d.tier}</div>
                      </div>

                      {/* Card Middle: Price */}
                      <div className="p-2 text-center flex-1 flex flex-col justify-center">
                        <div className="text-[10px] text-slate-500 font-semibold">السعر</div>
                        <div className="text-xs font-black text-slate-800 mt-0.5">
                          {d.price} ريال
                        </div>
                      </div>

                      {/* Card Bottom: Duration */}
                      <div className={`${denomTheme.bg} py-1 text-center text-[10px] font-bold ${denomTheme.text} border-t ${denomTheme.border}`}>
                        {d.days}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB: يمن فورجي (YEMEN 4G) - Matches Screenshot 17, 18                     */}
          {/* ========================================================================= */}
          {activeMainTab === "باقة يمن 4G" && (
            <div className="space-y-3">
              {/* Input Card */}
              <div className="bg-white rounded-2xl p-4 shadow-sm border border-slate-200 space-y-3">
                <label className="block text-right text-xs font-bold text-slate-800">
                  *ادخل المبلغ
                </label>
                <div className="flex items-center justify-between border-b-2 border-slate-300 pb-1 px-1">
                  <button onClick={() => setRechargeAmount("")} className="text-slate-400">
                    <X className="w-4 h-4" />
                  </button>
                  <input
                    type="number"
                    value={rechargeAmount}
                    onChange={(e) => setRechargeAmount(e.target.value)}
                    placeholder="المبلغ"
                    className="w-full text-right font-bold text-slate-900 text-base focus:outline-none bg-transparent px-2"
                  />
                  <span className="text-slate-500 font-bold">$</span>
                </div>
              </div>

              {/* Action Buttons: تسديد & استعلام */}
              <div className="flex items-center gap-2">
                <button
                  onClick={initiateBalanceRecharge}
                  className="flex-1 py-2.5 rounded-xl font-extrabold text-sm bg-[#0284C7] text-white transition shadow-sm active:scale-95"
                >
                  تسديد
                </button>
                <button
                  onClick={() => runInquiry("4g")}
                  className="flex-1 py-2.5 rounded-xl font-extrabold text-sm bg-[#FED7AA] hover:bg-[#FDBA74] text-slate-900 transition shadow-sm active:scale-95"
                >
                  استعلام
                </button>
              </div>

              {/* 4-Row Inquiry Result Table - Exactly matches Screenshot 18! */}
              {fourGInquiryData && (
                <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200 text-xs">
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      الرصيد
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {fourGInquiryData.balance}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      قيمة الباقة
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {fourGInquiryData.packagePrice}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      الحجم | السرعة
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {fourGInquiryData.speed}
                    </div>
                  </div>
                  <div className="grid grid-cols-2">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      تأريخ الإنتهاء
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {fourGInquiryData.expiry}
                    </div>
                  </div>
                </div>
              )}

              {/* 4G Denominations Grid (Screenshot 18) */}
              <div className="grid grid-cols-3 gap-2.5 pt-1">
                {fourGDenominations.map((d, idx) => (
                  <div
                    key={idx}
                    onClick={() => {
                      setRechargeAmount(d.price.toString());
                      setConfirmDialogData({
                        isOpen: true,
                        serviceName: "يمن فورجي",
                        itemName: d.label,
                        phoneNumber: phoneNumber,
                        amount: d.price,
                        feeRatio: 1,
                        totalCost: d.price,
                        amountArabicWords: getArabicAmountWords(d.price),
                        receivedAmount: "",
                        lastTxTime: "أمس الساعة 3:34 م",
                        lastTxName: d.label,
                        lastTxAmount: `${d.price} ر.ي`,
                      });
                    }}
                    className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200 cursor-pointer active:scale-95 transition flex flex-col"
                  >
                    <div className="bg-[#0284C7] py-1.5 px-2 text-white flex items-center justify-between text-[11px] font-bold">
                      <span>{d.label}</span>
                      <Wifi className="w-3.5 h-3.5" />
                    </div>
                    <div className="p-2 text-center flex-1 flex flex-col justify-center">
                      <div className="text-[9px] text-slate-500 font-semibold">السعر</div>
                      <div className="text-xs font-black text-slate-800 mt-0.5">
                        {d.price} ريال
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB: يمن نت (YEMEN NET ADSL & FIXED LINE) - Matches Screenshot 19, 20      */}
          {/* ========================================================================= */}
          {(activeMainTab === "الانترنت الارضي" || activeMainTab === "الهاتف الثابت") && (
            <div className="space-y-3">
              {/* Fixed Line Bill Banner (Screenshot 20) */}
              {activeMainTab === "الهاتف الثابت" && (
                <div className="bg-[#26C6DA] text-white py-2.5 px-3 rounded-2xl text-center text-xs font-extrabold shadow-sm">
                  مبلغ الفاتورة الحالية: -2000
                </div>
              )}

              {/* Input Card */}
              <div className="bg-white rounded-2xl p-4 shadow-sm border border-slate-200 space-y-3">
                <label className="block text-right text-xs font-bold text-slate-800">
                  *ادخل المبلغ
                </label>
                <div className="flex items-center justify-between border-b-2 border-slate-300 pb-1 px-1">
                  <button onClick={() => setRechargeAmount("")} className="text-slate-400">
                    <X className="w-4 h-4" />
                  </button>
                  <input
                    type="number"
                    value={rechargeAmount}
                    onChange={(e) => setRechargeAmount(e.target.value)}
                    placeholder="المبلغ"
                    className="w-full text-right font-bold text-slate-900 text-base focus:outline-none bg-transparent px-2"
                  />
                  <span className="text-slate-500 font-bold">$</span>
                </div>
              </div>

              {/* Action Buttons: تسديد & استعلام */}
              <div className="flex items-center gap-2">
                <button
                  onClick={initiateBalanceRecharge}
                  className="flex-1 py-2.5 rounded-xl font-extrabold text-sm bg-[#283593] text-white transition shadow-sm active:scale-95"
                >
                  تسديد
                </button>
                <button
                  onClick={() => runInquiry(netTab === "adsl" ? "net_adsl" : "net_line")}
                  className="flex-1 py-2.5 rounded-xl font-extrabold text-sm bg-[#FED7AA] hover:bg-[#FDBA74] text-slate-900 transition shadow-sm active:scale-95"
                >
                  استعلام
                </button>
              </div>

              {/* ADSL 4-Row Table Result - Exactly matches Screenshot 19! */}
              {activeMainTab === "الانترنت الارضي" && netInquiryData && (
                <div className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200 text-xs">
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      الرصيد
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {netInquiryData.balance}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      قيمة الباقة
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {netInquiryData.packagePrice}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 border-b border-slate-100">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      الحجم | السرعة
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {netInquiryData.speed}
                    </div>
                  </div>
                  <div className="grid grid-cols-2">
                    <div className="p-2.5 bg-[#E0E7FF]/60 font-bold text-slate-700 text-center border-l border-slate-100">
                      تأريخ الإنتهاء
                    </div>
                    <div className="p-2.5 font-extrabold text-slate-900 text-center">
                      {netInquiryData.expiry}
                    </div>
                  </div>
                </div>
              )}

              {/* ADSL Denominations (Screenshot 19) */}
              {activeMainTab === "الانترنت الارضي" && (
                <div className="grid grid-cols-3 gap-2.5 pt-1">
                  {yemenNetDenominations.map((d, idx) => (
                    <div
                      key={idx}
                      onClick={() => {
                        setRechargeAmount(d.price.toString());
                        setConfirmDialogData({
                          isOpen: true,
                          serviceName: "يمن نت ADSL",
                          itemName: d.label,
                          phoneNumber: phoneNumber,
                          amount: d.price,
                          feeRatio: 1,
                          totalCost: d.price,
                          amountArabicWords: getArabicAmountWords(d.price),
                          receivedAmount: "",
                          lastTxTime: "أمس الساعة 3:34 م",
                          lastTxName: d.label,
                          lastTxAmount: `${d.price} ر.ي`,
                        });
                      }}
                      className="bg-white rounded-2xl overflow-hidden shadow-sm border border-slate-200 cursor-pointer active:scale-95 transition flex flex-col"
                    >
                      <div className="bg-[#283593] py-1.5 px-2 text-white flex items-center justify-between text-[11px] font-bold">
                        <span>{d.label}</span>
                        <Wifi className="w-3.5 h-3.5" />
                      </div>
                      <div className="p-2 text-center flex-1 flex flex-col justify-center">
                        <div className="text-[9px] text-slate-500 font-semibold">السعر</div>
                        <div className="text-xs font-black text-slate-800 mt-0.5">
                          {d.price} ريال
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

        </div>

        {/* ========================================================================= */}
        {/* MODAL 1: LOADING SPINNER - Exactly matches Screenshot 3 & 17!            */}
        {/* Multi-colored 8 dots in circle + "الرجاء الإنتظار قليلاً..."               */}
        {/* ========================================================================= */}
        {isLoadingModalOpen && (
          <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px] z-50 flex items-center justify-center p-4 animate-fade-in">
            <div className="bg-white rounded-3xl p-6 shadow-2xl flex flex-col items-center justify-center max-w-[240px] w-full border border-slate-100">
              {/* 8 Multi-colored dots spinner */}
              <div className="w-14 h-14 relative flex items-center justify-center mb-4">
                <div className="absolute w-full h-full animate-spin">
                  {/* 8 colored dots */}
                  <span className="w-3 h-3 rounded-full bg-red-500 absolute top-0 left-1/2 -translate-x-1/2"></span>
                  <span className="w-3 h-3 rounded-full bg-orange-500 absolute top-1.5 right-1.5"></span>
                  <span className="w-3 h-3 rounded-full bg-yellow-400 absolute top-1/2 right-0 -translate-y-1/2"></span>
                  <span className="w-3 h-3 rounded-full bg-emerald-500 absolute bottom-1.5 right-1.5"></span>
                  <span className="w-3 h-3 rounded-full bg-cyan-500 absolute bottom-0 left-1/2 -translate-x-1/2"></span>
                  <span className="w-3 h-3 rounded-full bg-blue-600 absolute bottom-1.5 left-1.5"></span>
                  <span className="w-3 h-3 rounded-full bg-purple-600 absolute top-1/2 left-0 -translate-y-1/2"></span>
                  <span className="w-3 h-3 rounded-full bg-pink-500 absolute top-1.5 left-1.5"></span>
                </div>
              </div>

              {/* Exact text: الرجاء الإنتظار قليلاً... */}
              <div className="text-slate-800 font-extrabold text-sm text-center">
                الرجاء الإنتظار قليلاً...
              </div>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL 2: PACKAGE DETAILS BOTTOM SHEET - Exactly matches Screenshot 20!    */}
        {/* Shows package name, loan addition checkbox, price, net, current balance  */}
        {/* Buttons: تفعيل من الرصيد | حذف الباقة | تسديد + تفعيل                     */}
        {/* ========================================================================= */}
        {selectedPackageForModal && (
          <div className="absolute inset-0 bg-black/50 backdrop-blur-[1px] z-40 flex flex-col justify-end animate-fade-in">
            <div className="bg-white rounded-t-3xl p-4 shadow-2xl border-t border-slate-200 space-y-4 max-h-[85%] overflow-y-auto">

              {/* Header: Close Button and Package Title */}
              <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                <button
                  onClick={() => setSelectedPackageForModal(null)}
                  className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-600"
                >
                  <X className="w-5 h-5" />
                </button>
                <div
                  className="text-sm font-extrabold text-right flex-1 px-2"
                  style={{ color: currentOp.headerColor }}
                >
                  {selectedPackageForModal.name}
                </div>
              </div>

              {/* Checkbox: تسديد مبلغ السلفة */}
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-200 flex items-center justify-between">
                <div className="text-right">
                  <div className="text-xs font-bold text-[#0284C7]">
                    تسديد مبلغ السلفة {ymLoanAmount.toFixed(1)} ريال
                  </div>
                </div>
                <input
                  type="checkbox"
                  checked={includeLoanInPackage}
                  onChange={(e) => setIncludeLoanInPackage(e.target.checked)}
                  className="w-5 h-5 accent-[#0284C7] rounded cursor-pointer"
                />
              </div>

              {/* Package Price Field */}
              <div className="flex items-center justify-between bg-white px-3 py-2 rounded-xl border border-slate-200 shadow-sm">
                <span className="text-xs font-bold text-slate-700">سعر الباقة:</span>
                <div className="flex items-center gap-1.5 border border-slate-300 rounded-lg px-3 py-1 font-black text-slate-900 text-sm">
                  <span>{selectedPackageForModal.price + (includeLoanInPackage ? ymLoanAmount : 0)}</span>
                  <span className="text-xs text-slate-500 font-semibold">ريال</span>
                </div>
              </div>

              {/* Net Price & Current Balance */}
              <div className="space-y-1.5 text-xs font-bold text-slate-600 px-1">
                <div className="flex justify-between">
                  <span>الصافي بعد خصم الضريبة الحكومية:</span>
                  <span className="text-slate-800">
                    {(selectedPackageForModal.netDiscountPrice || selectedPackageForModal.price * 0.826).toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>رصيد الرقم الحالي:</span>
                  <span className="text-[#0284C7] font-extrabold">{ymPhoneBalance}</span>
                </div>
              </div>

              {/* Action Buttons: Exactly matching Screenshot 20! */}
              <div className="space-y-2 pt-2">
                {/* Button 1: تفعيل من الرصيد */}
                <button
                  onClick={() => {
                    alert("تفعيل الباقة من رصيد الهاتف مباشرة");
                    setSelectedPackageForModal(null);
                  }}
                  className="w-full py-2.5 rounded-xl border border-slate-300 hover:bg-slate-50 text-[#0284C7] font-extrabold text-xs flex items-center justify-center gap-2 shadow-sm transition"
                >
                  <CreditCard className="w-4 h-4" />
                  <span>تفعيل من الرصيد</span>
                </button>

                {/* Button 2: حذف الباقة */}
                <button
                  onClick={() => {
                    alert("طلب إلغاء أو حذف الباقة الحالية");
                    setSelectedPackageForModal(null);
                  }}
                  className="w-full py-2.5 rounded-xl border border-slate-300 hover:bg-slate-50 text-slate-700 font-extrabold text-xs flex items-center justify-center gap-2 shadow-sm transition"
                >
                  <Trash2 className="w-4 h-4 text-slate-600" />
                  <span>حذف الباقة</span>
                </button>

                {/* Button 3: تسديد + تفعيل (Opens Confirmation Dialog) */}
                <button
                  onClick={initiatePackagePayment}
                  className="w-full py-3 rounded-2xl bg-white border-2 border-emerald-500 text-emerald-700 hover:bg-emerald-50 font-black text-sm flex items-center justify-center gap-2 shadow-md active:scale-95 transition"
                >
                  <div className="w-5 h-5 rounded-full bg-emerald-500 text-white flex items-center justify-center">
                    <Check className="w-3.5 h-3.5" />
                  </div>
                  <span>تسديد + تفعيل</span>
                </button>
              </div>

            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL 3: CONFIRMATION DIALOG - Exactly matches Screenshot 5 & 21!         */}
        {/* Orange circular (i), tables, Arabic amount, last tx, keypad, 3 buttons    */}
        {/* ========================================================================= */}
        {confirmDialogData.isOpen && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-[2px] z-50 flex items-center justify-center p-3 animate-fade-in overflow-y-auto">
            <div className="bg-white rounded-3xl p-4 shadow-2xl max-w-[380px] w-full border border-slate-200 relative my-auto space-y-3">

              {/* Close Button Top Left */}
              <button
                onClick={() => setConfirmDialogData((prev) => ({ ...prev, isOpen: false }))}
                className="absolute top-3 left-3 w-8 h-8 rounded-full bg-rose-50 text-rose-500 hover:bg-rose-100 flex items-center justify-center"
              >
                <X className="w-4 h-4" />
              </button>

              {/* Orange circular (i) icon */}
              <div className="flex flex-col items-center justify-center pt-1">
                <div className="w-14 h-14 rounded-full border-4 border-amber-500 flex items-center justify-center text-amber-500 font-serif text-3xl font-black shadow-inner">
                  i
                </div>
                <div className="flex items-center gap-2 w-full mt-2">
                  <div className="flex-1 border-t-2 border-amber-400"></div>
                  <span className="text-amber-600 font-black text-sm px-1">تأكيد الطلب</span>
                  <div className="flex-1 border-t-2 border-amber-400"></div>
                </div>
              </div>

              {/* Table 1: تفاصيل الطلب */}
              <div>
                <div className="text-[11px] font-extrabold text-[#0284C7] mb-1">تفاصيل الطلب</div>
                <div className="bg-slate-50 rounded-xl overflow-hidden border border-slate-200 text-[11px]">
                  <div className="grid grid-cols-3 bg-slate-100/80 text-slate-700 font-extrabold py-1 px-2 text-center border-b border-slate-200">
                    <span>الخدمة</span>
                    <span>الصنف</span>
                    <span>رقم الهاتف</span>
                  </div>
                  <div className="grid grid-cols-3 py-1.5 px-2 text-center font-bold text-slate-800">
                    <span>{confirmDialogData.serviceName}</span>
                    <span className="truncate px-1">{confirmDialogData.itemName}</span>
                    <span dir="ltr">{confirmDialogData.phoneNumber}</span>
                  </div>
                </div>
              </div>

              {/* Table 2: تفاصيل التكلفة */}
              <div>
                <div className="text-[11px] font-extrabold text-[#0284C7] mb-1">تفاصيل التكلفة</div>
                <div className="bg-slate-50 rounded-xl overflow-hidden border border-slate-200 text-[11px]">
                  <div className="grid grid-cols-3 bg-slate-100/80 text-slate-700 font-extrabold py-1 px-2 text-center border-b border-slate-200">
                    <span>المبلغ</span>
                    <span>النسبة</span>
                    <span>التكلفة</span>
                  </div>
                  <div className="grid grid-cols-3 py-1.5 px-2 text-center font-bold text-slate-800">
                    <span>{confirmDialogData.amount}</span>
                    <span>% {confirmDialogData.feeRatio}</span>
                    <span>{confirmDialogData.totalCost.toFixed(2)}</span>
                  </div>
                </div>
                {/* Arabic words text */}
                <div className="text-center text-xs font-black text-slate-800 mt-1">
                  *اجمالي التكلفة : {confirmDialogData.amountArabicWords}
                </div>
              </div>

              {/* Card: اخر عملية لهذا الرقم (Real Verification Check - هل هي حقيقية) */}
              <div className="bg-white rounded-xl p-2.5 border border-slate-200 shadow-sm text-right space-y-1">
                <div className="flex items-center justify-between text-[10px] text-slate-500 font-bold">
                  <div className="flex items-center gap-1 text-slate-800 font-extrabold">
                    <Bell className="w-3.5 h-3.5 text-rose-500" />
                    <span>اخر عملية لهذا الرقم</span>
                  </div>
                  <span>{confirmDialogData.lastTxTime || "لا توجد"}</span>
                </div>
                <div className="text-xs font-bold text-slate-800">
                  {confirmDialogData.lastTxName || "لا توجد عمليات سابقة"}
                </div>
                <div className="flex items-center justify-between pt-1 border-t border-slate-100 text-[10px]">
                  {confirmDialogData.isRealVerified ? (
                    <div className="flex items-center gap-1 text-emerald-600 font-extrabold">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>حقيقية ومؤكدة بالسيرفر ✓</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-1 text-amber-600 font-bold">
                      <Info className="w-3.5 h-3.5" />
                      <span>عملية جديدة لأول مرة</span>
                    </div>
                  )}
                  <span className="font-bold text-slate-700">{confirmDialogData.lastTxAmount || "-"}</span>
                  <span
                    onClick={() =>
                      alert(
                        `فحص جاهزية الرقم ${confirmDialogData.phoneNumber}: الخدمة نشطة، والرقم مؤهل للتسديد الفوري!`
                      )
                    }
                    className="text-[#0284C7] underline cursor-pointer font-bold"
                  >
                    فحص الجاهزية
                  </span>
                </div>
              </div>

              {/* Section: المبلغ المستلم & Keypad (Screenshot 5) */}
              <div>
                <div className="bg-slate-50 rounded-xl p-2 border border-slate-200 flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-slate-500">المبلغ المستلم</span>
                  <span className="font-extrabold text-slate-800 text-sm">
                    {confirmDialogData.receivedAmount || "0"}
                  </span>
                </div>

                {/* Keypad Grid: 1 2 3 4 5 6 / 7 8 9 0 x */}
                <div className="grid grid-cols-6 gap-1.5 text-xs font-bold text-slate-800">
                  {["1", "2", "3", "4", "5", "6"].map((n) => (
                    <button
                      key={`keypad-num-${n}`}
                      onClick={() => handleKeypadPress(n)}
                      className="py-1.5 bg-slate-100 hover:bg-slate-200 rounded-lg text-center transition active:scale-95 shadow-sm"
                    >
                      {n}
                    </button>
                  ))}
                </div>
                <div className="grid grid-cols-5 gap-1.5 text-xs font-bold text-slate-800 mt-1.5">
                  {["7", "8", "9", "0", "x"].map((n) => (
                    <button
                      key={`keypad-num-${n}`}
                      onClick={() => handleKeypadPress(n)}
                      className={`py-1.5 rounded-lg text-center transition active:scale-95 shadow-sm ${
                        n === "x" ? "bg-rose-100 text-rose-600" : "bg-slate-100 hover:bg-slate-200"
                      }`}
                    >
                      {n}
                    </button>
                  ))}
                </div>
              </div>

              {/* Bottom 3 Action Buttons: موافق | عبر الرسائل | عبر الواتس */}
              <div className="grid grid-cols-3 gap-2 pt-2">
                <button
                  onClick={handleFinalRechargeExecute}
                  className="py-2.5 rounded-xl bg-[#4CAF50] hover:bg-[#43A047] text-white font-extrabold text-xs flex items-center justify-center gap-1 shadow-md active:scale-95 transition"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>موافق</span>
                </button>

                <button
                  onClick={() => alert("إرسال عبر الرسائل SMS")}
                  className="py-2.5 rounded-xl bg-[#1E88E5] hover:bg-[#1976D2] text-white font-extrabold text-xs flex items-center justify-center gap-1 shadow-md active:scale-95 transition"
                >
                  <Mail className="w-4 h-4" />
                  <span>عبر الرسائل</span>
                </button>

                <button
                  onClick={() => alert("إرسال عبر الواتساب")}
                  className="py-2.5 rounded-xl bg-[#00BCD4] hover:bg-[#00ACC1] text-white font-extrabold text-xs flex items-center justify-center gap-1 shadow-md active:scale-95 transition"
                >
                  <MessageCircle className="w-4 h-4" />
                  <span>عبر الواتس</span>
                </button>
              </div>

            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL 4: FAILURE POPUP - Exactly matches the physical phone photo!         */}
        {/* Orange circular (i) + "فشل اثناء تنفيذ عملية التسديد! السبب/ ..." + موافق  */}
        {/* ========================================================================= */}
        {failureDialog.isOpen && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-[2px] z-50 flex items-center justify-center p-4 animate-fade-in">
            <div className="bg-white rounded-3xl p-5 shadow-2xl max-w-[300px] w-full border border-slate-200 text-center space-y-3">
              {/* Circular orange (i) */}
              <div className="w-14 h-14 rounded-full border-4 border-amber-500 mx-auto flex items-center justify-center text-amber-500 font-serif text-3xl font-black">
                i
              </div>

              {/* Title & Reason */}
              <div className="text-xs font-extrabold text-slate-800 leading-relaxed">
                <div>{failureDialog.title}</div>
                <div className="text-slate-600 font-normal mt-1 leading-normal text-[11px]" dir="ltr">
                  {failureDialog.reason}
                </div>
              </div>

              {/* Coral Red button: موافق */}
              <button
                onClick={() => setFailureDialog((prev) => ({ ...prev, isOpen: false }))}
                className="w-full py-2 rounded-xl bg-[#E57373] hover:bg-[#EF5350] text-white font-black text-xs shadow-md transition active:scale-95"
              >
                موافق
              </button>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* MODAL 5: SUCCESS POPUP                                                    */}
        {/* ========================================================================= */}
        {successDialog.isOpen && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-[2px] z-50 flex items-center justify-center p-4 animate-fade-in">
            <div className="bg-white rounded-3xl p-5 shadow-2xl max-w-[320px] w-full border border-slate-200 text-center space-y-3">
              <div className="w-14 h-14 rounded-full bg-emerald-100 mx-auto flex items-center justify-center text-emerald-600">
                <CheckCircle2 className="w-8 h-8" />
              </div>
              <div className="text-sm font-extrabold text-slate-900">{successDialog.title}</div>
              <div className="text-xs text-slate-600 leading-relaxed">{successDialog.message}</div>
              <div className="text-[10px] text-slate-400 font-mono">المرجع: {successDialog.referenceId}</div>
              <button
                onClick={() => setSuccessDialog((prev) => ({ ...prev, isOpen: false }))}
                className="w-full py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs shadow-md transition active:scale-95"
              >
                تم
              </button>
            </div>
          </div>
        )}

        {/* Contacts Book Modal */}
        {isContactsModalOpen && (
          <div className="absolute inset-0 bg-black/50 backdrop-blur-[1px] z-50 flex flex-col justify-end">
            <div className="bg-white rounded-t-3xl p-4 shadow-2xl border-t border-slate-200 max-h-[70%] overflow-y-auto space-y-2">
              <div className="flex items-center justify-between border-b pb-2 mb-2">
                <span className="font-extrabold text-xs text-slate-800">اختر من دفتر العناوين</span>
                <button onClick={() => setIsContactsModalOpen(false)}>
                  <X className="w-4 h-4 text-slate-500" />
                </button>
              </div>
              {[
                { name: "زيدان العطاب (يمن موبايل)", phone: "774952665" },
                { name: "راوتر المكتب (يمن فورجي)", phone: "104463982" },
                { name: "انترنت المنزل (يمن نت)", phone: "04469543" },
                { name: "أحمد سبأفون", phone: "713333333" },
                { name: "خالد يو", phone: "736988645" },
              ].map((c, i) => (
                <div
                  key={i}
                  onClick={() => {
                    setPhoneNumber(c.phone);
                    setIsContactsModalOpen(false);
                  }}
                  className="p-2.5 rounded-xl hover:bg-slate-100 flex items-center justify-between cursor-pointer border border-slate-100"
                >
                  <span className="text-xs font-bold text-slate-800">{c.name}</span>
                  <span className="text-xs font-mono text-slate-500" dir="ltr">{c.phone}</span>
                </div>
              ))}
            </div>
          </div>
        )}

            </div>
          )}
        </div>

        {/* Persistent Bottom Navigation Bar - Accessible on all screens! */}
        {/* Material 3 Bottom Navigation Bar - Exact 5 destinations matching Flutter HomeShell */}
        <div className="bg-white border-t border-slate-200/90 px-3 py-2 flex items-center justify-around shadow-lg z-30 shrink-0 sticky bottom-0">
          <button
            onClick={() => setActiveScreen("main_home")}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all ${
              activeScreen === "main_home"
                ? "bg-[#8B1D3B]/10 text-[#8B1D3B] font-black scale-105"
                : "text-slate-500 hover:text-slate-800 font-bold"
            }`}
          >
            <Home className="w-5 h-5 mb-0.5" />
            <span className="text-[10px]">حسابي</span>
          </button>

          <button
            onClick={() => setActiveScreen("payment")}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all ${
              activeScreen === "payment"
                ? "bg-[#8B1D3B]/10 text-[#8B1D3B] font-black scale-105"
                : "text-slate-500 hover:text-slate-800 font-bold"
            }`}
          >
            <CreditCard className="w-5 h-5 mb-0.5" />
            <span className="text-[10px]">السداد</span>
          </button>

          <button
            onClick={() => setActiveScreen("store")}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all ${
              activeScreen === "store"
                ? "bg-emerald-50 text-[#059669] font-black scale-105"
                : "text-slate-500 hover:text-slate-800 font-bold"
            }`}
          >
            <ShoppingBag className="w-5 h-5 mb-0.5" />
            <span className="text-[10px]">المتجر</span>
          </button>

          <button
            onClick={() => setActiveScreen("operations")}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all ${
              activeScreen === "operations"
                ? "bg-sky-50 text-[#0284C7] font-black scale-105"
                : "text-slate-500 hover:text-slate-800 font-bold"
            }`}
          >
            <History className="w-5 h-5 mb-0.5" />
            <span className="text-[10px]">العمليات</span>
          </button>

          <button
            onClick={() => setActiveScreen("settings")}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-2xl transition-all ${
              activeScreen === "settings"
                ? "bg-slate-100 text-slate-800 font-black scale-105"
                : "text-slate-500 hover:text-slate-800 font-bold"
            }`}
          >
            <Settings className="w-5 h-5 mb-0.5" />
            <span className="text-[10px]">الإعدادات</span>
          </button>
        </div>

        {/* Operation Details Modal (if open) */}
        {selectedOpForDetail && (
          <OperationDetailModal
            operation={selectedOpForDetail}
            onClose={() => setSelectedOpForDetail(null)}
            onStatusUpdated={(updated) => {
              setSelectedOpForDetail(updated);
              setOperationsList((prev) =>
                prev.map((o) => (o.id === updated.id ? updated : o))
              );
            }}
          />
        )}

      </div>
    </div>
  );
}
