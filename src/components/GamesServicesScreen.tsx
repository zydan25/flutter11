import React from "react";
import { ArrowRight, Gamepad2 } from "lucide-react";

export const GamesServicesScreen: React.FC<{
  walletBalance: number;
  onBack: () => void;
  onRechargeGame?: (amt: number) => void;
}> = ({ walletBalance, onBack }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center gap-2">
      <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
        <ArrowRight className="w-5 h-5" />
      </button>
      <h2 className="text-base font-black text-slate-900">شحن الألعاب والتطبيقات</h2>
    </div>
    <div className="bg-white p-4 rounded-2xl border border-slate-200">
      <p className="text-xs text-slate-600 font-bold">شحن ببجي، فري فاير، وبطاقات الألعاب الإلكترونية الفورية.</p>
    </div>
  </div>
);
