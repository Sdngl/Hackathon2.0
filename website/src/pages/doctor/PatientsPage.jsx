import { useMemo, useState } from "react";
import { useDoctor } from "../../context/DoctorContext";
import { Avatar, Card } from "../../components/admin/ui";
import Pagination from "../../components/admin/Pagination";
import SearchInput from "../../components/admin/SearchInput";
import { getPatients } from "../../lib/doctorStats";
import { formatDate } from "../../lib/format";

const PAGE_SIZE = 10;

// /doctor/patients: everyone who has booked this doctor
export default function DoctorPatientsPage() {
  const { appointments, usersById } = useDoctor();
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const patients = useMemo(() => getPatients(appointments), [appointments]);
  const list = useMemo(() => {
    const q = search.trim().toLowerCase();
    return patients.filter(
      (p) =>
        !q ||
        `${p.name} ${usersById[p.userId]?.email ?? ""}`
          .toLowerCase()
          .includes(q),
    );
  }, [patients, search, usersById]);

  const pageCount = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = list.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  return (
    <Card
      title="Patients"
      subtitle={`${patients.length} people have booked you`}
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
          placeholder="Search patients…"
        />
      </div>
      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead className="border-b border-black/5 text-xs text-gray-500">
            <tr>
              {[
                "Patient",
                "Completed visits",
                "Last visit",
                "Next appointment",
              ].map((h) => (
                <th key={h} className="py-3 font-medium">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-black/5">
            {visible.map((p) => (
              <tr key={p.id}>
                <td className="py-3">
                  <span className="flex items-center gap-3">
                    <Avatar
                      name={p.name}
                      photo={usersById[p.userId]?.photoUrl}
                      size="h-9 w-9"
                    />
                    <span>
                      <span className="block font-semibold">{p.name}</span>
                      {usersById[p.userId]?.email && (
                        <span className="block text-xs text-gray-500">
                          {usersById[p.userId].email}
                        </span>
                      )}
                    </span>
                  </span>
                </td>
                <td className="font-medium">{p.visits}</td>
                <td className="text-gray-600">{formatDate(p.last)}</td>
                <td>
                  {p.next ? (
                    <span className="rounded-md bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700">
                      {formatDate(p.next)}
                    </span>
                  ) : (
                    <span className="text-gray-400">—</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <p className="py-10 text-center text-sm text-gray-500">
            {patients.length === 0
              ? "No patients yet. They appear here after their first booking."
              : "No patients match your search."}
          </p>
        )}
      </div>
    </Card>
  );
}
