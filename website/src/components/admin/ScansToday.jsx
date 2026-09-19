import { CircleAlert, FileText, Pill, UtensilsCrossed } from "lucide-react";
import { Card } from "./ui";

const rows = [
  {
    key: "medicines",
    label: "Medicine Strips",
    icon: Pill,
    color: "text-amber-500",
    bar: "bg-amber-500",
  },
  {
    key: "meals",
    label: "Meal Log Plates",
    icon: UtensilsCrossed,
    color: "text-orange-500",
    bar: "bg-orange-400",
  },
  {
    key: "reports",
    label: "Lab Reports",
    icon: FileText,
    color: "text-blue-600",
    bar: "bg-blue-600",
  },
];

export default function ScansToday({ stats, error }) {
  const max = Math.max(1, ...Object.values(stats.counts)) * 1.25;

  return (
    <Card title="Scans Uploaded Today">
      <ul className="mt-5 space-y-5">
        {rows.map(({ key, label, icon: Icon, color, bar }) => {
          const count = stats.counts[key] ?? 0;
          return (
            <li key={key}>
              <div className="flex items-center justify-between text-sm font-semibold">
                <span className="flex items-center gap-2">
                  <Icon size={16} className={color} />
                  {label}
                </span>
                <span>{count} scans</span>
              </div>
              <div className="mt-2 h-2 rounded-full bg-gray-100">
                <div
                  className={`h-full rounded-full ${bar}`}
                  style={{ width: `${(count / max) * 100}%` }}
                />
              </div>
            </li>
          );
        })}
      </ul>

      {error ? (
        <p className="mt-6 rounded-xl bg-red-50 px-4 py-3 text-xs text-red-700">
          Couldn't load scans: {error.message}
        </p>
      ) : (
        <p className="mt-6 flex items-center gap-2 rounded-xl bg-amber-50 px-4 py-3 text-xs font-medium text-amber-700">
          <CircleAlert size={15} />
          {stats.limitHitUsers} free-tier users have hit their 5-scan daily
          limit today.
        </p>
      )}
    </Card>
  );
}
