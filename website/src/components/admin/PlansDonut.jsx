import { Cell, Pie, PieChart } from "recharts";
import { Card } from "./ui";

export default function PlansDonut({ plans, total }) {
  return (
    <Card title="Plus Plans Distribution">
      {plans.length === 0 ? (
        <p className="mt-10 text-center text-sm text-gray-500">
          No active Plus subscribers yet.
        </p>
      ) : (
        <div className="mt-6 flex flex-wrap items-center gap-8">
          <div className="relative h-36 w-36 shrink-0">
            <PieChart width={144} height={144}>
              <Pie
                data={plans}
                dataKey="count"
                innerRadius={52}
                outerRadius={68}
                startAngle={90}
                endAngle={-270}
                stroke="none"
              >
                {plans.map((p) => (
                  <Cell key={p.name} fill={p.color} />
                ))}
              </Pie>
            </PieChart>
            <div className="absolute inset-0 grid place-items-center text-center">
              <div>
                <p className="text-[10px] text-gray-500">Plus users</p>
                <p className="text-2xl font-bold">{total}</p>
              </div>
            </div>
          </div>

          <ul className="space-y-3">
            {plans.map((p) => (
              <li key={p.name} className="flex gap-2.5">
                <span
                  className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full"
                  style={{ background: p.color }}
                />
                <div className="leading-tight">
                  <p className="text-sm font-semibold">{p.name}</p>
                  <p className="text-xs text-gray-500">
                    {p.price
                      ? `Rs. ${Number(p.price).toLocaleString("en-IN")} · `
                      : ""}
                    {p.count} users ({p.share}%)
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </Card>
  );
}
