import { useEffect, useState } from "react";
import { doc, onSnapshot } from "firebase/firestore";
import { db } from "../lib/firebase";

// Live-reads one document, e.g. useDocument('doctors', id)
export default function useDocument(collectionName, id) {
  const [state, setState] = useState({
    data: null,
    loading: true,
    error: null,
    key: null,
  });
  const key = `${collectionName}/${id}`;

  useEffect(() => {
    return onSnapshot(
      doc(db, collectionName, id),
      (snap) =>
        setState({
          data: snap.exists() ? { id: snap.id, ...snap.data() } : null,
          loading: false,
          error: null,
          key,
        }),
      (error) => setState({ data: null, loading: false, error, key }),
    );
  }, [collectionName, id, key]);

  // while switching to a different document, report loading instead of stale data
  if (state.key !== key) return { data: null, loading: true, error: null };
  return state;
}
