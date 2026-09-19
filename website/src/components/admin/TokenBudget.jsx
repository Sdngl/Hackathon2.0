import { Card, SampleTag } from "./ui";
import { tokenBudget } from "../../data/adminMock";

export default function TokenBudget() {
  const percent = ((tokenBudget.used / tokenBudget.total) * 100).toFixed(1);

  return (
    <Card title="AI Inference Token Budget" action={<SampleTag />}>
      <div className="mt-4 flex flex-wrap items-end justify-between gap-2">
        <p className="text-4xl font-bold tracking-tight">{percent}%</p>
        <p className="text-sm text-gray-500">
          {tokenBudget.used.toFixed(1)}M / {tokenBudget.total.toFixed(1)}M
          tokens used
        </p>
      </div>
      <div className="mt-4 h-3 rounded-full bg-gray-100">
        <div
          className="h-full rounded-full bg-violet-500"
          style={{ width: `${percent}%` }}
        />
      </div>
      <dl className="mt-5 divide-y divide-black/5 text-sm">
        {tokenBudget.breakdown.map(({ label, tokens }) => (
          <div key={label} className="flex justify-between py-2.5">
            <dt className="text-gray-600">{label}</dt>
            <dd className="font-semibold">{tokens} tokens</dd>
          </div>
        ))}
      </dl>
    </Card>
  );
}
