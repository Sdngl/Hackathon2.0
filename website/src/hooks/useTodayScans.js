import { useEffect, useState } from "react";
import {
  collectionGroup,
  onSnapshot,
  query,
  Timestamp,
  where,
} from "firebase/firestore";
import { db } from "../lib/firebase";
import { startOfToday } from "../lib/dashboardStats";

// The subcollections under each user that count as "scans"
const SCAN_COLLECTIONS = ["appointments", "meals", "medicines", "reports"];

// The date field inside those documents. Change this if yours is named differently.
const DATE_FIELD = "createdAt";

// Live list of every scan uploaded today, across all users
export default function useTodayScans() {
  const [scans, setScans] = useState({ appointments: [], meals: [], medicines: [], reports: [] });
  const [error, setError] = useState(null);

  useEffect(() => {
    const since = Timestamp.fromDate(startOfToday());

    const unsubscribers = SCAN_COLLECTIONS.map((name) =>
      onSnapshot(
        // collectionGroup = "every 'meals' subcollection, under every user"
        query(collectionGroup(db, name), where(DATE_FIELD, ">=", since)),
        (snap) => {
          const docs = snap.docs.map((doc) => ({
            type: name,
            userId: doc.ref.parent.parent?.id, // users/{userId}/meals/{docId}
          }));
          setScans((prev) => ({ ...prev, [name]: docs }));
        },
        (err) => setError(err),
      ),
    );

    return () => unsubscribers.forEach((unsub) => unsub());
  }, []);

  return { scans: Object.values(scans).flat(), error };
}
