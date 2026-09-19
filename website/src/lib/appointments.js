// Everything about reading appointment documents lives here.
// If your appointment fields have different names, only this file needs changing:
// each list is tried in order and the first field that exists wins.
import { toDate } from "./dashboardStats";

const FIELDS = {
  date: [
    "date",
    "appointmentDate",
    "scheduledAt",
    "dateTime",
    "startTime",
    "slotDate",
  ],
  time: ["time", "slot", "timeSlot", "appointmentTime"],
  doctorId: ["doctorId", "doctorUid"],
  doctorName: ["doctorName", "doctor"],
  patientName: ["patientName", "userName", "displayName"],
  type: ["type", "consultationType", "mode"],
  status: ["status", "appointmentStatus"],
};

export const STATUS_OPTIONS = [
  "Scheduled",
  "Confirmed",
  "Ongoing",
  "Completed",
  "Cancelled",
];

function pick(data, keys) {
  for (const key of keys) {
    if (data[key] !== undefined && data[key] !== null && data[key] !== "")
      return data[key];
  }
  return undefined;
}

// "2026-09-19" strings should mean local midnight, not UTC
function parseDate(value) {
  if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const [y, m, d] = value.split("-").map(Number);
    return new Date(y, m - 1, d);
  }
  return toDate(value);
}

export const capitalize = (s) =>
  String(s ?? "")
    .replace(/[_-]/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());

// Turns one Firestore appointment into what the table needs
export function mapAppointment(raw, usersById, doctorsById) {
  const date = parseDate(pick(raw, FIELDS.date));
  const doctorId = pick(raw, FIELDS.doctorId);
  const rawTime = pick(raw, FIELDS.time);
  const hasClock = date && (date.getHours() !== 0 || date.getMinutes() !== 0);
  const rawStatus = pick(raw, FIELDS.status) ?? "scheduled";

  return {
    id: raw.id,
    path: raw.path, // full Firestore path, used to update the status
    date,
    time:
      rawTime ??
      (hasClock
        ? date.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
          })
        : "—"),
    dateLabel: date
      ? date.toLocaleDateString("en-US", { month: "short", day: "numeric" })
      : "No date",
    patient:
      pick(raw, FIELDS.patientName) ??
      usersById[raw.userId]?.displayName ??
      "Unknown patient",
    doctor:
      pick(raw, FIELDS.doctorName) ??
      doctorsById[doctorId]?.name ??
      "Unassigned",
    type: capitalize(pick(raw, FIELDS.type) ?? "In-Clinic"),
    rawStatus,
    status: capitalize(rawStatus),
  };
}

export function isSameDay(a, b) {
  return (
    a &&
    b &&
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

// filter: 'today' | 'upcoming' | 'all'
export function filterAppointments(list, filter) {
  const now = new Date();
  const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const filtered = list.filter((a) => {
    if (filter === "today") return isSameDay(a.date, now);
    if (filter === "upcoming") return a.date && a.date >= startToday;
    return true;
  });

  // soonest first; appointments without a date go last
  return filtered.sort(
    (a, b) => (a.date?.getTime() ?? Infinity) - (b.date?.getTime() ?? Infinity),
  );
}

// Save the status in the same style the app uses ("completed" vs "Completed")
export function formatStatusForSave(newStatus, previousRaw) {
  const prev = String(previousRaw ?? "");
  if (prev && prev === prev.toLowerCase()) return newStatus.toLowerCase();
  if (prev && prev === prev.toUpperCase()) return newStatus.toUpperCase();
  return newStatus;
}
