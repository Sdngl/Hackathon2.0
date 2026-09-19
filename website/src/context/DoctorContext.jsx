import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { useAuth } from "./AuthContext";
import useDocument from "../hooks/useDocument";
import useDoctorAppointments, {
  APPOINTMENT_DOCTOR_FIELD,
} from "../hooks/useDoctorAppointments";
import useUsersByIds from "../hooks/useUsersByIds";
import { mapAppointment } from "../lib/appointments";
import { grantDoctorAccess } from "../lib/doctorAccess";

// Shared by every doctor page: the live doctor profile, their appointments
// (already mapped for tables), and the names of their patients.
const DoctorContext = createContext(null);

export function DoctorProvider({ children }) {
  const { user, doctor: signedInDoctor } = useAuth();
  const live = useDocument("doctors", signedInDoctor.id); // updates when the profile is edited
  const doctor = live.data ?? signedInDoctor;

  const doctorKey =
    APPOINTMENT_DOCTOR_FIELD === "doctorName" ? doctor.name : doctor.id;
  const {
    appointments: raw,
    loading,
    error,
  } = useDoctorAppointments(doctorKey);

  // Write the access passes for every appointment first (see lib/doctorAccess.js),
  // then read patient names and reports. accessKey changes when appointments change.
  const accessKey = raw
    .map((a) => `${a.path}:${a.reportId ?? ""}:${a.reportShared ?? ""}`)
    .sort()
    .join("|");
  const [readyKey, setReadyKey] = useState(null);
  useEffect(() => {
    if (!accessKey) return;
    let cancelled = false;
    grantDoctorAccess({
      doctorId: doctor.id,
      doctorUid: user.uid,
      appointments: raw,
    }).then(() => {
      if (!cancelled) setReadyKey(accessKey);
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [accessKey, doctor.id, user.uid]);
  const accessReady = !accessKey || readyKey === accessKey;

  const usersById = useUsersByIds(accessReady ? raw.map((a) => a.userId) : []);

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
    accessReady,
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
