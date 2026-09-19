import { LoaderCircle } from "lucide-react";
import useCollection from "../../hooks/useCollection";
import DoctorQueue from "../../components/admin/DoctorQueue";
import { getDoctorStats } from "../../lib/dashboardStats";

// /admin/doctors: the full doctors list, 10 per page
export default function DoctorsPage() {
  const { data: doctors, loading, error } = useCollection("doctors");

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
  return (
    <DoctorQueue
      doctors={sorted}
      stats={getDoctorStats(doctors)}
      pageSize={10}
      title="All doctors"
    />
  );
}
