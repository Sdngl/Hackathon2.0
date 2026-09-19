import { useMemo, useState } from "react";
import { FileText } from "lucide-react";
import { useDoctor } from "../../context/DoctorContext";
import { Avatar, Card, StatusPill } from "../../components/admin/ui";
import Pagination from "../../components/admin/Pagination";
import SearchInput from "../../components/admin/SearchInput";
import ReportViewer from "../../components/doctor/ReportViewer";

const PAGE_SIZE = 10;

// /doctor/reports: every report patients have shared with this doctor
export default function DoctorReportsPage() {
  const { appointments } = useDoctor();
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [viewing, setViewing] = useState(null);

  const shared = useMemo(
    () =>
      appointments
        .filter((a) => a.reportId)
        .filter(
          (a) =>
            !search.trim() ||
            a.patient.toLowerCase().includes(search.trim().toLowerCase()),
        )
        .sort((a, b) => (b.bookedAt ?? 0) - (a.bookedAt ?? 0)), // newest first
    [appointments, search],
  );

  const pageCount = Math.max(1, Math.ceil(shared.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = shared.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  return (
    <Card
      title="Shared reports"
      subtitle="Reports patients chose to share when booking you"
      action={
        <Pagination page={current} pageCount={pageCount} onChange={setPage} />
      }
    >
      <div className="mt-4">
        <SearchInput
          value={search}
          onChange={(v) => {
            setSearch(v);
            setPage(1);
          }}
          placeholder="Search by patient…"
        />
      </div>
      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="border-b border-black/5 text-xs text-gray-500">
            <tr>
              {["Patient", "Shared on", "Appointment", "Status", ""].map(
                (h) => (
                  <th key={h} className="py-3 font-medium">
                    {h}
                  </th>
                ),
              )}
            </tr>
          </thead>
          <tbody className="divide-y divide-black/5">
            {visible.map((a) => (
              <tr key={a.path}>
                <td className="py-3">
                  <span className="flex items-center gap-3 font-semibold">
                    <Avatar name={a.patient} size="h-8 w-8" />
                    {a.patient}
                  </span>
                </td>
                <td className="text-gray-600">{a.bookedLabel ?? "—"}</td>
                <td className="text-gray-600">
                  {a.date ? `${a.dateLabel} · ${a.time}` : "Date not set"}
                </td>
                <td>
                  <StatusPill status={a.status} />
                </td>
                <td className="text-right">
                  <button
                    onClick={() => setViewing(a)}
                    className="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 hover:bg-blue-100"
                  >
                    <FileText size={13} /> View report
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {shared.length === 0 && (
          <p className="py-10 text-center text-sm text-gray-500">
            {search
              ? "No shared reports match your search."
              : "No reports shared with you yet. Patients can attach one when they book."}
          </p>
        )}
      </div>
      {viewing && (
        <ReportViewer appointment={viewing} onClose={() => setViewing(null)} />
      )}
    </Card>
  );
}
