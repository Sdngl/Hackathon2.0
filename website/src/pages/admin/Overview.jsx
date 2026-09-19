import { LoaderCircle } from "lucide-react";
import useDashboardData from "../../hooks/useDashboardData";
import StatCards from "../../components/admin/StatCards";
import ActivityChart from "../../components/admin/ActivityChart";
import PlansDonut from "../../components/admin/PlansDonut";
import ScansToday from "../../components/admin/ScansToday";
import TokenBudget from "../../components/admin/TokenBudget";
import DoctorQueue from "../../components/admin/DoctorQueue";
import Consultations from "../../components/admin/Consultations";

export default function Overview() {
  const {
    userStats,
    plans,
    growth,
    doctorStats,
    doctors,
    users,
    scanStats,
    loading,
    error,
    scansError,
  } = useDashboardData();

  if (loading) {
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-3xl border border-red-100 bg-red-50 p-6 text-sm text-red-700">
        <p className="font-semibold">Couldn't load dashboard data.</p>
        <p className="mt-1">{error.message}</p>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <StatCards userStats={userStats} doctorStats={doctorStats} />

      <div className="grid gap-5 xl:grid-cols-[1.6fr_1fr]">
        <ActivityChart data={growth} />
        <PlansDonut plans={plans} total={userStats.plusCount} />
      </div>

      <div className="grid gap-5 xl:grid-cols-2">
        <ScansToday stats={scanStats} error={scansError} />
        <TokenBudget />
      </div>

      <DoctorQueue doctors={doctors} stats={doctorStats} />
      <Consultations users={users} doctors={doctors} />
    </div>
  );
}
