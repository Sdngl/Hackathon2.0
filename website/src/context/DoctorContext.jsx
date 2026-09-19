import { createContext, useContext, useMemo } from "react";
import { useAuth } from "./AuthContext";
import useDocument from "../hooks/useDocument";
import useDoctorAppointments, {
  APPOINTMENT_DOCTOR_FIELD,
} from "../hooks/useDoctorAppointments";
import useUsersByIds from "../hooks/useUsersByIds";
import { mapAppointment } from "../lib/appointments";

// Shared by every doctor page: the live doctor profile, their appointments
// (already mapped for tables), and the names of their patients.
const DoctorContext = createContext(null);

export function DoctorProvider({ children }) {
  const { doctor: signedInDoctor } = useAuth();
  const live = useDocument("doctors", signedInDoctor.id); // updates when the profile is edited
  const doctor = live.data ?? signedInDoctor;

  const doctorKey =
    APPOINTMENT_DOCTOR_FIELD === "doctorName" ? doctor.name : doctor.id;
  const {
    appointments: raw,
    loading,
    error,
  } = useDoctorAppointments(doctorKey);
  const usersById = useUsersByIds(raw.map((a) => a.userId));

  const appointments = useMemo(
    () =>
      raw.map((a) => ({
        ...mapAppointment(a, usersById, { [doctor.id]: doctor }),
        userId: a.userId,
      })),
    [raw, usersById, doctor],
  );

  const value = {
    doctor,
    appointments,
    usersById,
    appointmentsLoading: loading,
    appointmentsError: error,
  };
  return (
    <DoctorContext.Provider value={value}>{children}</DoctorContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useDoctor() {
  return useContext(DoctorContext);
}
