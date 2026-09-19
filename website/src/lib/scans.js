// Scan numbers for the Scans & AI Usage page.
// scans = [{ type: 'medicines' | 'meals' | 'reports', userId, date }]
import { isActivePlus, startOfToday } from "./dashboardStats";

const DAY = 24 * 60 * 60 * 1000;
export const SCAN_TYPES = ["medicines", "meals", "reports"];

export const RANGES = [
  { key: "today", label: "Today", days: 1 },
  { key: "week", label: "This week", days: 7 },
  { key: "month", label: "This month", days: 30 },
];

// Start of the range: today at midnight, 6 days before that, or 29 days before that
export function rangeStart(rangeKey) {
  const days = RANGES.find((r) => r.key === rangeKey)?.days ?? 1;
  return new Date(startOfToday().getTime() - (days - 1) * DAY);
}

export const inRange = (scans, rangeKey) => {
  const start = rangeStart(rangeKey);
  return scans.filter((s) => s.date && s.date >= start);
};

export function countByType(scans) {
  const counts = { medicines: 0, meals: 0, reports: 0 };
  for (const s of scans) counts[s.type] = (counts[s.type] ?? 0) + 1;
  return counts;
}

// One bar per day for the last `days` days, split by scan type
export function scansPerDay(scans, days = 7) {
  const today = startOfToday();
  return Array.from({ length: days }, (_, i) => {
    const start = new Date(today.getTime() - (days - 1 - i) * DAY);
    const end = new Date(start.getTime() + DAY);
    const dayScans = scans.filter((s) => s.date >= start && s.date < end);
    return {
      day: start.toLocaleDateString("en-US", {
        weekday: "short",
        day: "numeric",
      }),
      ...countByType(dayScans),
      total: dayScans.length,
    };
  });
}

// Users who scanned the most in the range
export function topScanners(scans, users, limit = 5) {
  const byUser = {};
  for (const s of scans) {
    byUser[s.userId] ??= {
      userId: s.userId,
      total: 0,
      medicines: 0,
      meals: 0,
      reports: 0,
    };
    byUser[s.userId].total++;
    byUser[s.userId][s.type]++;
  }
  const usersById = Object.fromEntries(users.map((u) => [u.id, u]));
  return Object.values(byUser)
    .sort((a, b) => b.total - a.total)
    .slice(0, limit)
    .map((row) => ({ ...row, user: usersById[row.userId] }));
}

// Free users who reached the 5-scans-a-day limit today
export function limitHitsToday(scans, users) {
  const todays = inRange(scans, "today");
  const plusIds = new Set(
    users.filter((u) => isActivePlus(u)).map((u) => u.id),
  );
  const perUser = {};
  for (const s of todays) perUser[s.userId] = (perUser[s.userId] ?? 0) + 1;
  return Object.entries(perUser).filter(([id, n]) => n >= 5 && !plusIds.has(id))
    .length;
}
