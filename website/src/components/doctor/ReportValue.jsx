import { toDate } from "../../lib/dashboardStats";
import { formatDate } from "../../lib/format";
import { prettyKey } from "../../lib/reportFiles";

// Turns any value from a report (text, number, date, list, nested object,
// or JSON saved as text) into readable labels and values instead of raw JSON.

const MAX_DEPTH = 4;

// Some apps save the AI analysis as a JSON *string*; open it up if so
function unwrap(value) {
  if (typeof value !== "string") return value;
  const t = value.trim();
  if (
    (t.startsWith("{") && t.endsWith("}")) ||
    (t.startsWith("[") && t.endsWith("]"))
  ) {
    try {
      return JSON.parse(t);
    } catch {
      return value;
    }
  }
  return value;
}

const isDate = (v) => v instanceof Date || typeof v?.toDate === "function"; // JS date or Firestore Timestamp
const isPlainObject = (v) =>
  v !== null && typeof v === "object" && !Array.isArray(v) && !isDate(v);
const isEmpty = (v) =>
  v === null ||
  v === undefined ||
  v === "" ||
  (Array.isArray(v) && v.length === 0);

// "high", "low", "abnormal"… get a coloured pill so problems stand out
const FLAG_STYLE = {
  high: "bg-red-50 text-red-700",
  low: "bg-amber-50 text-amber-700",
  abnormal: "bg-red-50 text-red-700",
  critical: "bg-red-100 text-red-800",
  borderline: "bg-amber-50 text-amber-700",
  normal: "bg-brand-50 text-brand-700",
  ok: "bg-brand-50 text-brand-700",
  good: "bg-brand-50 text-brand-700",
};
const flagStyle = (v) =>
  typeof v === "string" ? FLAG_STYLE[v.trim().toLowerCase()] : null;

function Simple({ value }) {
  if (isDate(value)) return <>{formatDate(toDate(value))}</>;
  if (typeof value === "boolean") return <>{value ? "Yes" : "No"}</>;
  const style = flagStyle(value);
  if (style)
    return (
      <span
        className={`rounded-md px-2 py-0.5 text-xs font-semibold capitalize ${style}`}
      >
        {value}
      </span>
    );
  return <>{String(value)}</>;
}

// A list of objects that all share the same keys (like lab test results) → a small table
function ObjectTable({ rows }) {
  const keys = [...new Set(rows.flatMap((r) => Object.keys(r)))].filter((k) =>
    rows.some((r) => !isEmpty(r[k])),
  );
  return (
    <div className="overflow-x-auto rounded-xl border border-black/5">
      <table className="w-full text-left text-xs">
        <thead className="bg-mist text-gray-500">
          <tr>
            {keys.map((k) => (
              <th key={k} className="px-3 py-2 font-medium">
                {prettyKey(k)}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-black/5">
          {rows.map((row, i) => (
            <tr key={i}>
              {keys.map((k) => (
                <td key={k} className="px-3 py-2 align-top font-medium">
                  {isEmpty(row[k]) ? (
                    <span className="text-gray-300">—</span>
                  ) : isPlainObject(row[k]) || Array.isArray(row[k]) ? (
                    <ReportValue value={row[k]} depth={MAX_DEPTH} />
                  ) : (
                    <Simple value={row[k]} />
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Nested object → indented label / value list
function ObjectList({ obj, depth }) {
  const entries = Object.entries(obj).filter(([, v]) => !isEmpty(v));
  if (entries.length === 0) return <span className="text-gray-400">—</span>;
  return (
    <dl
      className={`space-y-1.5 ${depth > 0 ? "border-l-2 border-black/5 pl-3" : ""}`}
    >
      {entries.map(([k, v]) => (
        <div key={k} className="text-sm">
          <dt className="text-xs text-gray-500">{prettyKey(k)}</dt>
          <dd className="font-medium break-words whitespace-pre-wrap">
            <ReportValue value={v} depth={depth + 1} />
          </dd>
        </div>
      ))}
    </dl>
  );
}

export default function ReportValue({ value: raw, depth = 0 }) {
  const value = unwrap(raw);

  if (isEmpty(value)) return <span className="text-gray-400">—</span>;
  if (depth > MAX_DEPTH)
    return <span className="text-gray-500">{JSON.stringify(value)}</span>; // very deep: stop

  if (Array.isArray(value)) {
    // list of results with the same shape → table
    if (value.every(isPlainObject)) return <ObjectTable rows={value} />;
    // list of words/numbers → chips
    if (value.every((v) => !isPlainObject(v) && !Array.isArray(v))) {
      return (
        <span className="flex flex-wrap gap-1.5">
          {value.map((v, i) => (
            <span
              key={i}
              className="rounded-full bg-mist px-2.5 py-0.5 text-xs font-medium"
            >
              <Simple value={v} />
            </span>
          ))}
        </span>
      );
    }
    return (
      <ol className="list-decimal space-y-1 pl-5">
        {value.map((v, i) => (
          <li key={i}>
            <ReportValue value={v} depth={depth + 1} />
          </li>
        ))}
      </ol>
    );
  }

  if (isPlainObject(value)) return <ObjectList obj={value} depth={depth} />;
  return <Simple value={value} />;
}
