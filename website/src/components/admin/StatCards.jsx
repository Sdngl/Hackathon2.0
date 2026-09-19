import { CreditCard, Stethoscope, Users, Wallet } from "lucide-react";

const npr = (n) => `Rs. ${n.toLocaleString("en-IN")}`;

export default function StatCards({ userStats, doctorStats }) {
  const cards = [
    {
      label: "Daily Active Users",
      value: userStats.activeToday.toLocaleString("en-IN"),
      note: `of ${userStats.totalUsers} users`,
      icon: Users,
      tint: "bg-brand-50 text-brand-700",
    },
    {
      label: "Plus Subscribers",
      value: userStats.plusCount.toLocaleString("en-IN"),
      note: "Active",
      noteStyle: "bg-violet-50 text-violet-600",
      icon: CreditCard,
      tint: "bg-blue-50 text-blue-600",
    },
    {
      label: "Revenue (30 days)",
      value: npr(userStats.revenue),
      note: `${userStats.paymentsCount} payments`,
      icon: Wallet,
      tint: "bg-red-50 text-red-500",
    },
    {
      label: "Active Doctors",
      value: `${doctorStats.active} / ${doctorStats.total}`,
      note: `${doctorStats.available} available`,
      noteStyle: "bg-amber-50 text-amber-600",
      icon: Stethoscope,
      tint: "bg-amber-50 text-amber-600",
    },
  ];

  return (
    <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map(({ label, value, note, noteStyle, icon: Icon, tint }) => (
        <div
          key={label}
          className="rounded-3xl border border-black/5 bg-white p-5"
        >
          <div className="flex items-start justify-between">
            <p className="text-sm text-gray-600">{label}</p>
            <span
              className={`grid h-9 w-9 place-items-center rounded-xl ${tint}`}
            >
              <Icon size={18} />
            </span>
          </div>
          <div className="mt-3 flex flex-wrap items-center gap-2">
            <p className="text-2xl font-bold tracking-tight xl:text-[1.7rem]">
              {value}
            </p>
            <span
              className={`rounded-full px-2 py-0.5 text-xs font-semibold ${noteStyle ?? "bg-brand-50 text-brand-700"}`}
            >
              {note}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}
