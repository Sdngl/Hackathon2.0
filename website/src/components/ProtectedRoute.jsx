import { Navigate, Outlet } from "react-router";
import { LoaderCircle } from "lucide-react";
import { useAuth } from "../context/AuthContext";

// Wraps every /admin page: not logged in as admin → back to the login page
export default function ProtectedRoute() {
  const { isAdmin, loading } = useAuth();

  if (loading) {
    return (
      <div className="grid min-h-screen place-items-center">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  }

  return isAdmin ? <Outlet /> : <Navigate to="/admin/login" replace />;
}
