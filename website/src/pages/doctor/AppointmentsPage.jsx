import { useSearchParams } from "react-router";
import { useDoctor } from "../../context/DoctorContext";
import AppointmentsTable from "../../components/doctor/AppointmentsTable";

// /doctor/appointments (add ?tab=unscheduled to open "Needs a date")
export default function DoctorAppointmentsPage() {
  const { appointments, appointmentsError } = useDoctor();
  const [params] = useSearchParams();
  const initial = ["today", "upcoming", "unscheduled", "all"].includes(
    params.get("tab"),
  )
    ? params.get("tab")
    : "upcoming";

  return (
    <AppointmentsTable
      key={initial} // reopen on the right tab when a link changes it
      appointments={appointments}
      error={appointmentsError}
      initialFilter={initial}
      pageSize={10}
      title="Appointments"
    />
  );
}
