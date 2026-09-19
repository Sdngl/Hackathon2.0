import {
  Area,
  CartesianGrid,
  ComposedChart,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card } from "./ui";

function Legend() {
  return (
    <div className="flex gap-4 text-xs text-gray-600">
      <span className="flex items-center gap-1.5">
        <span className="h-2 w-2 rounded-full bg-brand-700" />
        Users
      </span>
      <span className="flex items-center gap-1.5">
        <span className="h-2 w-2 rounded-full bg-brand-500" />
        Plus
      </span>
    </div>
  );
}

export default function ActivityChart({ data }) {
  return (
    <Card
      title="User Growth"
      subtitle="Total users vs Plus subscribers over the last 30 days"
      action={<Legend />}
    >
      <div className="mt-4 h-60">
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart
            data={data}
            margin={{ top: 8, right: 4, left: 4, bottom: 0 }}
          >
            <CartesianGrid
              vertical={false}
              strokeDasharray="4 4"
              stroke="#e5e7eb"
            />
            <XAxis dataKey="day" hide />
            <YAxis hide allowDecimals={false} />
            <Tooltip
              contentStyle={{
                borderRadius: 12,
                border: "1px solid rgba(0,0,0,0.06)",
                fontSize: 12,
              }}
              labelStyle={{ fontWeight: 600 }}
            />
            <Area
              type="stepAfter"
              dataKey="users"
              fill="#e3f4ec"
              stroke="none"
              tooltipType="none"
            />
            <Line
              type="monotone"
              dataKey="users"
              name="Users"
              stroke="#0d6e57"
              strokeWidth={2}
              dot={false}
            />
            <Line
              type="monotone"
              dataKey="plus"
              name="Plus"
              stroke="#16a37f"
              strokeWidth={2}
              dot={false}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}
