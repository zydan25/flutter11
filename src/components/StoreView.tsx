import React, { useState, useEffect } from "react";
import { ShoppingBag, Search, Heart, Store, ChevronLeft, ArrowRight } from "lucide-react";

interface StoreViewProps {
  onNavigateToAccount?: () => void;
  onNavigateToPayment?: () => void;
  walletBalance?: number;
}

export const StoreView: React.FC<StoreViewProps> = ({
  onNavigateToAccount,
  onNavigateToPayment,
  walletBalance = 5420,
}) => {
  const [products, setProducts] = useState<any[]>([]);
  const [cart, setCart] = useState<{ [id: number]: number }>({});
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState("الكل");

  useEffect(() => {
    fetch("https://shopik.alattab.site/api/products/", {
      headers: {
        Authorization: "Token 3241591d9733768e4b5d3226c96b200e04c7ca15",
        Accept: "application/json",
      },
    })
      .then((r) => r.json())
      .then((data) => {
        if (data && data.results) setProducts(data.results);
      })
      .catch(() => {});
  }, []);

  const totalCartCount = (Object.values(cart) as number[]).reduce((a: number, b: number) => a + b, 0);

  return (
    <div className="p-4 space-y-4">
      {/* Top Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-10 h-10 rounded-xl bg-[#8B1D3B] flex items-center justify-center text-white shadow-sm">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-base font-black text-slate-900">سوق شبيك بلس</h1>
            <p className="text-xs text-slate-500 font-semibold">المتجر الإلكتروني المعتمد</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={onNavigateToAccount}
            className="px-3 py-1.5 rounded-full bg-rose-50 border border-rose-200 text-[#8B1D3B] text-xs font-bold"
          >
            حسابي
          </button>
          <div className="relative">
            <button className="w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center text-slate-700">
              <ShoppingBag className="w-4 h-4" />
            </button>
            {totalCartCount > 0 && (
              <span className="absolute -top-1 -right-1 bg-emerald-600 text-white text-[10px] font-bold rounded-full w-4 h-4 flex items-center justify-center">
                {totalCartCount}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <input
          type="text"
          placeholder="ابحث عن المنتجات أو المتاجر المعتمدة..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-4 pr-10 py-2.5 bg-slate-100 border border-slate-200 rounded-2xl text-xs text-slate-800 outline-none focus:ring-2 focus:ring-[#8B1D3B]/20"
        />
        <Search className="absolute right-3.5 top-3 w-4 h-4 text-slate-400" />
      </div>

      {/* Products Grid */}
      <div className="grid grid-cols-2 gap-3">
        {products.map((p) => {
          const inCart = cart[p.id] || 0;
          return (
            <div key={p.id} className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs flex flex-col justify-between p-2.5">
              <div className="relative h-32 bg-slate-50 rounded-xl overflow-hidden flex items-center justify-center">
                {p.main_image_url || (p.gallery && p.gallery[0]?.url) ? (
                  <img
                    src={p.main_image_url || p.gallery[0]?.url}
                    alt={p.name}
                    className="w-full h-full object-contain"
                  />
                ) : (
                  <ShoppingBag className="w-10 h-10 text-slate-300" />
                )}
                {p.discount_percent > 0 && (
                  <span className="absolute top-2 right-2 bg-rose-600 text-white text-[10px] font-black px-1.5 py-0.5 rounded-md">
                    خصم {p.discount_percent}%
                  </span>
                )}
              </div>
              <div className="mt-2 space-y-1">
                <p className="text-[10px] text-slate-400 font-bold">{p.vendor?.store_name || "متجر معتمد"}</p>
                <h3 className="text-xs font-bold text-slate-900 truncate">{p.name}</h3>
                <p className="text-xs font-black text-[#8B1D3B]">
                  {Number(p.effective_price || p.price).toLocaleString()} ر.ي
                </p>
              </div>
              <button
                onClick={() => setCart((prev) => ({ ...prev, [p.id]: (prev[p.id] || 0) + 1 }))}
                className="mt-2 w-full py-1.5 bg-[#8B1D3B] text-white rounded-xl text-xs font-bold flex items-center justify-center gap-1"
              >
                <span>أضف للسلة</span>
                {inCart > 0 && <span className="bg-white/20 px-1.5 rounded-full text-[10px]">({inCart})</span>}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export const AddressesScreen: React.FC<{ onBack?: () => void }> = ({ onBack }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center gap-2">
      <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
        <ArrowRight className="w-5 h-5" />
      </button>
      <h2 className="text-base font-bold">دفتر العناوين</h2>
    </div>
    <p className="text-xs text-slate-500">لا توجد عناوين مسجلة حالياً.</p>
  </div>
);

export const CategoriesFlutterScreen: React.FC<{ onBack?: () => void }> = ({ onBack }) => (
  <div className="p-4 space-y-4">
    <div className="flex items-center gap-2">
      <button onClick={onBack} className="p-2 rounded-full hover:bg-slate-100">
        <ArrowRight className="w-5 h-5" />
      </button>
      <h2 className="text-base font-bold">أقسام وتصنيفات المتجر</h2>
    </div>
    <p className="text-xs text-slate-500">تصفح كافة الأقسام المعتمدة.</p>
  </div>
);
