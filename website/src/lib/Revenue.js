// Subscription and revenue numbers, calculated from the subscription fields on each user.
// Note: each user document only stores their CURRENT subscription, so renewals
// replace the old one. Revenue here = subscriptions that started in the period.
import { isActivePlus, startOfToday, toDate } from "./dashboardStats";

const DAY = 24 * 60 * 60 * 1000;

const isTest = (u) => u.paymentMode === "test";
const price = (u) => Number(u.subscriptionPrice) || 0;

// All users who have paid at some point, optionally ignoring test payments
export function paidUsers(users, includeTest) {
  return users.filter((u) => u.isPaid && (includeTest || !isTest(u)));
}

// What one subscription is worth per month (Rs. 799 for 6 months = Rs. 133/month)
function monthlyValue(u) {
  const months = Number(u.subscriptionMonths) || 1;
  return price(u) / months;
}

export function subscriptionState(u, now = new Date()) {
  if (!isActivePlus(u, now)) return "Expired";
  if (u.subscriptionCancelAtPeriodEnd) return "Cancelling";
  const expires = toDate(u.subscriptionExpiresAt);
  if (expires && expires - now < 7 * DAY) return "Expiring";
  return "Active";
}

export function getRevenueStats(users, includeTest) {
  const paid = paidUsers(users, includeTest);
  const now = new Date();
  const today = startOfToday();
  const monthAgo = new Date(now - 30 * DAY);
  const startedSince = (since) =>
    paid.filter((u) => toDate(u.subscriptionStartedAt) >= since);
  const sum = (list) => list.reduce((total, u) => total + price(u), 0);

  const active = paid.filter((u) => isActivePlus(u, now));
  const states = active.map((u) => subscriptionState(u, now));

  return {
    today: sum(startedSince(today)),
    todayCount: startedSince(today).length,
    month: sum(startedSince(monthAgo)),
    monthCount: startedSince(monthAgo).length,
    lifetime: sum(paid),
    active: active.length,
    mrr: Math.round(active.reduce((total, u) => total + monthlyValue(u), 0)),
    expiring: states.filter((s) => s === "Expiring").length,
    cancelling: states.filter((s) => s === "Cancelling").length,
    conversion: users.length
      ? Math.round((active.length / users.length) * 100)
      : 0,
  };
}

// Revenue for each of the last `days` days, for the bar chart
export function dailyRevenue(users, includeTest, days = 30) {
  const paid = paidUsers(users, includeTest);
  const today = startOfToday();

  return Array.from({ length: days }, (_, i) => {
    const start = new Date(today.getTime() - (days - 1 - i) * DAY);
    const end = new Date(start.getTime() + DAY);
    const started = paid.filter((u) => {
      const d = toDate(u.subscriptionStartedAt);
      return d && d >= start && d < end;
    });
    return {
      day: start.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
      revenue: started.reduce((total, u) => total + price(u), 0),
      count: started.length,
    };
  });
}

// One row per plan: price, active subscribers, total collected
export function planTable(users, includeTest) {
  const groups = {};
  for (const u of paidUsers(users, includeTest)) {
    const name = u.subscriptionTitle || u.subscriptionPlan || "Unknown";
    groups[name] ??= {
      name,
      price: price(u),
      months: u.subscriptionMonths,
      active: 0,
      total: 0,
      revenue: 0,
    };
    groups[name].total++;
    groups[name].revenue += price(u);
    if (isActivePlus(u)) groups[name].active++;
  }
  return Object.values(groups).sort((a, b) => b.revenue - a.revenue);
}

// Subscription list, newest first, filtered by state ('all' | 'Active' | 'Expiring' | ...)
export function subscriptionRows(users, includeTest, state = "all") {
  const now = new Date();
  return paidUsers(users, includeTest)
    .map((u) => ({ ...u, state: subscriptionState(u, now) }))
    .filter((u) => state === "all" || u.state === state)
    .sort(
      (a, b) =>
        (toDate(b.subscriptionStartedAt)?.getTime() ?? 0) -
        (toDate(a.subscriptionStartedAt)?.getTime() ?? 0),
    );
}
