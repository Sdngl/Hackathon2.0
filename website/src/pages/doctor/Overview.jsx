import { useMemo } from "react";
import { CalendarDays, CalendarRange, Star, Users } from "lucide-react";
import { useDoctor } from "../../context/DoctorContext";
import MiniStat from "../../components/admin/MiniStat";
import NextAppointment from "../../components/doctor/NextAppointment";
import WeekChart from "../../components/doctor/WeekChart";
import AppointmentsTable from "../../components/doctor/AppointmentsTable";
import AvailabilityCard from "../../components/doctor/AvailabilityCard";
import ProfileCompleteness from "../../components/doctor/ProfileCompleteness";
import DateRequests from "../../components/doctor/DateRequests";
import { getDoctorOverview, nextSevenDays } from "../../lib/doctorStats";

// /doctor
export default function DoctorOverview() {
  const { doctor, appointments, appointmentsError } = useDoctor();
  const stats = useMemo(() => getDoctorOverview(appointments), [appointments]);
  const week = useMemo(() => nextSevenDays(appointments), [appointments]);

  return (
    <div className="space-y-5">
      <DateRequests appointments={appointments} />

      <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <MiniStat
          icon={CalendarDays}
          label="Today"
          value={stats.todayCount}
          note={`${stats.todayDone} completed`}
        />
        <MiniStat
          icon={CalendarRange}
          label="Next 7 days"
          value={stats.weekCount}
          note="upcoming appointments"
          tint="bg-blue-50 text-blue-600"
        />
        <MiniStat
          icon={Users}
          label="Patients"
          value={stats.patientCount}
          note="who have booked you"
          tint="bg-violet-50 text-violet-600"
        />
        <MiniStat
          icon={Star}
          label="Rating"
          value={doctor.rating ? doctor.rating : "—"}
          note={
            doctor.reviewCount
              ? `${doctor.reviewCount} reviews`
              : "No reviews yet"
          }
          tint="bg-amber-50 text-amber-600"
        />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1fr_1.6fr]">
        <NextAppointment appointment={stats.next} />
        <WeekChart data={week} />
      </div>

      <AppointmentsTable
        appointments={appointments}
        error={appointmentsError}
      />

      <div className="grid gap-5 xl:grid-cols-2">
        <AvailabilityCard doctor={doctor} />
        <ProfileCompleteness doctor={doctor} />
      </div>
    </div>
  );
}
