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
  CalendarClock,
  CircleAlert,
  Crown,
  LoaderCircle,
  Repeat,
  TrendingUp,
  Wallet,
} from "lucide-react";
import useCollection from "../../hooks/useCollection";
import { useAdmin } from "../../context/AdminContext";
import { Avatar, Card } from "../../components/admin/ui";
import MiniStat from "../../components/admin/MiniStat";
import Pagination from "../../components/admin/Pagination";
import Tabs from "../../components/admin/Tabs";
import {
  dailyRevenue,
  getRevenueStats,
  planTable,
  subscriptionRows,
} from "../../lib/Revenue";
import { formatDate, npr } from "../../lib/format";

const PAGE_SIZE = 10;
const STATE_TABS = [
  { key: "all", label: "All" },
  { key: "Active", label: "Active" },
  { key: "Expiring", label: "Expiring soon" },
  { key: "Cancelling", label: "Cancelling" },
  { key: "Expired", label: "Expired" },
];
const stateStyle = {
  Active: "bg-brand-50 text-brand-700",
  Expiring: "bg-amber-50 text-amber-600",
  Cancelling: "bg-orange-50 text-orange-600",
  Expired: "bg-red-50 text-red-600",
};

function RevenueChart({ data, days }) {
  return (
    <Card
      title="Daily revenue"
      subtitle={`New subscriptions over the last ${days} days`}
    >
      <div className="mt-4 h-64">
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
              fontSize={11}
              interval={Math.max(0, Math.ceil(days / 7) - 1)}
              tick={{ fill: "#6b7280" }}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              fontSize={11}
              width={56}
              tick={{ fill: "#6b7280" }}
              tickFormatter={(v) => (v >= 1000 ? `${v / 1000}k` : v)}
            />
            <Tooltip
              cursor={{ fill: "#f4f6f5" }}
              contentStyle={{
                borderRadius: 12,
                border: "1px solid rgba(0,0,0,0.06)",
                fontSize: 12,
              }}
              formatter={(value, _name, item) => [
                `${npr(value)} · ${item.payload.count} new`,
                "Revenue",
              ]}
            />
            <Bar
              dataKey="revenue"
              fill="#16a37f"
              radius={[6, 6, 0, 0]}
              maxBarSize={28}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}

function PlansCard({ plans }) {
  return (
    <Card title="Plans">
      {plans.length === 0 ? (
        <p className="mt-8 text-center text-sm text-gray-500">
          No paid subscriptions yet.
        </p>
      ) : (
        <ul className="mt-4 divide-y divide-black/5">
          {plans.map((p) => (
            <li
              key={p.name}
              className="flex items-center justify-between gap-4 py-3"
            >
              <div>
                <p className="text-sm font-semibold">{p.name}</p>
                <p className="text-xs text-gray-500">
                  {npr(p.price)}
                  {p.months
                    ? ` for ${p.months} month${p.months > 1 ? "s" : ""}`
                    : ""}{" "}
                  · {p.active} active of {p.total}
                </p>
              </div>
              <p className="text-sm font-bold">{npr(p.revenue)}</p>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

// /admin/subscriptions
export default function SubscriptionsPage() {
  const { data: users, loading, error } = useCollection("users");
  const { rangeDays } = useAdmin(); // from the date picker in the top bar
  const [includeTest, setIncludeTest] = useState(true);
  const [state, setState] = useState("all");
  const [page, setPage] = useState(1);

  const stats = useMemo(
    () => getRevenueStats(users, includeTest, rangeDays),
    [users, includeTest, rangeDays],
  );
  const chart = useMemo(
    () => dailyRevenue(users, includeTest, rangeDays),
    [users, includeTest, rangeDays],
  );
  const plans = useMemo(
    () => planTable(users, includeTest),
    [users, includeTest],
  );
  const rows = useMemo(
    () => subscriptionRows(users, includeTest, state),
    [users, includeTest, state],
  );

  const pageCount = Math.max(1, Math.ceil(rows.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = rows.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load subscriptions: {error.message}
      </p>
    );

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold tracking-tight">
          Subscriptions &amp; Revenue
        </h1>
        <label className="flex cursor-pointer items-center gap-2.5 rounded-xl border border-black/10 bg-white px-3.5 py-2 text-sm">
          <input
            type="checkbox"
            checked={includeTest}
            onChange={(e) => setIncludeTest(e.target.checked)}
            className="h-4 w-4 accent-brand-700"
          />
          Include test payments
        </label>
      </div>

      <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <MiniStat
          icon={Wallet}
          label="Today's revenue"
          value={npr(stats.today)}
          note={`${stats.todayCount} new subscription${stats.todayCount !== 1 ? "s" : ""} today`}
        />
        <MiniStat
          icon={TrendingUp}
          label={`Last ${rangeDays} days`}
          value={npr(stats.period)}
          note={`${stats.periodCount} subscriptions · ${npr(stats.lifetime)} all time`}
          tint="bg-blue-50 text-blue-600"
        />
        <MiniStat
          icon={Repeat}
          label="Monthly recurring (MRR)"
          value={npr(stats.mrr)}
          note="Active plans spread per month"
          tint="bg-violet-50 text-violet-600"
        />
        <MiniStat
          icon={Crown}
          label="Active Plus"
          value={stats.active}
          note={`${stats.conversion}% of all users`}
          tint="bg-amber-50 text-amber-600"
        />
      </div>

      {(stats.expiring > 0 || stats.cancelling > 0) && (
        <div className="flex flex-wrap gap-3">
          {stats.expiring > 0 && (
            <button
              onClick={() => {
                setState("Expiring");
                setPage(1);
              }}
              className="flex items-center gap-2 rounded-xl bg-amber-50 px-4 py-2.5 text-sm font-medium text-amber-700"
            >
              <CalendarClock size={16} />{" "}
              {stats.expiring === 1
                ? "1 subscription expires"
                : `${stats.expiring} subscriptions expire`}{" "}
              within 7 days
            </button>
          )}
          {stats.cancelling > 0 && (
            <button
              onClick={() => {
                setState("Cancelling");
                setPage(1);
              }}
              className="flex items-center gap-2 rounded-xl bg-orange-50 px-4 py-2.5 text-sm font-medium text-orange-700"
            >
              <CircleAlert size={16} /> {stats.cancelling} set to cancel at
              period end
            </button>
          )}
        </div>
      )}

      <div className="grid gap-5 xl:grid-cols-[1.6fr_1fr]">
        <RevenueChart data={chart} days={rangeDays} />
        <PlansCard plans={plans} />
      </div>

      <Card
        title="Subscriptions"
        action={
          <Pagination page={current} pageCount={pageCount} onChange={setPage} />
        }
      >
        <div className="mt-4">
          <Tabs
            tabs={STATE_TABS}
            value={state}
            onChange={(key) => {
              setState(key);
              setPage(1);
            }}
          />
        </div>
        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[820px] text-left text-sm">
            <thead className="border-b border-black/5 text-xs text-gray-500">
              <tr>
                {[
                  "User",
                  "Plan",
                  "Amount",
                  "Started",
                  "Expires",
                  "Paid with",
                  "Status",
                ].map((h) => (
                  <th key={h} className="py-3 font-medium">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {visible.map((u) => (
                <tr key={u.id}>
                  <td className="py-3">
                    <Link
                      to={`/admin/users/${u.id}`}
                      className="group flex items-center gap-3"
                    >
                      <Avatar
                        name={u.displayName || u.email || "?"}
                        photo={u.photoUrl}
                        size="h-8 w-8"
                      />
                      <span className="font-semibold group-hover:text-brand-700 group-hover:underline">
                        {u.displayName || u.email}
                      </span>
                    </Link>
                  </td>
                  <td className="text-gray-600">
                    {u.subscriptionTitle ?? u.subscriptionPlan ?? "—"}
                  </td>
                  <td className="font-medium">{npr(u.subscriptionPrice)}</td>
                  <td className="text-gray-600">
                    {formatDate(u.subscriptionStartedAt)}
                  </td>
                  <td className="text-gray-600">
                    {formatDate(u.subscriptionExpiresAt)}
                  </td>
                  <td className="text-gray-600 capitalize">
                    {u.paymentProvider ?? "—"}
                    {u.paymentMode === "test" && (
                      <span className="ml-1.5 rounded bg-gray-100 px-1.5 py-0.5 text-[10px] font-semibold text-gray-500 normal-case">
                        test
                      </span>
                    )}
                  </td>
                  <td>
                    <span
                      className={`rounded-md px-2 py-0.5 text-xs font-semibold ${stateStyle[u.state]}`}
                    >
                      {u.state === "Expiring" ? "Expiring soon" : u.state}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length === 0 && (
            <p className="py-10 text-center text-sm text-gray-500">
              No subscriptions here.
            </p>
          )}
        </div>
      </Card>
    </div>
  );
}
