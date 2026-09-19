import { useDoctor } from "../../context/DoctorContext";
import AppointmentsTable from "../../components/doctor/AppointmentsTable";

// /doctor/appointments
export default function DoctorAppointmentsPage() {
  const { appointments, appointmentsError } = useDoctor();
  return (
    <AppointmentsTable
      appointments={appointments}
      error={appointmentsError}
      initialFilter="upcoming"
      pageSize={10}
      title="Appointments"
    />
  );
}
