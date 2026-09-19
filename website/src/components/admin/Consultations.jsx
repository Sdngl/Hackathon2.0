import { useMemo, useState } from "react";
import { Building, LoaderCircle, Video } from "lucide-react";
import { Avatar, Card, StatusPill } from "./ui";
import Pagination from "./Pagination";
import StatusModal from "./StatusModal";
import useAppointments from "../../hooks/useAppointments";
import { filterAppointments, mapAppointment } from "../../lib/appointments";

const FILTERS = [
  { key: "today", label: "Today" },
  { key: "upcoming", label: "Upcoming" },
  { key: "all", label: "All" },
];

export default function Consultations({
  users,
  doctors,
  initialFilter = "today",
  pageSize = 5,
  title = "Today's Scheduled Consultations",
}) {
  const { appointments, loading, error } = useAppointments();
  const [filter, setFilter] = useState(initialFilter);
  const [page, setPage] = useState(1);
  const [managing, setManaging] = useState(null); // the appointment open in the pop-up

  const list = useMemo(() => {
    const usersById = Object.fromEntries(users.map((u) => [u.id, u]));
    const doctorsById = Object.fromEntries(doctors.map((d) => [d.id, d]));
    const mapped = appointments.map((a) =>
      mapAppointment(a, usersById, doctorsById),
    );
    return filterAppointments(mapped, filter);
  }, [appointments, users, doctors, filter]);

  const pageCount = Math.max(1, Math.ceil(list.length / pageSize));
  const current = Math.min(page, pageCount);
  const visible = list.slice((current - 1) * pageSize, current * pageSize);

  function changeFilter(key) {
    setFilter(key);
    setPage(1);
  }

  return (
    <Card
      title={title}
      action={
        <div className="flex flex-wrap items-center justify-end gap-3">
          <Pagination page={current} pageCount={pageCount} onChange={setPage} />
          <div className="flex rounded-xl bg-mist p-1 text-xs font-semibold">
            {FILTERS.map((f) => (
              <button
                key={f.key}
                onClick={() => changeFilter(f.key)}
                className={`rounded-lg px-3 py-1.5 transition-colors ${filter === f.key ? "bg-white text-ink shadow-sm" : "text-gray-500 hover:text-ink"}`}
              >
                {f.label}
              </button>
            ))}
          </div>
        </div>
      }
    >
      {error ? (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          Couldn't load appointments: {error.message}
        </p>
      ) : loading ? (
        <div className="grid place-items-center py-10">
          <LoaderCircle className="animate-spin text-brand-700" />
        </div>
      ) : (
        <div className="mt-4 overflow-x-auto">
          <table className="w-full min-w-[760px] text-left text-sm">
            <thead className="border-b border-black/5 text-xs text-gray-500">
              <tr>
                {[
                  "Patient Name",
                  "Assigned Doctor",
                  filter === "today" ? "Time" : "Date & Time",
                  "Type",
                  "Status",
                  "Session",
                ].map((h) => (
                  <th
                    key={h}
                    className={`py-3 font-medium ${h === "Session" ? "text-right" : ""}`}
                  >
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
                        <Avatar name={a.patient} size="h-7 w-7" />
                        {a.patient}
                      </span>
                    </td>
                    <td className="text-gray-700">{a.doctor}</td>
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
            <p className="py-8 text-center text-sm text-gray-500">
              {filter === "today"
                ? "No consultations scheduled for today."
                : "No appointments found."}
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
