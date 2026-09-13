import React, { useState } from "react";
import { ArrowRight } from "lucide-react";

export const SubscriberTransferScreen: React.FC<{
  walletBalance: number;
  onBack: () => void;
  onTransferSuccess?: (amt: number) => void;
}> = ({ walletBalance, onBack }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center gap-2">
      <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
        <ArrowRight className="w-5 h-5" />
      </button>
      <h2 className="text-base font-black text-slate-900">تحويل رصيد لمشترك آخر</h2>
    </div>
    <div className="bg-white p-4 rounded-2xl border border-slate-200">
      <p className="text-xs text-slate-600 font-bold">يمكنك تحويل رصيد مباشر لأي رقم هاتف أو حساب شبيك مسجل.</p>
    </div>
  </div>
);
