import { LogOut, Stethoscope } from "lucide-react";
import Logo from "../../components/Logo";
import { useAuth } from "../../context/AuthContext";

// /doctor: placeholder until the doctor dashboard is built
export default function DoctorHome() {
  const { doctor, logout } = useAuth();
  const specs = Array.isArray(doctor.specialization)
    ? doctor.specialization.join(", ")
    : doctor.specialization;

  return (
    <div className="flex min-h-screen flex-col bg-mist">
      <header className="mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-5 lg:px-8">
        <Logo />
        <button
          onClick={logout}
          className="flex items-center gap-2 rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-semibold hover:bg-mist"
        >
          <LogOut size={15} /> Sign out
        </button>
      </header>

      <main className="grid flex-1 place-items-center px-5 pb-20">
        <div className="w-full max-w-lg rounded-3xl border border-black/5 bg-white p-10 text-center">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-brand-50 text-brand-700">
            <Stethoscope size={26} />
          </span>
          <h1 className="mt-5 text-2xl font-bold tracking-tight">
            Welcome, {doctor.name}
          </h1>
          {specs && <p className="mt-1 text-sm text-gray-500">{specs}</p>}
          <p className="mt-4 text-gray-600">
            Your doctor dashboard is on its way. Soon you’ll see your
            appointments and patient reports here.
          </p>
        </div>
      </main>
    </div>
  );
}
