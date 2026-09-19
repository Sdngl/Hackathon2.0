// Segmented control: [ Today | This week | This month ]
export default function Tabs({ tabs, value, onChange }) {
  return (
    <div className="flex w-fit flex-wrap rounded-xl bg-mist p-1 text-xs font-semibold">
      {tabs.map((t) => (
        <button
          key={t.key}
          onClick={() => onChange(t.key)}
          className={`rounded-lg px-3 py-1.5 transition-colors ${value === t.key ? "bg-white text-ink shadow-sm" : "text-gray-500 hover:text-ink"}`}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}
