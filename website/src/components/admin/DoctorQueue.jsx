import { useState } from "react";
import { Link } from "react-router";
import { ChevronRight, Star } from "lucide-react";
import { Avatar, Card, StatusPill } from "./ui";
import Pagination from "./Pagination";

// Doctors table with < 1 / 2 > paging. Used on the Overview and the Doctors page.
export default function DoctorQueue({
  doctors,
  stats,
  pageSize = 5,
  title = "Doctors",
}) {
  const [page, setPage] = useState(1);

  const pageCount = Math.max(1, Math.ceil(doctors.length / pageSize));
  const current = Math.min(page, pageCount); // stays valid if doctors get deleted
  const visible = doctors.slice((current - 1) * pageSize, current * pageSize);

  return (
    <Card
      title={title}
      action={
        <div className="flex items-center gap-3">
          <Pagination page={current} pageCount={pageCount} onChange={setPage} />
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold whitespace-nowrap text-brand-700">
            {stats.active} of {stats.total} active
          </span>
        </div>
      }
    >
      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[820px] text-left text-sm">
          <thead className="border-b border-black/5 text-xs text-gray-500">
            <tr>
              {[
                "Name",
                "Specialization",
                "Clinic / Hospital",
                "Experience",
                "Rating",
                "Availability",
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
            {visible.map((d) => (
              <tr key={d.id} className="transition-colors hover:bg-mist/60">
                <td className="py-3.5">
                  <Link
                    to={`/admin/doctors/${d.id}`}
                    className="group flex items-center gap-3 font-semibold"
                  >
                    <Avatar name={d.name ?? "?"} photo={d.imageUrl} />
                    <span className="group-hover:text-brand-700 group-hover:underline">
                      {d.name ?? "Unnamed"}
                    </span>
                  </Link>
                </td>
                <td className="text-gray-600">
                  {Array.isArray(d.specialization)
                    ? d.specialization.join(", ")
                    : d.specialization}
                </td>
                <td className="text-gray-600">
                  {d.hospital ?? d.clinicName ?? d.Clinic ?? d.clinic ?? "—"}
                </td>
                <td className="text-gray-600">{d.experienceYears ?? 0} yrs</td>
                <td>
                  <span className="flex items-center gap-1 font-medium">
                    <Star size={13} className="fill-amber-400 text-amber-400" />
                    {d.rating ?? "—"}
                  </span>
                </td>
                <td>
                  <StatusPill status={d.available ? "Available" : "Busy"} />
                </td>
                <td>
                  <StatusPill status={d.isActive ? "Active" : "Inactive"} />
                </td>
                <td className="text-right">
                  <Link
                    to={`/admin/doctors/${d.id}`}
                    className="inline-grid h-8 w-8 place-items-center rounded-lg text-gray-400 hover:bg-white hover:text-ink"
                    aria-label={`View ${d.name}`}
                  >
                    <ChevronRight size={16} />
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {doctors.length === 0 && (
          <p className="py-8 text-center text-sm text-gray-500">
            No doctors yet.
          </p>
        )}
      </div>
    </Card>
  );
}
