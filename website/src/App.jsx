import { Navigate, Route, Routes } from "react-router";
import Landing from "../src/pages/Landing";
import PortalSelect from "../src/pages/PortalSelect";
import AdminLogin from "../src/pages/admin/Login";
import Overview from "../src/pages/admin/Overview";
import DoctorsPage from "../src/pages/admin/DoctorsPage";
import DoctorDetail from "../src/pages/admin/DoctorDetail";
import AppointmentsPage from "../src/pages/admin/AppointmentsPage";
import ComingSoon from "../src/pages/admin/ComingSoon";
import AdminLayout from "../src/components/admin/AdminLayout";
import ProtectedRoute from "../src/components/ProtectedRoute";
import { adminNav } from "../src/components/admin/navItems";

// Sidebar pages that are built. Anything not listed here shows "Coming soon".
const builtPages = {
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
