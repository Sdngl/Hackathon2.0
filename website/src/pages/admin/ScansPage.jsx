import { useMemo, useState } from "react";
import { Link } from "react-router";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  CircleAlert,
  FileText,
  LoaderCircle,
  Pill,
  ScanLine,
  Users,
  UtensilsCrossed,
} from "lucide-react";
import useScans from "../../hooks/useScans";
import useCollection from "../../hooks/useCollection";
import { Avatar, Card } from "../../components/admin/ui";
import MiniStat from "../../components/admin/MiniStat";
import Tabs from "../../components/admin/Tabs";
import TokenBudget from "../../components/admin/TokenBudget";
import {
  RANGES,
  countByType,
  inRange,
  limitHitsToday,
  scansPerDay,
  topScanners,
} from "../../lib/scans";

const TYPES = [
  {
    key: "medicines",
    label: "Medicine Strips",
    icon: Pill,
    color: "#f59e0b",
    text: "text-amber-500",
    bar: "bg-amber-500",
  },
  {
    key: "meals",
    label: "Meal Log Plates",
    icon: UtensilsCrossed,
    color: "#f43f5e",
    text: "text-rose-500",
    bar: "bg-rose-500",
  },
  {
    key: "reports",
    label: "Lab Reports",
    icon: FileText,
    color: "#2563eb",
    text: "text-blue-600",
    bar: "bg-blue-600",
  },
];

function WeeklyChart({ data }) {
  return (
    <Card
      title="Scans this week"
      subtitle="Daily uploads over the last 7 days"
      action={
        <div className="flex flex-wrap gap-3 text-xs text-gray-600">
          {TYPES.map((t) => (
            <span key={t.key} className="flex items-center gap-1.5">
              <span
                className="h-2 w-2 rounded-full"
                style={{ background: t.color }}
              />
              {t.label.split(" ")[0]}
            </span>
          ))}
        </div>
      }
    >
      <div className="mt-4 h-72">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={data}
            margin={{ top: 8, right: 0, left: 0, bottom: 0 }}
          >
            <CartesianGrid
              vertical={false}
              strokeDasharray="4 4"
              stroke="#e5e7eb"
            />
            <XAxis
              dataKey="day"
              tickLine={false}
              axisLine={false}
              fontSize={12}
              tick={{ fill: "#6b7280" }}
            />
            <YAxis
              allowDecimals={false}
              tickLine={false}
              axisLine={false}
              fontSize={11}
              width={32}
              tick={{ fill: "#6b7280" }}
            />
            <Tooltip
              cursor={{ fill: "#f4f6f5" }}
              contentStyle={{
                borderRadius: 12,
                border: "1px solid rgba(0,0,0,0.06)",
                fontSize: 12,
              }}
            />
            {TYPES.map((t, i) => (
              <Bar
                key={t.key}
                dataKey={t.key}
                name={t.label}
                stackId="scans"
                fill={t.color}
                radius={i === TYPES.length - 1 ? [6, 6, 0, 0] : 0}
                maxBarSize={44}
              />
            ))}
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}

function Breakdown({ counts, range, setRange, limitHits }) {
  const max = Math.max(1, ...Object.values(counts)) * 1.25;
  const label = RANGES.find((r) => r.key === range).label.toLowerCase();

  return (
    <Card
      title="Scans uploaded"
      action={<Tabs tabs={RANGES} value={range} onChange={setRange} />}
    >
      <ul className="mt-5 space-y-5">
        {TYPES.map(({ key, label: name, icon: Icon, text, bar }) => (
          <li key={key}>
            <div className="flex items-center justify-between text-sm font-semibold">
              <span className="flex items-center gap-2">
                <Icon size={16} className={text} />
                {name}
              </span>
              <span>{counts[key]} scans</span>
            </div>
            <div className="mt-2 h-2 rounded-full bg-gray-100">
              <div
                className={`h-full rounded-full transition-all ${bar}`}
                style={{ width: `${(counts[key] / max) * 100}%` }}
              />
            </div>
          </li>
        ))}
      </ul>
      {range === "today" ? (
        <p className="mt-6 flex items-center gap-2 rounded-xl bg-amber-50 px-4 py-3 text-xs font-medium text-amber-700">
          <CircleAlert size={15} />
          {limitHits} free-tier user{limitHits !== 1 && "s"} hit the 5-scan
          daily limit today.
        </p>
      ) : (
        <p className="mt-6 text-xs text-gray-500">
          Showing {label}. Switch to Today to see free-tier limit hits.
        </p>
      )}
    </Card>
  );
}

function TopScanners({ rows }) {
  return (
    <Card title="Most active scanners">
      {rows.length === 0 ? (
        <p className="mt-8 text-center text-sm text-gray-500">
          No scans in this period.
        </p>
      ) : (
        <ul className="mt-4 divide-y divide-black/5">
          {rows.map((r, i) => (
            <li key={r.userId} className="flex items-center gap-3 py-3">
              <span className="w-4 text-xs font-bold text-gray-400">
                {i + 1}
              </span>
              <Avatar
                name={r.user?.displayName || "?"}
                photo={r.user?.photoUrl}
                size="h-8 w-8"
              />
              <Link
                to={`/admin/users/${r.userId}`}
                className="min-w-0 flex-1 truncate text-sm font-semibold hover:text-brand-700 hover:underline"
              >
                {r.user?.displayName || r.user?.email || "Unknown user"}
              </Link>
              <span className="hidden text-xs text-gray-500 sm:block">
                {r.medicines} med · {r.meals} meal · {r.reports} report
              </span>
              <span className="text-sm font-bold">{r.total}</span>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

// /admin/scans
export default function ScansPage() {
  const { scans, loading, error } = useScans(30);
  const { data: users } = useCollection("users");
  const [range, setRange] = useState("week");

  const weekly = useMemo(() => scansPerDay(scans, 7), [scans]);
  const ranged = useMemo(() => inRange(scans, range), [scans, range]);
  const counts = useMemo(() => countByType(ranged), [ranged]);
  const top = useMemo(() => topScanners(ranged, users), [ranged, users]);
  const limitHits = useMemo(() => limitHitsToday(scans, users), [scans, users]);
  const scanners = new Set(ranged.map((s) => s.userId)).size;

  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load scans: {error.message}
      </p>
    );
  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold tracking-tight">
          Scans &amp; AI Usage
        </h1>
        <p className="mt-0.5 text-sm text-gray-500">
          The numbers below follow the Today / This week / This month switch.
        </p>
      </div>

      <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <MiniStat
          icon={ScanLine}
          label="Total scans"
          value={ranged.length}
          note={RANGES.find((r) => r.key === range).label}
        />
        <MiniStat
          icon={Users}
          label="Users scanning"
          value={scanners}
          note={
            scanners
              ? `${(ranged.length / scanners).toFixed(1)} scans per user`
              : "No scans yet"
          }
          tint="bg-blue-50 text-blue-600"
        />
        <MiniStat
          icon={Pill}
          label="Medicines"
          value={counts.medicines}
          tint="bg-amber-50 text-amber-600"
        />
        <MiniStat
          icon={FileText}
          label="Lab reports"
          value={counts.reports}
          note={`${counts.meals} meals`}
          tint="bg-violet-50 text-violet-600"
        />
      </div>

      <WeeklyChart data={weekly} />

      <div className="grid gap-5 xl:grid-cols-2">
        <Breakdown
          counts={counts}
          range={range}
          setRange={setRange}
          limitHits={limitHits}
        />
        <TopScanners rows={top} />
      </div>

      <TokenBudget />
    </div>
  );
}
