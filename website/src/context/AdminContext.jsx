import { createContext, useContext, useMemo, useState } from "react";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "../lib/firebase";
import useCollection from "../hooks/useCollection";
import useAppointments from "../hooks/useAppointments";
import useDocument from "../hooks/useDocument";
import { useAuth } from "./AuthContext";
import { buildAlerts } from "../lib/alerts";
import { ADMIN_SETTINGS, mergeAdminSettings } from "../lib/settings";
import { APPLICATIONS } from "../lib/applications";

// Shared by every admin page: the top bar's date range, the data the search box
// and exports use, the notification feed, and this admin's saved settings.
const AdminContext = createContext(null);

const SEEN_KEY = "seva-admin-notifications-seen";

function readLastSeen() {
  try {
    return Number(localStorage.getItem(SEEN_KEY)) || 0;
  } catch {
    return 0;
  }
}

export function AdminProvider({ children }) {
  const { user } = useAuth();
  const users = useCollection("users");
  const doctors = useCollection("doctors");
  const { appointments } = useAppointments();
  const applications = useCollection(APPLICATIONS);
  const settingsDoc = useDocument(ADMIN_SETTINGS, user?.uid ?? "none");

  const settings = useMemo(
    () => mergeAdminSettings(settingsDoc.data),
    [settingsDoc.data],
  );

  // The date picker starts at the saved default until you pick something else
  const [rangeOverride, setRangeDays] = useState(null);
  const rangeDays = rangeOverride ?? settings.defaultRange;

  const [lastSeen, setLastSeen] = useState(readLastSeen);

  const alerts = useMemo(
    () =>
      buildAlerts(
        users.data,
        doctors.data,
        appointments,
        applications.data,
      ).filter(
        (a) => settings.alertKinds[a.kind] !== false, // types switched off in Settings are hidden
      ),
    [
      users.data,
      doctors.data,
      appointments,
      applications.data,
      settings.alertKinds,
    ],
  );
  const unreadCount = alerts.filter((a) => a.time.getTime() > lastSeen).length;

  function markAllRead() {
    const now = Date.now();
    try {
      localStorage.setItem(SEEN_KEY, String(now));
    } catch {
      // private browsing: the badge just resets on reload
    }
    setLastSeen(now);
  }

  // Saves part of this admin's settings, e.g. saveSettings({ defaultRange: 7 })
  function saveSettings(changes) {
    return setDoc(
      doc(db, ADMIN_SETTINGS, user.uid),
      { ...changes, updatedAt: serverTimestamp() },
      { merge: true },
    );
  }

  const value = {
    users: users.data,
    doctors: doctors.data,
    appointments,
    rangeDays,
    setRangeDays,
    alerts,
    lastSeen,
    unreadCount,
    markAllRead,
    settings,
    settingsLoading: settingsDoc.loading,
    saveSettings,
  };

  return (
    <AdminContext.Provider value={value}>{children}</AdminContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAdmin() {
  return useContext(AdminContext);
}
