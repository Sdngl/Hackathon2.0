import { Navigate, Outlet } from "react-router";
import { LoaderCircle } from "lucide-react";
import { useAuth } from "../context/AuthContext";

// Wraps every /doctor page: not logged in as a doctor → the doctor login page
export default function DoctorRoute() {
  const { isDoctor, loading } = useAuth();

  if (loading) {
    return (
      <div className="grid min-h-screen place-items-center">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  }

  return isDoctor ? <Outlet /> : <Navigate to="/doctor/login" replace />;
}
