import React from "react";
import { OperationItem } from "../types";
import { ArrowRight, BarChart3, RefreshCw } from "lucide-react";

export const ReportsScreen: React.FC<{
  onBack: () => void;
  operations: OperationItem[];
  walletBalance: number;
  onRefresh: () => void;
  onSelectOperation?: (op: OperationItem) => void;
}> = ({ onBack, operations, walletBalance, onRefresh }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
          <ArrowRight className="w-5 h-5" />
        </button>
        <h2 className="text-base font-black text-slate-900">التقارير المالية والعمليات</h2>
      </div>
      <button onClick={onRefresh} className="p-2 rounded-full hover:bg-slate-100 text-slate-600">
        <RefreshCw className="w-4 h-4" />
      </button>
    </div>
    <div className="bg-white p-4 rounded-2xl border border-slate-200">
      <p className="text-xs text-slate-500 font-bold">إجمالي العمليات المنجزة</p>
      <p className="text-xl font-black text-slate-900 mt-1">{operations.length} عملية</p>
    </div>
  </div>
);
