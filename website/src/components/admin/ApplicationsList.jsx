import { useMemo, useState } from "react";
import { Avatar, Card, StatusPill } from "./ui";
import Tabs from "./Tabs";
import ApplicationReview from "./ApplicationReview";
import { APPLICATION_STATUSES } from "../../lib/applications";
import { toDate } from "../../lib/dashboardStats";
import { timeAgo } from "../../lib/format";

const statusLabel = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
};

// Applications from the public "Join as a doctor" form
export default function ApplicationsList({ applications }) {
  const [status, setStatus] = useState("pending");
  const [reviewingId, setReviewingId] = useState(null);

  const counts = useMemo(
    () =>
      Object.fromEntries(
        APPLICATION_STATUSES.map((s) => [
          s.key,
          applications.filter((a) => a.status === s.key).length,
        ]),
      ),
    [applications],
  );
  const visible = useMemo(
    () =>
      applications
        .filter((a) => a.status === status)
        .sort(
          (a, b) =>
            (toDate(b.createdAt)?.getTime() ?? 0) -
            (toDate(a.createdAt)?.getTime() ?? 0),
        ),
    [applications, status],
  );
  // look the application up by id so the pop-up shows live changes
  const reviewing = applications.find((a) => a.id === reviewingId);

  return (
    <Card
      title="Doctor applications"
      subtitle="Sent from the “Join as a doctor” form on the website"
    >
      <div className="mt-4">
        <Tabs
          tabs={APPLICATION_STATUSES.map((s) => ({
            key: s.key,
            label: `${s.label} (${counts[s.key]})`,
          }))}
          value={status}
          onChange={setStatus}
        />
      </div>

      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead className="border-b border-black/5 text-xs text-gray-500">
            <tr>
              {[
                "Applicant",
                "Specialization",
                "NMC number",
                "Hospital",
                "Applied",
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
            {visible.map((a) => (
              <tr key={a.id}>
                <td className="py-3">
                  <span className="flex items-center gap-3">
                    <Avatar name={a.name || "?"} />
                    <span>
                      <span className="block font-semibold">{a.name}</span>
                      <span className="block text-xs text-gray-500">
                        {a.email}
                      </span>
                    </span>
                  </span>
                </td>
                <td className="text-gray-600">
                  {(a.specialization ?? []).join(", ")}
                </td>
                <td className="font-mono text-xs">{a.licenseNumber}</td>
                <td className="text-gray-600">{a.hospital}</td>
                <td className="text-gray-600">{timeAgo(a.createdAt)}</td>
                <td>
                  <StatusPill status={statusLabel[a.status] ?? "Pending"} />
                </td>
                <td className="text-right">
                  <button
                    onClick={() => setReviewingId(a.id)}
                    className="rounded-lg bg-brand-700 px-4 py-1.5 text-xs font-semibold text-white hover:bg-brand-800"
                  >
                    {a.status === "pending" ? "Review" : "View"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {visible.length === 0 && (
          <p className="py-10 text-center text-sm text-gray-500">
            {status === "pending"
              ? "No applications waiting for review."
              : `No ${status} applications.`}
          </p>
        )}
      </div>

      {reviewing && (
        <ApplicationReview
          application={reviewing}
          onClose={() => setReviewingId(null)}
        />
      )}
    </Card>
  );
}
