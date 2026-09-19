// `kind` matches the notification types in Settings (lib/settings.js).
// Builds the admin's activity feed (Notifications page, bell and sidebar badge)
// from data that's already in Firestore. Nothing extra needs to be stored.
import { isActivePlus, toDate } from "./dashboardStats";
import { mapAppointment } from "./appointments";

const DAY = 24 * 60 * 60 * 1000;
const WINDOW_DAYS = 14; // how far back the feed goes

export const ALERT_TYPES = [
  { key: "all", label: "All" },
  { key: "user", label: "New users" },
  { key: "subscription", label: "Subscriptions" },
  { key: "appointment", label: "Appointments" },
  { key: "doctor", label: "Doctors" },
];

const name = (u) => u.displayName || u.email || "A user";

export function buildAlerts(users, doctors, appointments, applications = []) {
  const now = new Date();
  const since = new Date(now - WINDOW_DAYS * DAY);
  const recent = (d) => d && d >= since && d <= now;
  const alerts = [];

  for (const u of users) {
    const joined = toDate(u.createdAt);
    if (recent(joined)) {
      alerts.push({
        id: `join-${u.id}`,
        kind: "join",
        type: "user",
        time: joined,
        link: `/admin/users/${u.id}`,
        title: `${name(u)} joined SEVA`,
        body: u.email ?? "",
      });
    }

    const started = toDate(u.subscriptionStartedAt);
    if (u.isPaid && recent(started)) {
      alerts.push({
        id: `sub-${u.id}-${started.getTime()}`,
        kind: "subscribe",
        type: "subscription",
        time: started,
        link: `/admin/users/${u.id}`,
        title: `${name(u)} subscribed to ${u.subscriptionTitle ?? "Plus"}`,
        body: `Rs. ${Number(u.subscriptionPrice || 0).toLocaleString("en-IN")}${u.paymentProvider ? ` via ${u.paymentProvider}` : ""}`,
      });
    }

    const expires = toDate(u.subscriptionExpiresAt);
    if (isActivePlus(u, now) && expires && expires - now < 7 * DAY) {
      // shows up when the subscription enters its last 7 days
      alerts.push({
        id: `exp-${u.id}-${expires.getTime()}`,
        kind: "expiring",
        type: "subscription",
        time: new Date(expires - 7 * DAY),
        link: "/admin/subscriptions",
        tone: "warning",
        title: `${name(u)}'s plan expires soon`,
        body: `Ends ${expires.toLocaleDateString("en-US", { month: "short", day: "numeric" })}`,
      });
    }

    const updated = toDate(u.subscriptionUpdatedAt);
    if (
      isActivePlus(u, now) &&
      u.subscriptionCancelAtPeriodEnd &&
      recent(updated)
    ) {
      alerts.push({
        id: `cancel-${u.id}-${updated.getTime()}`,
        kind: "cancel",
        type: "subscription",
        time: updated,
        link: "/admin/subscriptions",
        tone: "warning",
        title: `${name(u)} cancelled their plan`,
        body: "It stays active until the end of the period",
      });
    }
  }

  // Appointments need a createdAt (when it was booked) to appear in the feed
  const usersById = Object.fromEntries(users.map((u) => [u.id, u]));
  const doctorsById = Object.fromEntries(doctors.map((d) => [d.id, d]));
  for (const raw of appointments) {
    const booked = toDate(raw.createdAt);
    if (!recent(booked)) continue;
    const a = mapAppointment(raw, usersById, doctorsById);
    alerts.push({
      id: `appt-${raw.path}`,
      kind: "appointment",
      type: "appointment",
      time: booked,
      link: "/admin/appointments",
      title: `${a.patient} booked ${a.doctor}`,
      body: `${a.dateLabel} · ${a.time} · ${a.type}`,
    });
  }

  // Doctor applications still waiting for a decision
  for (const app of applications) {
    const applied = toDate(app.createdAt);
    if (app.status !== "pending" || !recent(applied)) continue;
    const specs = Array.isArray(app.specialization)
      ? app.specialization.join(", ")
      : app.specialization;
    alerts.push({
      id: `apply-${app.id}`,
      kind: "application",
      type: "doctor",
      time: applied,
      link: "/admin/doctors?tab=applications",
      title: `${app.name} applied to join as a doctor`,
      body: [specs, app.licenseNumber].filter(Boolean).join(" · "),
    });
  }

  return alerts.sort((a, b) => b.time - a.time).slice(0, 100);
}
