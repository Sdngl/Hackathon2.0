import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db } from "../lib/firebase";

// Loads only the users you ask for (e.g. this doctor's patients), not the whole collection.
// Users that can't be read (deleted, or blocked by rules) are simply left out.
export default function useUsersByIds(ids) {
  const [usersById, setUsersById] = useState({});
  const key = [...new Set(ids)].filter(Boolean).sort().join(",");

  useEffect(() => {
    if (!key) return;
    let cancelled = false;
    Promise.allSettled(
      key.split(",").map((id) => getDoc(doc(db, "users", id))),
    ).then((results) => {
      if (cancelled) return;
      const found = {};
      for (const r of results) {
        if (r.status === "fulfilled" && r.value.exists())
          found[r.value.id] = { id: r.value.id, ...r.value.data() };
      }
      setUsersById(found);
    });
    return () => {
      cancelled = true;
    };
  }, [key]);

  return usersById;
}
