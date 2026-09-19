import useCollection from "../../hooks/useCollection";
import Consultations from "../../components/admin/Consultations";

// /admin/appointments: every appointment, 10 per page, starting on "Upcoming"
export default function AppointmentsPage() {
  const users = useCollection("users");
  const doctors = useCollection("doctors");

  return (
    <Consultations
      users={users.data}
      doctors={doctors.data}
      initialFilter="upcoming"
      pageSize={10}
      title="Appointments"
    />
  );
}
