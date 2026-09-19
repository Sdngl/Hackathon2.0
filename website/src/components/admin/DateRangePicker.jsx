import { useEffect, useRef, useState } from "react";
import { Calendar, Check, ChevronDown } from "lucide-react";
import { useAdmin } from "../../context/AdminContext";

const OPTIONS = [7, 30, 90];

// "Last 30 days" button in the top bar. Changes the period on the Overview
// (revenue card + growth chart) and on Subscriptions & Revenue.
export default function DateRangePicker() {
  const { rangeDays, setRangeDays } = useAdmin();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  // close when clicking anywhere else
  useEffect(() => {
    if (!open) return;
    const onClick = (e) => !ref.current?.contains(e.target) && setOpen(false);
    const onKey = (e) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        className="flex items-center gap-2 rounded-xl border border-black/10 px-4 py-2.5 text-sm font-semibold hover:bg-mist"
      >
        <Calendar size={16} /> Last {rangeDays} days{" "}
        <ChevronDown size={14} className="text-gray-400" />
      </button>

      {open && (
        <ul className="absolute right-0 z-30 mt-2 w-44 rounded-2xl border border-black/5 bg-white p-1.5 shadow-xl">
          {OPTIONS.map((days) => (
            <li key={days}>
              <button
                onClick={() => {
                  setRangeDays(days);
                  setOpen(false);
                }}
                className="flex w-full items-center justify-between rounded-xl px-3 py-2 text-sm hover:bg-mist"
              >
                Last {days} days
                {days === rangeDays && (
                  <Check size={15} className="text-brand-700" />
                )}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
