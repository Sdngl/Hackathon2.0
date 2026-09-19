import { useEffect, useState } from "react";
import { collectionGroup, onSnapshot } from "firebase/firestore";
import { db } from "../lib/firebase";

// Live list of every appointment under every user: users/{userId}/appointments/{id}
// No filter in the query, so no extra Firestore index is needed.
export default function useAppointments() {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    return onSnapshot(
      collectionGroup(db, "appointments"),
      (snap) => {
        setAppointments(
          snap.docs.map((doc) => ({
            id: doc.id,
            path: doc.ref.path,
            userId: doc.ref.parent.parent?.id,
            ...doc.data(),
          })),
        );
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      },
    );
  }, []);

  return { appointments, loading, error };
}
