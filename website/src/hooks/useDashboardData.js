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

// One hook that loads everything the Overview page needs.
// `days` comes from the date picker in the top bar (7, 30 or 90).
export default function useDashboardData(days = 30) {
  const users = useCollection("users");
  const doctors = useCollection("doctors");
  const { scans, error: scansError } = useTodayScans();

  const data = useMemo(
    () => ({
      userStats: getUserStats(users.data, days),
      plans: getPlanBreakdown(users.data),
      growth: getGrowth(users.data, days),
      doctorStats: getDoctorStats(doctors.data),
      doctors: doctors.data,
      users: users.data,
      scanStats: getScanStats(scans, users.data),
    }),
    [users.data, doctors.data, scans, days],
  );

  return {
    ...data,
    loading: users.loading || doctors.loading,
    error: users.error || doctors.error,
    scansError,
  };
}
