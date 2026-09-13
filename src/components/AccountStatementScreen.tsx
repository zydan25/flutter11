import React from "react";
import { ArrowRight, RefreshCw } from "lucide-react";

export const AccountStatementScreen: React.FC<{
  walletBalance: number;
  onBack: () => void;
  onRefreshWallet?: () => void;
}> = ({ walletBalance, onBack, onRefreshWallet }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
          <ArrowRight className="w-5 h-5" />
        </button>
        <h2 className="text-base font-black text-slate-900">كشف الحساب وتغذية المحفظة</h2>
      </div>
      {onRefreshWallet && (
        <button onClick={onRefreshWallet} className="p-2 rounded-full hover:bg-slate-100 text-slate-600">
          <RefreshCw className="w-4 h-4" />
        </button>
      )}
    </div>
    <div className="bg-white p-4 rounded-2xl border border-slate-200">
      <p className="text-xs text-slate-500 font-bold">الرصيد المتوفر حالياً</p>
      <p className="text-xl font-black text-[#8B1D3B] mt-1">{Number(walletBalance).toLocaleString()} ر.ي</p>
    </div>
  </div>
);
