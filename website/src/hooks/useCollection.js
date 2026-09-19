import { useEffect, useState } from 'react'
import { collection, onSnapshot, query } from 'firebase/firestore'
import { db } from '../lib/firebase'

// Live-reads a Firestore collection. Usage:
//   const { data, loading, error } = useCollection('doctors')
// Pass extra constraints (where, orderBy, limit) as the rest arguments.
export default function useCollection(path, ...constraints) {
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const q = query(collection(db, path), ...constraints)
    const unsubscribe = onSnapshot(
      q,
      (snap) => {
        setData(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })))
        setLoading(false)
      },
      (err) => {
        setError(err)
        setLoading(false)
      },
    )
    return unsubscribe
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [path])

  return { data, loading, error }
}
