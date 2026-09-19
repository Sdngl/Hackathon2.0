import { Link, useSearchParams } from "react-router";
import { LoaderCircle, Plus } from "lucide-react";
import useCollection from "../../hooks/useCollection";
import DoctorQueue from "../../components/admin/DoctorQueue";
import ApplicationsList from "../../components/admin/ApplicationsList";
import Tabs from "../../components/admin/Tabs";
import { getDoctorStats } from "../../lib/dashboardStats";
import { APPLICATIONS } from "../../lib/applications";

// /admin/doctors (?tab=applications opens the applications list)
export default function DoctorsPage() {
  const { data: doctors, loading, error } = useCollection("doctors");
  const applications = useCollection(APPLICATIONS);
  const [params, setParams] = useSearchParams();
  const tab = params.get("tab") === "applications" ? "applications" : "doctors";

  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load doctors: {error.message}
      </p>
    );

  const sorted = [...doctors].sort((a, b) =>
    (a.name ?? "").localeCompare(b.name ?? ""),
  );
  const pending = applications.data.filter(
    (a) => a.status === "pending",
  ).length;

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Tabs
          tabs={[
            { key: "doctors", label: `Doctors (${doctors.length})` },
            {
              key: "applications",
              label: pending ? `Applications · ${pending} new` : "Applications",
            },
          ]}
          value={tab}
          onChange={(key) => setParams(key === "doctors" ? {} : { tab: key })}
        />
        <Link
          to="/admin/doctors/new"
          className="flex items-center gap-2 rounded-full bg-ink px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-800"
        >
          <Plus size={16} /> Add doctor
        </Link>
      </div>

      {tab === "doctors" ? (
        <DoctorQueue
          doctors={sorted}
          stats={getDoctorStats(doctors)}
          pageSize={10}
          title="All doctors"
        />
      ) : applications.error ? (
        <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
          Couldn't load applications: {applications.error.message}
        </p>
      ) : (
        <ApplicationsList applications={applications.data} />
      )}
    </div>
  );
}
