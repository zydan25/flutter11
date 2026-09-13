import React, { useState, useEffect } from "react";
import { Layers, Smartphone, RefreshCw, ExternalLink } from "lucide-react";

export function FlutterWebContainer({ onFallback }: { onFallback?: () => void }) {
  const [hasFlutterWeb, setHasFlutterWeb] = useState<boolean | null>(null);
  const [iframeKey, setIframeKey] = useState(0);

  useEffect(() => {
    // Check if flutter web build files exist
    fetch("/flutter_web/index.html", { method: "HEAD" })
      .then((res) => {
        if (res.ok) {
          setHasFlutterWeb(true);
        } else {
          // Check root as fallback
          fetch("/main.dart.js", { method: "HEAD" })
            .then((r) => setHasFlutterWeb(r.ok))
            .catch(() => setHasFlutterWeb(false));
        }
      })
      .catch(() => {
        setHasFlutterWeb(false);
      });
  }, []);

  if (hasFlutterWeb === false) {
    return (
      <div className="min-h-screen bg-[#0F172A] text-white flex flex-col items-center justify-center p-6 text-center" dir="rtl">
        <div className="w-20 h-20 rounded-3xl bg-rose-900/30 border border-rose-500/30 flex items-center justify-center mb-6 shadow-xl">
          <Smartphone className="w-10 h-10 text-rose-400" />
        </div>
        <h2 className="text-2xl font-black mb-3">نسخة Flutter Web بانتظار اكتمال البناء</h2>
        <p className="text-slate-300 max-w-md text-sm leading-relaxed mb-6">
          تم إنشاء Workflow في GitHub Actions لبناء كود الفلاتر تلقائياً. بعد اكتمال البناء، سيتم تشغيل تطبيق فلاتر الحقيقي هنا مباشرة.
        </p>

        <div className="flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => {
              setHasFlutterWeb(null);
              setIframeKey((k) => k + 1);
              fetch("/flutter_web/index.html", { method: "HEAD" }).then((r) => setHasFlutterWeb(r.ok));
            }}
            className="flex items-center justify-center gap-2 px-6 py-3 bg-[#8B1D3B] hover:bg-[#a32245] text-white font-bold rounded-xl transition shadow-lg shadow-rose-950/40"
          >
            <RefreshCw className="w-4 h-4" />
            <span>إعادة فحص نسخة Flutter</span>
          </button>

          {onFallback && (
            <button
              onClick={onFallback}
              className="flex items-center justify-center gap-2 px-6 py-3 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded-xl transition border border-slate-700"
            >
              <Layers className="w-4 h-4" />
              <span>عرض واجهة المعاينة الحالية</span>
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-screen bg-[#0F172A] flex flex-col items-center justify-center relative overflow-hidden" dir="rtl">
      {/* Phone Shell for Flutter Canvas */}
      <div className="w-full h-full max-w-md sm:h-[95vh] sm:rounded-3xl overflow-hidden shadow-2xl border border-slate-800 relative bg-black">
        <iframe
          key={iframeKey}
          src="/flutter_web/index.html"
          title="Flutter Web Live App"
          className="w-full h-full border-0 bg-transparent"
        />
      </div>
    </div>
  );
}
