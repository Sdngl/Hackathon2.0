// Numbers for the doctor dashboard, from this doctor's own appointments.
// `appointments` here are already mapped (see lib/appointments.js) and include userId.
import { isSameDay } from "./appointments";
import { startOfToday } from "./dashboardStats";

const DAY = 24 * 60 * 60 * 1000;
const isDone = (a) =>
  ["completed", "cancelled"].includes(a.status.toLowerCase());
const isVideo = (a) => a.type.toLowerCase().includes("video");

export function getDoctorOverview(appointments) {
  const now = new Date();
  const today = appointments.filter((a) => isSameDay(a.date, now));
  const weekEnd = new Date(startOfToday().getTime() + 7 * DAY);

  const upcoming = appointments
    .filter((a) => a.date && a.date >= now && !isDone(a))
    .sort((a, b) => a.date - b.date);

  return {
    todayCount: today.length,
    todayDone: today.filter((a) => a.status.toLowerCase() === "completed")
      .length,
    weekCount: upcoming.filter((a) => a.date < weekEnd).length,
    patientCount: new Set(appointments.map((a) => a.userId).filter(Boolean))
      .size,
    next: upcoming[0] ?? null,
  };
}

// One bar per day for the next 7 days, split into in-clinic and video
export function nextSevenDays(appointments) {
  const today = startOfToday();
  return Array.from({ length: 7 }, (_, i) => {
    const start = new Date(today.getTime() + i * DAY);
    const end = new Date(start.getTime() + DAY);
    const day = appointments.filter(
      (a) =>
        a.date &&
        a.date >= start &&
        a.date < end &&
        a.status.toLowerCase() !== "cancelled",
    );
    return {
      day:
        i === 0
          ? "Today"
          : start.toLocaleDateString("en-US", {
              weekday: "short",
              day: "numeric",
            }),
      clinic: day.filter((a) => !isVideo(a)).length,
      video: day.filter(isVideo).length,
    };
  });
}

// One row per patient: visits, last and next appointment
export function getPatients(appointments) {
  const now = new Date();
  const byUser = {};
  for (const a of appointments) {
    const key = a.userId ?? a.patient;
    byUser[key] ??= {
      id: key,
      userId: a.userId,
      name: a.patient,
      visits: 0,
      last: null,
      next: null,
    };
    const p = byUser[key];
    if (a.status.toLowerCase() === "completed") p.visits++;
    if (a.date && a.date < now && (!p.last || a.date > p.last)) p.last = a.date;
    if (a.date && a.date >= now && !isDone(a) && (!p.next || a.date < p.next))
      p.next = a.date;
  }
  // patients with an upcoming appointment first (soonest at the top), then the most recent visits
  return Object.values(byUser).sort((a, b) => {
    if (a.next && b.next) return a.next - b.next;
    if (a.next || b.next) return a.next ? -1 : 1;
    return (b.last ?? 0) - (a.last ?? 0);
  });
}

// Fields patients see in the app, and whether this doctor has filled them in
export const PROFILE_FIELDS = [
  { key: "imageUrl", label: "Profile photo" },
  { key: "qualification", label: "Qualification" },
  { key: "about", label: "About you" },
  { key: "clinicAddress", label: "Clinic address" },
  { key: "clinicHours", label: "Clinic hours" },
  { key: "phone", label: "Phone" },
  { key: "consultationFee", label: "Consultation fee" },
  { key: "languages", label: "Languages" },
  { key: "availableSlots", label: "Available slots" },
];

const filled = (v) =>
  Array.isArray(v)
    ? v.length > 0
    : v !== undefined && v !== null && v !== "" && v !== 0;

export function profileCompleteness(doctor) {
  const missing = PROFILE_FIELDS.filter((f) => !filled(doctor[f.key]));
  return {
    percent: Math.round(
      ((PROFILE_FIELDS.length - missing.length) / PROFILE_FIELDS.length) * 100,
    ),
    missing,
  };
}
