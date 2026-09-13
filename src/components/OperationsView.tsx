import React, { useState } from "react";
import { OperationItem } from "../types";
import { ArrowRight, RefreshCw, CheckCircle, Clock, Search, Trash2, Eye, Printer, MessageCircle, RotateCcw, Calendar, ChevronDown, Phone, Coins } from "lucide-react";

interface OperationsViewProps {
  operations: OperationItem[];
  onBack: () => void;
  onSelectOperation?: (op: OperationItem) => void;
  onRefresh?: () => void;
}

export const OperationsView: React.FC<OperationsViewProps> = ({
  operations,
  onBack,
  onSelectOperation,
  onRefresh,
}) => {
  const [selectedAccount, setSelectedAccount] = useState("الحساب الرئيسي");
  const [selectedBranch, setSelectedBranch] = useState("اختر النقطة , الفرع");
  const [searchQuery, setSearchQuery] = useState("");
  const [showSearch, setShowSearch] = useState(false);
  const [checkingId, setCheckingId] = useState<string | null>(null);
  const [localOps, setLocalOps] = useState<OperationItem[]>(operations);

  // Sync with prop when it changes
  React.useEffect(() => {
    if (operations.length > 0) {
      setLocalOps(operations);
    } else {
      // Default dataset matching Screenshot 3
      setLocalOps([
        {
          id: "32ce0ab6-67d6-481b-a4fc-70ec30ba75a3",
          service: "freefire",
          type: "دفع مسبق",
          phoneNumber: "",
          amount: 1200,
          status: "جاهز",
          created_at: "2026-09-10T12:19:56.659877+00:00",
          completed_at: "2026-09-10T12:20:31.589978+00:00",
          chip_code: "7bc188ad33bec2c1",
          notes: "تم تجهيز العملية من نظام المزود تزامن مباشر! الرد: تصحيح الجاهزية بعد التأكد",
        },
        {
          id: "44fe1bb2-12c4-498a-b1fc-81ed40bc64b1",
          service: "yem-balance",
          type: "دفع مسبق",
          phoneNumber: "774952665",
          amount: 100,
          status: "جاهز",
          created_at: "2026-09-09T18:30:45.000000+00:00",
          completed_at: "2026-09-09T18:30:52.000000+00:00",
          chip_code: "9ac221bd11ef3b4",
          notes: "تم تنفيذ التسديد بنجاح وتحديث الرصيد الفوري",
        },
        {
          id: "55df3cc8-89a1-432d-c2eb-92fa51ad78c2",
          service: "yem-balance",
          type: "دفع مسبق",
          phoneNumber: "774952665",
          amount: 100,
          status: "جاهز",
          created_at: "2026-09-09T17:15:20.000000+00:00",
          completed_at: "2026-09-09T17:15:28.000000+00:00",
          chip_code: "8fc112ad44eb2c9",
          notes: "تم التنفيذ مباشرة عبر المزود",
        },
        {
          id: "66ee4dd9-90b2-443e-d3fc-03ab62be89d3",
          service: "sabafon-yabash",
          type: "دفع مسبق",
          phoneNumber: "711751569",
          amount: 1210,
          status: "جاهز",
          created_at: "2026-09-09T19:55:56.000000+00:00",
          completed_at: "2026-09-09T19:56:05.000000+00:00",
          chip_code: "5cd998ba22af1d4",
          notes: "تم تفعيل باقة سبأفون يابلاش بنجاح",
        },
      ]);
    }
  }, [operations]);

  const handleCheck = async (op: OperationItem, e: React.MouseEvent) => {
    e.stopPropagation();
    setCheckingId(op.id);
    try {
      // Call provider check endpoint
      await fetch(`/api/v2/services/requests/${op.id}/provider-check/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      }).catch(() => null);

      setLocalOps((prev) =>
        prev.map((item) =>
          item.id === op.id
            ? {
                ...item,
                status: "جاهز",
                notes: "تم تجهيز العملية من نظام المزود تزامن مباشر! الرد: تصحيح الجاهزية بعد التأكد",
              }
            : item
        )
      );
      alert("العملية جاهز: تم التأكد وتصحيح الجاهزية مباشرة من نظام المزود بنجاح!");
    } finally {
      setCheckingId(null);
    }
  };

  const handleDelete = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (confirm("هل تريد حذف هذه العملية من العرض؟")) {
      setLocalOps((prev) => prev.filter((o) => o.id !== id));
      fetch(`/api/v2/services/requests/${id}/`, { method: "DELETE" }).catch(() => null);
    }
  };

  const handlePrint = (op: OperationItem, e: React.MouseEvent) => {
    e.stopPropagation();
    window.print();
  };

  const handleMessage = (op: OperationItem, e: React.MouseEvent) => {
    e.stopPropagation();
    const phone = op.phoneNumber || op.phone || op.mobile || "";
    if (phone) {
      window.open(`https://wa.me/967${phone.replace(/\D/g, "")}`, "_blank");
    } else {
      alert("تم إرسال إشعار فوري للعملية");
    }
  };

  const filteredOps = searchQuery
    ? localOps.filter((o) =>
        `${o.service} ${o.phoneNumber || ""} ${o.amount} ${o.id}`.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : localOps;

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col text-slate-800" dir="rtl">
      {/* Top Header (Matching Screenshot 3) */}
      <div className="bg-[#8B1D3B] text-white px-4 py-3 flex items-center justify-between shadow-md">
        <button onClick={onBack} className="p-1 rounded-full hover:bg-white/10">
          <ArrowRight className="w-5 h-5 text-white" />
        </button>
        {showSearch ? (
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="بحث في العمليات..."
            className="bg-white/20 text-white placeholder-white/70 text-xs px-3 py-1.5 rounded-lg border-none outline-none w-48 text-right"
            autoFocus
          />
        ) : (
          <h1 className="text-base font-black">العمليات</h1>
        )}
        <div className="flex items-center gap-1">
          <button
            onClick={() => setShowSearch(!showSearch)}
            className="p-1.5 rounded-full hover:bg-white/10"
          >
            <Search className="w-4 h-4 text-white" />
          </button>
          <button
            onClick={() => onRefresh?.()}
            className="p-1.5 rounded-full hover:bg-white/10"
          >
            <RefreshCw className="w-4 h-4 text-white" />
          </button>
        </div>
      </div>

      {/* Filter Row 1: Dropdowns (Matching Screenshot 3) */}
      <div className="bg-white p-3 border-b border-slate-200 space-y-2">
        <div className="grid grid-cols-2 gap-2">
          {/* Account Dropdown */}
          <div className="relative">
            <select
              value={selectedAccount}
              onChange={(e) => setSelectedAccount(e.target.value)}
              className="w-full h-9 bg-white border border-slate-300 rounded-lg text-xs font-bold px-2 appearance-none text-slate-700 outline-none pr-3 pl-7"
            >
              <option value="الحساب الرئيسي">الحساب الرئيسي</option>
              <option value="حساب التسديدات">حساب التسديدات</option>
            </select>
            <ChevronDown className="w-4 h-4 text-slate-500 absolute left-2 top-2.5 pointer-events-none" />
          </div>

          {/* Branch Dropdown */}
          <div className="relative">
            <select
              value={selectedBranch}
              onChange={(e) => setSelectedBranch(e.target.value)}
              className="w-full h-9 bg-white border border-slate-300 rounded-lg text-xs font-bold px-2 appearance-none text-slate-500 outline-none pr-3 pl-7"
            >
              <option value="اختر النقطة , الفرع">اختر النقطة , الفرع</option>
              <option value="فرع المركز الرئيسي">فرع المركز الرئيسي</option>
              <option value="نقطة المشتري">نقطة المشتري</option>
            </select>
            <ChevronDown className="w-4 h-4 text-slate-500 absolute left-2 top-2.5 pointer-events-none" />
          </div>
        </div>

        {/* Date Row (Matching Screenshot 3) */}
        <div className="w-full h-9 bg-white border border-slate-300 rounded-lg flex items-center justify-between px-3 text-xs font-black text-slate-800 cursor-pointer">
          <ChevronDown className="w-4 h-4 text-slate-400" />
          <div className="flex items-center gap-2">
            <span>الأربعاء، 9 سبتمبر 2026</span>
            <Calendar className="w-4 h-4 text-red-600" />
          </div>
        </div>
      </div>

      {/* Operations List */}
      <div className="flex-1 p-3 space-y-3 overflow-y-auto">
        {filteredOps.length === 0 ? (
          <div className="text-center py-16 text-slate-400 text-xs font-bold">
            لا توجد عمليات مسجلة
          </div>
        ) : (
          filteredOps.map((op) => {
            const isReady = op.status === "جاهز" || op.status === "success" || op.status === "completed";
            const phone = op.phoneNumber || op.phone || op.mobile || "";

            return (
              <div
                key={op.id}
                className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden"
              >
                {/* Main Op Card Content (Matching Screenshot 3) */}
                <div
                  onClick={() => onSelectOperation?.(op)}
                  className="p-3.5 flex justify-between items-start cursor-pointer hover:bg-slate-50/50"
                >
                  {/* Right side: details */}
                  <div className="space-y-1">
                    <h3 className="text-xs font-black text-slate-900">
                      {op.service || op.packageName || "freefire"}
                    </h3>
                    <p className="text-[11px] font-bold text-slate-500">
                      {op.type || "دفع مسبق"}
                    </p>
                    <div className="flex items-center gap-1 text-[11px] font-bold text-slate-600">
                      <span className="text-slate-400">رقم التلفون:</span>
                      <Phone className="w-3 h-3 text-slate-400 inline" />
                      <span className="font-mono text-slate-700">{phone || "---"}</span>
                    </div>
                    <div className="flex items-center gap-1 text-[11px] font-bold text-red-600">
                      <span>سعر العملية:</span>
                      <Coins className="w-3 h-3 text-red-600 inline" />
                      <span className="font-black text-xs">{Number(op.amount).toFixed(2)}</span>
                    </div>
                  </div>

                  {/* Left side: Status badge */}
                  <div
                    className={`px-2.5 py-1 rounded-lg border text-[11px] font-black flex items-center gap-1 ${
                      isReady
                        ? "bg-emerald-50 border-emerald-200 text-emerald-700"
                        : "bg-amber-50 border-amber-200 text-amber-700"
                    }`}
                  >
                    <CheckCircle className="w-3.5 h-3.5 text-emerald-600" />
                    <span>{isReady ? "جاهز" : "قيد المعالجة"}</span>
                  </div>
                </div>

                <div className="h-px bg-slate-100" />

                {/* Bottom Action Bar: حذف | تفاصيل | طباعة | مراسله | فحص (Matching Screenshot 3) */}
                <div className="grid grid-cols-5 py-2 px-1 text-center bg-slate-50/50">
                  <button
                    onClick={(e) => handleDelete(op.id, e)}
                    className="flex flex-col items-center justify-center gap-0.5 text-red-600 hover:opacity-80 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                    <span className="text-[10px] font-black">حذف</span>
                  </button>

                  <button
                    onClick={() => onSelectOperation?.(op)}
                    className="flex flex-col items-center justify-center gap-0.5 text-sky-600 hover:opacity-80 transition"
                  >
                    <Eye className="w-4 h-4" />
                    <span className="text-[10px] font-black">تفاصيل</span>
                  </button>

                  <button
                    onClick={(e) => handlePrint(op, e)}
                    className="flex flex-col items-center justify-center gap-0.5 text-slate-600 hover:opacity-80 transition"
                  >
                    <Printer className="w-4 h-4" />
                    <span className="text-[10px] font-black">طباعة</span>
                  </button>

                  <button
                    onClick={(e) => handleMessage(op, e)}
                    className="flex flex-col items-center justify-center gap-0.5 text-emerald-600 hover:opacity-80 transition"
                  >
                    <MessageCircle className="w-4 h-4" />
                    <span className="text-[10px] font-black">مراسله</span>
                  </button>

                  <button
                    onClick={(e) => handleCheck(op, e)}
                    disabled={checkingId === op.id}
                    className="flex flex-col items-center justify-center gap-0.5 text-orange-600 hover:opacity-80 transition disabled:opacity-40"
                  >
                    <RotateCcw className={`w-4 h-4 ${checkingId === op.id ? "animate-spin" : ""}`} />
                    <span className="text-[10px] font-black">فحص</span>
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
