import React, { useEffect, useState } from "react";
import { BellRing, X, CheckCircle, ArrowLeft, ShieldAlert } from "lucide-react";

export interface HeadsUpNotificationData {
  id: string | number;
  title: string;
  body: string;
  type?: "success" | "warning" | "info" | "order" | "transaction";
  importance?: "IMPORTANCE_HIGH" | "PRIORITY_MAX";
  channelName?: string;
  onAction?: () => void;
  actionLabel?: string;
}

// Global notification trigger event system
type NotificationListener = (data: HeadsUpNotificationData) => void;
const listeners: Set<NotificationListener> = new Set();

export function triggerHeadsUpNotification(data: Omit<HeadsUpNotificationData, "id"> & { id?: string | number }) {
  const fullData: HeadsUpNotificationData = {
    id: data.id || `notif-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    channelName: data.channelName || "قناة إشعارات شبيك الفورية (Heads-up)",
    importance: data.importance || "IMPORTANCE_HIGH",
    ...data,
  };

  // 1. Play sound chime via Web Audio API
  try {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (AudioContextClass) {
      const ctx = new AudioContextClass();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
      osc.frequency.setValueAtTime(880, ctx.currentTime + 0.08); // A5
      osc.frequency.setValueAtTime(1174.66, ctx.currentTime + 0.16); // D6
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.42);
    }
  } catch {}

  // 2. Trigger hardware vibration if supported (standard for heads-up alerts)
  try {
    if ("vibrate" in navigator) {
      navigator.vibrate([250, 100, 250]);
    }
  } catch {}

  // 3. Trigger browser native notification if permitted
  try {
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification(fullData.title, {
        body: fullData.body,
        icon: "/icon.png",
        badge: "/icon.png",
        tag: `heads-up-${fullData.id}`,
        requireInteraction: true,
      });
    }
  } catch {}

  // 4. Notify in-app UI listeners
  listeners.forEach((l) => l(fullData));
}

export const HeadsUpNotificationContainer: React.FC = () => {
  const [activeNotifications, setActiveNotifications] = useState<HeadsUpNotificationData[]>([]);

  useEffect(() => {
    // Request permission once quietly
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission().catch(() => {});
    }

    const handler: NotificationListener = (notif) => {
      setActiveNotifications((prev) => [notif, ...prev.slice(0, 2)]);
    };

    listeners.add(handler);
    return () => {
      listeners.delete(handler);
    };
  }, []);

  const dismiss = (id: string | number) => {
    setActiveNotifications((prev) => prev.filter((n) => n.id !== id));
  };

  if (activeNotifications.length === 0) return null;

  return (
    <div className="fixed top-3 inset-x-3 z-50 flex flex-col items-center pointer-events-none max-w-md mx-auto space-y-2" dir="rtl">
      {activeNotifications.map((notif) => (
        <HeadsUpCard key={notif.id} notif={notif} onDismiss={() => dismiss(notif.id)} />
      ))}
    </div>
  );
};

interface HeadsUpCardProps {
  notif: HeadsUpNotificationData;
  onDismiss: () => void;
}

const HeadsUpCard: React.FC<HeadsUpCardProps> = ({ notif, onDismiss }) => {
  const [progress, setProgress] = useState(100);

  useEffect(() => {
    const duration = 6500;
    const intervalTime = 50;
    const step = (intervalTime / duration) * 100;

    const timer = setInterval(() => {
      setProgress((p) => {
        if (p <= step) {
          clearInterval(timer);
          onDismiss();
          return 0;
        }
        return p - step;
      });
    }, intervalTime);

    return () => clearInterval(timer);
  }, [onDismiss]);

  const isSuccess = notif.type === "success" || notif.type === "order" || notif.type === "transaction";

  return (
    <div className="pointer-events-auto w-full bg-slate-900/95 text-white rounded-2xl p-3.5 shadow-2xl border border-slate-700/80 backdrop-blur-md animate-in slide-in-from-top-4 fade-in duration-200 transition-all">
      {/* Top Channel & Priority Header */}
      <div className="flex items-center justify-between text-[10px] text-slate-400 mb-1.5 pb-1 border-b border-slate-800">
        <div className="flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
          <span className="font-mono font-bold text-rose-400">PRIORITY_MAX</span>
          <span>•</span>
          <span className="font-semibold text-slate-300">{notif.channelName}</span>
        </div>
        <button
          onClick={onDismiss}
          className="text-slate-400 hover:text-white p-0.5 rounded-full hover:bg-slate-800 transition"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Main Body */}
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#8B1D3B] to-[#991B1B] p-0.5 shrink-0 flex items-center justify-center shadow-xs overflow-hidden">
          <img
            src="/icon.png"
            alt="شبيك"
            className="w-full h-full object-cover rounded-[10px]"
            onError={(e) => {
              (e.target as HTMLImageElement).style.display = "none";
            }}
          />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5">
            <h4 className="text-xs font-black text-white truncate">{notif.title}</h4>
            {isSuccess && <CheckCircle className="w-3.5 h-3.5 text-emerald-400 shrink-0" />}
          </div>
          <p className="text-[11px] text-slate-300 font-medium leading-relaxed mt-0.5 line-clamp-2">
            {notif.body}
          </p>

          {/* Action button if provided */}
          {notif.onAction && (
            <div className="mt-2 flex items-center gap-2">
              <button
                onClick={() => {
                  notif.onAction?.();
                  onDismiss();
                }}
                className="bg-[#8B1D3B] hover:bg-[#a02245] text-white px-3 py-1 rounded-full text-[10px] font-black flex items-center gap-1 transition active:scale-95 shadow-xs"
              >
                <span>{notif.actionLabel || "عرض التفاصيل"}</span>
                <ArrowLeft className="w-3 h-3" />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Progress Bar (Auto Dismiss) */}
      <div className="w-full bg-slate-800 h-1 rounded-full overflow-hidden mt-2.5">
        <div
          className="bg-gradient-to-r from-rose-500 to-amber-400 h-full transition-all duration-75"
          style={{ width: `${progress}%` }}
        />
      </div>
    </div>
  );
};
