import { Link } from "react-router";
import { CalendarPlus, ChevronRight } from "lucide-react";
import { needsDate } from "../../lib/appointments";

// Amber banner on the Overview when clinic bookings are waiting for the doctor to pick a date
export default function DateRequests({ appointments }) {
  const waiting = appointments.filter(needsDate).length;
  if (!waiting) return null;

  return (
    <Link
      to="/doctor/appointments?tab=unscheduled"
      className="flex items-center gap-4 rounded-3xl border border-amber-200 bg-amber-50 p-5 transition-colors hover:bg-amber-100"
    >
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-white text-amber-600">
        <CalendarPlus size={20} />
      </span>
      <span className="flex-1">
        <span className="block font-semibold text-amber-900">
          {waiting === 1
            ? "1 clinic booking needs a date"
            : `${waiting} clinic bookings need a date`}
        </span>
        <span className="block text-sm text-amber-800">
          Patients are waiting for you to confirm when to come in.
        </span>
      </span>
      <ChevronRight size={18} className="text-amber-700" />
    </Link>
  );
}
