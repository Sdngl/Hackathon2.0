import { useMemo, useState } from "react";
import { Building, Video } from "lucide-react";
import { Avatar, Card, StatusPill } from "../admin/ui";
import Pagination from "../admin/Pagination";
import Tabs from "../admin/Tabs";
import StatusModal from "../admin/StatusModal";
import { filterAppointments } from "../../lib/appointments";

const FILTERS = [
  { key: "today", label: "Today" },
  { key: "upcoming", label: "Upcoming" },
  { key: "all", label: "All" },
];

// This doctor's appointments with Today / Upcoming / All and a Manage pop-up
export default function AppointmentsTable({
  appointments,
  initialFilter = "today",
  pageSize = 5,
  title = "Today's schedule",
  error,
}) {
  const [filter, setFilter] = useState(initialFilter);
  const [page, setPage] = useState(1);
  const [managing, setManaging] = useState(null);

  const list = useMemo(
    () => filterAppointments([...appointments], filter),
    [appointments, filter],
  );
  const pageCount = Math.max(1, Math.ceil(list.length / pageSize));
  const current = Math.min(page, pageCount);
  const visible = list.slice((current - 1) * pageSize, current * pageSize);

  return (
    <Card
      title={title}
      action={
        <div className="flex flex-wrap items-center justify-end gap-3">
          <Pagination page={current} pageCount={pageCount} onChange={setPage} />
          <Tabs
            tabs={FILTERS}
            value={filter}
            onChange={(k) => {
              setFilter(k);
              setPage(1);
            }}
          />
        </div>
      }
    >
      {error ? (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm break-words text-red-700">
          Couldn't load appointments: {error.message}
        </p>
      ) : (
        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="border-b border-black/5 text-xs text-gray-500">
              <tr>
                {[
                  "Patient",
                  filter === "today" ? "Time" : "Date & time",
                  "Type",
                  "Status",
                  "",
                ].map((h) => (
                  <th key={h} className="py-3 font-medium">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {visible.map((a) => {
                const TypeIcon = a.type.toLowerCase().includes("video")
                  ? Video
                  : Building;
                return (
                  <tr key={a.path}>
                    <td className="py-3">
                      <span className="flex items-center gap-3 font-semibold">
                        <Avatar name={a.patient} size="h-8 w-8" />
                        {a.patient}
                      </span>
                    </td>
                    <td className="font-medium">
                      {filter === "today"
                        ? a.time
                        : `${a.dateLabel} · ${a.time}`}
                    </td>
                    <td className="text-gray-600">
                      <span className="flex items-center gap-2">
                        <TypeIcon size={15} />
                        {a.type}
                      </span>
                    </td>
                    <td>
                      <StatusPill status={a.status} />
                    </td>
                    <td className="text-right">
                      <button
                        onClick={() => setManaging(a)}
                        className="rounded-lg border border-black/10 px-4 py-1.5 text-xs font-semibold hover:bg-mist"
                      >
                        Manage
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {list.length === 0 && (
            <p className="py-10 text-center text-sm text-gray-500">
              {filter === "today"
                ? "No appointments today."
                : "No appointments here yet."}
            </p>
          )}
        </div>
      )}
      {managing && (
        <StatusModal appointment={managing} onClose={() => setManaging(null)} />
      )}
    </Card>
  );
}
