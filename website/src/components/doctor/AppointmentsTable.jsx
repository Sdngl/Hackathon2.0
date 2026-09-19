import { useMemo, useState } from "react";
import { Building, CalendarPlus, FileText, Video } from "lucide-react";
import { Avatar, Card, StatusPill } from "../admin/ui";
import Pagination from "../admin/Pagination";
import Tabs from "../admin/Tabs";
import StatusModal from "../admin/StatusModal";
import ReportViewer from "./ReportViewer";
import ScheduleModal from "./ScheduleModal";
import { useDoctor } from "../../context/DoctorContext";
import { filterAppointments, needsDate } from "../../lib/appointments";

const FILTERS = [
  { key: "today", label: "Today" },
  { key: "upcoming", label: "Upcoming" },
  { key: "unscheduled", label: "Needs a date" },
  { key: "all", label: "All" },
];

function When({ a, today, onSchedule }) {
  if (needsDate(a)) {
    return (
      <span className="flex flex-col items-start gap-1">
        <button
          onClick={onSchedule}
          className="flex items-center gap-1.5 rounded-lg bg-amber-50 px-3 py-1.5 text-xs font-semibold text-amber-700 hover:bg-amber-100"
        >
          <CalendarPlus size={13} /> Set date &amp; time
        </button>
        {a.bookedLabel && (
          <span className="text-xs text-gray-400">
            Requested {a.bookedLabel}
          </span>
        )}
      </span>
    );
  }
  if (!a.date) return <span className="text-gray-400">No date</span>;
  return (
    <span className="group flex flex-col items-start">
      <span className="font-medium">
        {today ? a.time : `${a.dateLabel} · ${a.time}`}
      </span>
      <button
        onClick={onSchedule}
        className="text-xs text-gray-400 hover:text-brand-700 hover:underline"
      >
        Reschedule
      </button>
    </span>
  );
}

// This doctor's appointments with Today / Upcoming / All, shared reports and a Manage pop-up
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
  const [viewing, setViewing] = useState(null);
  const [scheduling, setScheduling] = useState(null);
  const { doctor } = useDoctor();

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
          <table className="w-full min-w-[760px] text-left text-sm">
            <thead className="border-b border-black/5 text-xs text-gray-500">
              <tr>
                {[
                  "Patient",
                  filter === "today" ? "Time" : "Date & time",
                  "Type",
                  "Report",
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
                    <td className="py-2">
                      <When
                        a={a}
                        today={filter === "today"}
                        onSchedule={() => setScheduling(a)}
                      />
                    </td>
                    <td className="text-gray-600">
                      <span className="flex items-center gap-2">
                        <TypeIcon size={15} />
                        {a.type}
                      </span>
                    </td>
                    <td>
                      {a.reportId ? (
                        <button
                          onClick={() => setViewing(a)}
                          className="flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 hover:bg-blue-100"
                        >
                          <FileText size={13} /> View report
                        </button>
                      ) : (
                        <span className="text-xs text-gray-400">
                          None shared
                        </span>
                      )}
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
                : filter === "unscheduled"
                  ? "No requests waiting for a date."
                  : "No appointments here yet."}
            </p>
          )}
        </div>
      )}
      {managing && (
        <StatusModal appointment={managing} onClose={() => setManaging(null)} />
      )}
      {viewing && (
        <ReportViewer appointment={viewing} onClose={() => setViewing(null)} />
      )}
      {scheduling && (
        <ScheduleModal
          appointment={scheduling}
          slots={
            Array.isArray(doctor.availableSlots) ? doctor.availableSlots : []
          }
          onClose={() => setScheduling(null)}
        />
      )}
    </Card>
  );
}
