import { Navigate, Route, Routes } from "react-router";
import Landing from "../src/pages/Landing";
import PortalSelect from "./pages/PortalSelect";
import AdminLogin from "../src/pages/admin/Login";
import Overview from "../src/pages/admin/Overview";
import DoctorsPage from "../src/pages/admin/DoctorsPage";
import DoctorDetail from "../src/pages/admin/DoctorDetail";
import AppointmentsPage from "../src/pages/admin/AppointmentsPage";
import UsersPage from "../src/pages/admin/UsersPage";
import UserDetail from "../src/pages/admin/UserDetail";
import ClinicsPage from "../src/pages/admin/ClinicsPage";
import SubscriptionsPage from "../src/pages/admin/SubscriptionsPage";
import ScansPage from "../src/pages/admin/ScansPage";
import SuggestionRulesPage from "../src/pages/admin/SuggestionRulesPage";
import ContentPage from "../src/pages/admin/ContentPage";
import NotificationsPage from "../src/pages/admin/NotificationsPage";
import SettingsPage from "../src/pages/admin/SettingsPage";
import ComingSoon from "../src/pages/admin/ComingSoon";
import AdminLayout from "./components/admin/AdminLayout";
import ProtectedRoute from "./components/ProtectedRoute";
import { adminNav } from "./components/admin/navItems";

// Sidebar pages that are built. Anything not listed here shows "Coming soon".
const builtPages = {
  users: <UsersPage />,
  clinics: <ClinicsPage />,
  subscriptions: <SubscriptionsPage />,
  scans: <ScansPage />,
  "suggestion-rules": <SuggestionRulesPage />,
  content: <ContentPage />,
  notifications: <NotificationsPage />,
  settings: <SettingsPage />,
  doctors: <DoctorsPage />,
  appointments: <AppointmentsPage />,
};

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/portal" element={<PortalSelect />} />
      <Route path="/admin/login" element={<AdminLogin />} />
      <Route
        path="/doctor/login"
        element={<ComingSoon title="Doctor portal" standalone />}
      />

      {/* Everything under /admin needs an admin login */}
      <Route element={<ProtectedRoute />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Overview />} />
          <Route path="doctors/:id" element={<DoctorDetail />} />
          <Route path="users/:id" element={<UserDetail />} />
          {adminNav
            .filter((item) => item.path !== "")
            .map((item) => (
              <Route
                key={item.path}
                path={item.path}
                element={
                  builtPages[item.path] ?? <ComingSoon title={item.label} />
                }
              />
            ))}
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
