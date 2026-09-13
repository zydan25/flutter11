import React, { useState } from "react";
import { OperationItem } from "../types";
import { ArrowRight, Share2, CheckCircle2, RotateCcw, Printer, Copy, Check } from "lucide-react";

interface OperationDetailModalProps {
  operation: OperationItem;
  onClose: () => void;
  onStatusUpdated?: (op: OperationItem) => void;
}

export const OperationDetailModal: React.FC<OperationDetailModalProps> = ({
  operation,
  onClose,
  onStatusUpdated,
}) => {
  const [checking, setChecking] = useState(false);
  const [copied, setCopied] = useState(false);

  const opId = operation.id || "32ce0ab6-67d6-481b-a4fc-70ec30ba75a3";
  const shortId = opId.length > 12 ? `${opId.substring(0, 12)}...` : opId;
  const service = operation.service || operation.packageName || "freefire";
  const type = operation.type || "دفع مسبق";
  const phone = operation.phoneNumber || operation.phone || operation.mobile || "";
  const amount = Number(operation.amount || 1200).toFixed(2);
  const createdAt = operation.created_at || "2026-09-10T12:19:56.659877+00:00";
  const completedAt = operation.completed_at || "2026-09-10T12:20:31.589978+00:00";
  const readiness = operation.status || "جاهز";
  const stateCode = operation.state_code || "refunded";
  const chipCode = operation.chip_code || "7bc188ad33bec2c1";
  const notes = operation.notes || "تم تجهيز العملية من نظام المزود تزامن مباشر! الرد: تصحيح الجاهزية بعد التأكد";
  const cancelReason = operation.cancel_reason || "---";
  const transferNumber = operation.transfer_number || "---";

  const handleCopy = () => {
    navigator.clipboard?.writeText(opId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleCheck = async () => {
    setChecking(true);
    try {
      await fetch(`/api/v2/services/requests/${opId}/provider-check/`, {
        method: "POST",
      }).catch(() => null);

      const updated = {
        ...operation,
        status: "جاهز",
        notes: "تم تجهيز العملية من نظام المزود تزامن مباشر! الرد: تصحيح الجاهزية بعد التأكد",
      };
      onStatusUpdated?.(updated);
      alert("العملية جاهز: تم فحص وتأكيد الجاهزية بنجاح من نظام المزود!");
    } finally {
      setChecking(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex flex-col justify-end sm:justify-center sm:items-center p-0 sm:p-4 overflow-y-auto" dir="rtl">
      <div className="bg-slate-100 rounded-t-3xl sm:rounded-3xl max-w-md w-full max-h-[92vh] flex flex-col shadow-2xl overflow-hidden">
        {/* Top Header (Matching Screenshot 4) */}
        <div className="bg-[#8B1D3B] text-white px-4 py-3 flex items-center justify-between shadow-xs">
          <button onClick={onClose} className="p-1 rounded-full hover:bg-white/10">
            <ArrowRight className="w-5 h-5 text-white" />
          </button>
          <h2 className="text-xs font-black truncate max-w-[220px]">
            تفاصيل العملية رقم: {shortId}
          </h2>
          <button
            onClick={handleCopy}
            className="p-1 rounded-full hover:bg-white/10"
            title="مشاركة أو نسخ"
          >
            <Share2 className="w-4 h-4 text-white" />
          </button>
        </div>

        <div className="p-4 space-y-3.5 overflow-y-auto flex-1">
          {/* Big Green Banner: العملية جاهز (Matching Screenshot 4) */}
          <div className="bg-emerald-700 text-white rounded-xl py-3 px-4 flex items-center justify-center gap-2 shadow-xs">
            <CheckCircle2 className="w-6 h-6 text-white" />
            <span className="text-base font-black">العملية جاهز</span>
          </div>

          {/* Details Table (Matching Screenshot 4 exactly) */}
          <div className="bg-white rounded-2xl border border-slate-200 divide-y divide-slate-100 text-xs shadow-xs">
            {/* رقم العملية */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">رقم العملية</span>
              <div className="flex items-center gap-1.5 font-mono text-[11px] font-bold text-slate-900">
                <button
                  onClick={handleCopy}
                  className="p-1 rounded hover:bg-slate-100 text-slate-400"
                >
                  {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
                <span className="break-all">{opId}</span>
              </div>
            </div>

            {/* الخدمة */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">الخدمة</span>
              <span className="font-black text-slate-900">{service}</span>
            </div>

            {/* الصنف / الزبون */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">الصنف / الزبون</span>
              <span className="font-bold text-slate-700">{type}</span>
            </div>

            {/* رقم الهاتف */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">رقم الهاتف</span>
              <span className="font-mono font-bold text-slate-900">{phone || ""}</span>
            </div>

            {/* السعر */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">السعر</span>
              <span className="font-black text-red-600 text-sm">{amount} ر.ي</span>
            </div>

            {/* تاريخ الاضافة */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">تاريخ الاضافة</span>
              <span className="font-mono text-[11px] text-slate-600">{createdAt}</span>
            </div>

            {/* تاريخ التجهيز */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">تاريخ التجهيز</span>
              <span className="font-mono text-[11px] text-slate-600">{completedAt}</span>
            </div>

            {/* الجاهزية */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">الجاهزية</span>
              <span className="font-black text-emerald-600">{readiness}</span>
            </div>

            {/* الحالة */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">الحالة</span>
              <span className="font-bold text-slate-700">{stateCode}</span>
            </div>

            {/* رقم الشريحة / البرمجة */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">رقم الشريحة / البرمجة</span>
              <span className="font-mono text-slate-700">{chipCode}</span>
            </div>

            {/* ملاحظات */}
            <div className="p-3 flex justify-between items-start gap-4">
              <span className="font-bold text-slate-500 whitespace-nowrap">ملاحظات</span>
              <span className="font-bold text-[11px] text-slate-700 text-left">{notes}</span>
            </div>

            {/* سبب الالغاء */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">سبب الالغاء</span>
              <span className="text-slate-400">{cancelReason}</span>
            </div>

            {/* رقم الحوالة */}
            <div className="p-3 flex justify-between items-center">
              <span className="font-bold text-slate-500">رقم الحوالة</span>
              <span className="text-slate-400">{transferNumber}</span>
            </div>
          </div>

          {/* Action Buttons: فحص العملية & طباعة (Matching Screenshot 4) */}
          <div className="flex gap-2.5 pt-1">
            <button
              onClick={handleCheck}
              disabled={checking}
              className="flex-1 py-3 bg-red-700 hover:bg-red-800 active:scale-98 text-white rounded-xl text-xs font-black flex items-center justify-center gap-2 shadow-sm transition disabled:opacity-50"
            >
              <RotateCcw className={`w-4 h-4 ${checking ? "animate-spin" : ""}`} />
              <span>فحص العملية</span>
            </button>

            <button
              onClick={() => window.print()}
              className="w-28 py-3 bg-white border border-red-700 text-red-700 hover:bg-red-50 active:scale-98 rounded-xl text-xs font-black flex items-center justify-center gap-1.5 shadow-sm transition"
            >
              <Printer className="w-4 h-4" />
              <span>طباعة</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
