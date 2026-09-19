// Small number card used on the Subscriptions and Scans pages
export default function MiniStat({
  icon: Icon,
  label,
  value,
  note,
  tint = "bg-brand-50 text-brand-700",
}) {
  return (
    <div className="rounded-3xl border border-black/5 bg-white p-5">
      <div className="flex items-start justify-between">
        <p className="text-sm text-gray-600">{label}</p>
        <span className={`grid h-9 w-9 place-items-center rounded-xl ${tint}`}>
          <Icon size={18} />
        </span>
      </div>
      <p className="mt-3 text-2xl font-bold tracking-tight">{value}</p>
      {note && <p className="mt-1 text-xs text-gray-500">{note}</p>}
    </div>
  );
}
