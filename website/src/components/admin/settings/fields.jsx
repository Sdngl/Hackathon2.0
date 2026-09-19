// Small form pieces shared by the settings sections

export const inputClass =
  "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100 disabled:bg-mist disabled:text-gray-500";

export function Field({ label, hint, children }) {
  return (
    <label className="block text-sm font-medium">
      {label}
      {children}
      {hint && (
        <span className="mt-1 block text-xs font-normal text-gray-500">
          {hint}
        </span>
      )}
    </label>
  );
}

// On/off row: label and description on the left, a switch on the right
export function SwitchRow({ label, hint, checked, onChange }) {
  return (
    <div className="flex items-center justify-between gap-4 py-3.5">
      <div>
        <p className="text-sm font-medium">{label}</p>
        {hint && <p className="text-xs text-gray-500">{hint}</p>}
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={() => onChange(!checked)}
        className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${checked ? "bg-brand-600" : "bg-gray-300"}`}
      >
        <span
          className={`absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${checked ? "translate-x-5" : ""}`}
        />
      </button>
    </div>
  );
}
