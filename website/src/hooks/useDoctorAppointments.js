import { useEffect, useState } from "react";
import { collectionGroup, onSnapshot, query, where } from "firebase/firestore";
import { db } from "../lib/firebase";

// Which field in an appointment says which doctor it's with.
// If your appointments store the doctor's NAME instead of their document ID,
// change this to 'doctorName' and pass doctor.name in DoctorContext.
export const APPOINTMENT_DOCTOR_FIELD = "doctorId";

// Live list of this doctor's appointments, across every user
export default function useDoctorAppointments(doctorKey) {
  const [state, setState] = useState({
    appointments: [],
    loading: true,
    error: null,
    key: null,
  });

  useEffect(() => {
    if (!doctorKey) return;
    return onSnapshot(
      query(
        collectionGroup(db, "appointments"),
        where(APPOINTMENT_DOCTOR_FIELD, "==", doctorKey),
      ),
      (snap) =>
        setState({
          appointments: snap.docs.map((d) => ({
            id: d.id,
            path: d.ref.path,
            userId: d.ref.parent.parent?.id,
            ...d.data(),
          })),
          loading: false,
          error: null,
          key: doctorKey,
        }),
      (error) =>
        setState({ appointments: [], loading: false, error, key: doctorKey }),
    );
  }, [doctorKey]);

  if (state.key !== doctorKey)
    return { appointments: [], loading: true, error: null };
  return state;
}
