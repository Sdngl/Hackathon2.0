import { useMemo } from "react";
import useCollection from "./useCollection";
import useTodayScans from "./useTodayScans";
import {
  getDoctorStats,
  getGrowth,
  getPlanBreakdown,
  getScanStats,
  getUserStats,
} from "../lib/dashboardStats";

// One hook that loads everything the Overview page needs
export default function useDashboardData() {
  const users = useCollection("users");
  const doctors = useCollection("doctors");
  const { scans, error: scansError } = useTodayScans();

  const data = useMemo(
    () => ({
      userStats: getUserStats(users.data),
      plans: getPlanBreakdown(users.data),
      growth: getGrowth(users.data),
      doctorStats: getDoctorStats(doctors.data),
      doctors: doctors.data,
      users: users.data,
      scanStats: getScanStats(scans, users.data),
    }),
    [users.data, doctors.data, scans],
  );

  return {
    ...data,
    loading: users.loading || doctors.loading,
    error: users.error || doctors.error,
    scansError,
  };
}
