import { useEffect, useState } from "react";
import {
  collectionGroup,
  onSnapshot,
  query,
  Timestamp,
  where,
} from "firebase/firestore";
import { db } from "../lib/firebase";
import { startOfToday, toDate } from "../lib/dashboardStats";
import { SCAN_TYPES } from "../lib/scans";

const DATE_FIELD = "createdAt"; // same field as useTodayScans
const DAY = 24 * 60 * 60 * 1000;

// Live list of every scan from the last `days` days, across all users.
// Uses the same Firestore indexes you already created for the Overview.
export default function useScans(days = 30) {
  const [byType, setByType] = useState({
    medicines: [],
    meals: [],
    reports: [],
  });
  const [loaded, setLoaded] = useState(new Set());
  const [error, setError] = useState(null);

  useEffect(() => {
    const since = Timestamp.fromDate(
      new Date(startOfToday().getTime() - (days - 1) * DAY),
    );

    const unsubscribers = SCAN_TYPES.map((type) =>
      onSnapshot(
        query(collectionGroup(db, type), where(DATE_FIELD, ">=", since)),
        (snap) => {
          const docs = snap.docs.map((doc) => ({
            id: doc.id,
            type,
            userId: doc.ref.parent.parent?.id,
            date: toDate(doc.get(DATE_FIELD)),
          }));
          setByType((prev) => ({ ...prev, [type]: docs }));
          setLoaded((prev) => new Set(prev).add(type));
        },
        (err) => setError(err),
      ),
    );
    return () => unsubscribers.forEach((unsub) => unsub());
  }, [days]);

  return {
    scans: Object.values(byType).flat(),
    loading: loaded.size < SCAN_TYPES.length && !error,
    error,
  };
}
