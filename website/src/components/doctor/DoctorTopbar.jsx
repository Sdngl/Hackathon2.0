import { Link } from "react-router";
import { Menu } from "lucide-react";
import { useDoctor } from "../../context/DoctorContext";

function greeting() {
  const h = new Date().getHours();
  return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
}

export default function DoctorTopbar({ onMenu }) {
  const { doctor } = useDoctor();
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-black/5 bg-white/90 px-5 py-4 backdrop-blur lg:px-8">
      <button
        onClick={onMenu}
        className="rounded-lg p-2 lg:hidden"
        aria-label="Open menu"
      >
        <Menu size={20} />
      </button>

      <div className="min-w-0">
        <p className="truncate font-semibold">
          {greeting()}, {doctor.name}
        </p>
        <p className="text-xs text-gray-500">{today}</p>
      </div>

      {/* shows whether patients can book right now; click to change */}
      <Link
        to="/doctor/availability"
        className={`ml-auto flex items-center gap-2 rounded-full px-3.5 py-2 text-xs font-semibold ${
          doctor.available
            ? "bg-brand-50 text-brand-700"
            : "bg-gray-100 text-gray-600"
        }`}
      >
        <span
          className={`h-2 w-2 rounded-full ${doctor.available ? "bg-brand-500" : "bg-gray-400"}`}
        />
        {doctor.available ? "Accepting bookings" : "Not accepting bookings"}
      </Link>
    </header>
  );
}
