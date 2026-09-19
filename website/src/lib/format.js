import { toDate } from "./dashboardStats";

// "Sep 19, 2026" (or "—" when missing)
export function formatDate(value) {
  const d = toDate(value);
  return d
    ? d.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : "—";
}

// "2 hours ago", "3 days ago", or a date for anything older than a month
export function timeAgo(value) {
  const d = toDate(value);
  if (!d) return "—";
  const minutes = Math.round((Date.now() - d.getTime()) / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours} hr${hours > 1 ? "s" : ""} ago`;
  const days = Math.round(hours / 24);
  if (days < 30) return `${days} day${days > 1 ? "s" : ""} ago`;
  return formatDate(d);
}

export const npr = (n) => `Rs. ${Number(n || 0).toLocaleString("en-IN")}`;
