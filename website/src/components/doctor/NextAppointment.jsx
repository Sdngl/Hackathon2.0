import { useState } from "react";
import { Building, CalendarCheck, Video } from "lucide-react";
import StatusModal from "../admin/StatusModal";

function startsIn(date) {
  const minutes = Math.round((date - new Date()) / 60000);
  if (minutes < 60) return `in ${Math.max(minutes, 0)} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `in ${hours} hr${hours > 1 ? "s" : ""}`;
  const days = Math.round(hours / 24);
  return `in ${days} day${days > 1 ? "s" : ""}`;
}

// Green card with the very next appointment
export default function NextAppointment({ appointment: a }) {
  const [managing, setManaging] = useState(false);

  if (!a) {
    return (
      <section className="flex flex-col justify-center rounded-3xl bg-gradient-to-br from-brand-800 to-brand-500 p-6 text-white">
        <CalendarCheck size={24} className="opacity-80" />
        <p className="mt-4 text-lg font-semibold">No upcoming appointments</p>
        <p className="mt-1 text-sm text-white/75">
          New bookings from the app will show up here.
        </p>
      </section>
    );
  }

  const TypeIcon = a.type.toLowerCase().includes("video") ? Video : Building;

  return (
    <section className="flex flex-col rounded-3xl bg-gradient-to-br from-brand-800 to-brand-500 p-6 text-white">
      <div className="flex items-center justify-between">
        <p className="text-sm text-white/80">Next appointment</p>
        <span className="rounded-full bg-white/20 px-2.5 py-1 text-xs font-semibold">
          {startsIn(a.date)}
        </span>
      </div>
      <p className="mt-4 text-2xl font-bold tracking-tight">{a.patient}</p>
      <p className="mt-1 text-sm text-white/80">
        {a.dateLabel} · {a.time}
      </p>
      <p className="mt-3 flex items-center gap-2 text-sm">
        <TypeIcon size={15} />
        {a.type}
      </p>
      <button
        onClick={() => setManaging(true)}
        className="mt-auto self-start rounded-full bg-white px-5 py-2.5 text-sm font-semibold text-brand-700 hover:bg-brand-50"
      >
        Manage
      </button>
      {managing && (
        <StatusModal appointment={a} onClose={() => setManaging(false)} />
      )}
    </section>
  );
}
