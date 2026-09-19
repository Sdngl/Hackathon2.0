// Turns raw Firestore documents into the numbers the dashboard shows.
// All functions are pure: data in, numbers out. No Firebase calls here.

const DAY = 24 * 60 * 60 * 1000;

// Firestore Timestamps have .toDate(); plain strings/numbers get converted too
export function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

export function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

// A user counts as Plus if isPaid is true and the subscription hasn't expired
export function isActivePlus(user, now = new Date()) {
  if (!user.isPaid) return false;
  const expires = toDate(user.subscriptionExpiresAt);
  return !expires || expires > now;
}

export function getUserStats(users) {
  const now = new Date();
  const dayAgo = new Date(now - DAY);
  const monthAgo = new Date(now - 30 * DAY);

  const activeToday = users.filter(
    (u) => toDate(u.lastLoginAt) >= dayAgo,
  ).length;
  const plusUsers = users.filter((u) => isActivePlus(u, now));

  // Revenue = subscriptions started in the last 30 days
  const recentPayments = users.filter(
    (u) => u.isPaid && toDate(u.subscriptionStartedAt) >= monthAgo,
  );
  const revenue = recentPayments.reduce(
    (sum, u) => sum + (Number(u.subscriptionPrice) || 0),
    0,
  );

  return {
    totalUsers: users.length,
    activeToday,
    plusCount: plusUsers.length,
    revenue,
    paymentsCount: recentPayments.length,
  };
}

const PLAN_COLORS = ["#0d6e57", "#16a37f", "#a8e0cb", "#d3f0e4"];

// Groups active Plus users by plan, e.g. "6 Months", "Monthly", "Yearly"
export function getPlanBreakdown(users) {
  const plus = users.filter((u) => isActivePlus(u));
  const groups = {};

  for (const u of plus) {
    const name = u.subscriptionTitle || u.subscriptionPlan || "Unknown";
    groups[name] ??= { name, price: u.subscriptionPrice, count: 0 };
    groups[name].count++;
  }

  return Object.values(groups)
    .sort((a, b) => b.count - a.count)
    .map((g, i) => ({
      ...g,
      share: plus.length ? Math.round((g.count / plus.length) * 100) : 0,
      color: PLAN_COLORS[i % PLAN_COLORS.length],
    }));
}

// Running totals of users and Plus subscribers for each of the last 30 days
export function getGrowth(users, days = 30) {
  const created = users.map((u) => toDate(u.createdAt)).filter(Boolean);
  const subscribed = users
    .filter((u) => u.isPaid)
    .map((u) => toDate(u.subscriptionStartedAt))
    .filter(Boolean);

  const today = startOfToday();

  return Array.from({ length: days }, (_, i) => {
    const dayStart = new Date(today.getTime() - (days - 1 - i) * DAY);
    const dayEnd = new Date(dayStart.getTime() + DAY);
    return {
      day: dayStart.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
      users: created.filter((d) => d < dayEnd).length,
      plus: subscribed.filter((d) => d < dayEnd).length,
    };
  });
}

export function getDoctorStats(doctors) {
  return {
    total: doctors.length,
    active: doctors.filter((d) => d.isActive).length,
    available: doctors.filter((d) => d.available).length,
  };
}

// scans = [{ type: 'meals', userId }, ...] from today's uploads
export function getScanStats(scans, users) {
  const counts = { medicines: 0, meals: 0, reports: 0 };
  const perUser = {};

  for (const s of scans) {
    counts[s.type] = (counts[s.type] ?? 0) + 1;
    perUser[s.userId] = (perUser[s.userId] ?? 0) + 1;
  }

  const plusIds = new Set(
    users.filter((u) => isActivePlus(u)).map((u) => u.id),
  );
  const limitHitUsers = Object.entries(perUser).filter(
    ([userId, count]) => count >= 5 && !plusIds.has(userId),
  ).length;

  return { counts, limitHitUsers };
}
