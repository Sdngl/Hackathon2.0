import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card } from "../admin/ui";

function Legend() {
  return (
    <div className="flex gap-4 text-xs text-gray-600">
      <span className="flex items-center gap-1.5">
        <span className="h-2 w-2 rounded-full bg-brand-700" />
        In-clinic
      </span>
      <span className="flex items-center gap-1.5">
        <span className="h-2 w-2 rounded-full bg-blue-500" />
        Video
      </span>
    </div>
  );
}

export default function WeekChart({ data }) {
  return (
    <Card
      title="Your week"
      subtitle="Appointments over the next 7 days"
      action={<Legend />}
    >
      <div className="mt-4 h-56">
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
              width={28}
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
            <Bar
              dataKey="clinic"
              name="In-clinic"
              stackId="a"
              fill="#0d6e57"
              maxBarSize={40}
            />
            <Bar
              dataKey="video"
              name="Video"
              stackId="a"
              fill="#3b82f6"
              radius={[6, 6, 0, 0]}
              maxBarSize={40}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}
