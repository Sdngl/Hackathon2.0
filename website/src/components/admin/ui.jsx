// Small shared building blocks for admin pages

export function Card({ title, subtitle, action, children, className = "" }) {
  return (
    <section
      className={`rounded-3xl border border-black/5 bg-white p-6 ${className}`}
    >
      {(title || action) && (
        <div className="flex items-start justify-between gap-4">
          <div>
            {title && <h2 className="font-semibold">{title}</h2>}
            {subtitle && (
              <p className="mt-0.5 text-xs text-gray-500">{subtitle}</p>
            )}
          </div>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}

const pillColors = {
  Pending: "bg-amber-50 text-amber-600",
  Review: "bg-amber-50 text-amber-600",
  Approved: "bg-brand-50 text-brand-700",
  Completed: "bg-brand-50 text-brand-700",
  Rejected: "bg-red-50 text-red-600",
  Ongoing: "bg-blue-50 text-blue-600",
  Active: "bg-brand-50 text-brand-700",
  Inactive: "bg-gray-100 text-gray-600",
  Available: "bg-blue-50 text-blue-600",
  Busy: "bg-amber-50 text-amber-600",
  Scheduled: "bg-gray-100 text-gray-600",
  Cancelled: "bg-red-50 text-red-600",
  Confirmed: "bg-brand-50 text-brand-700",
  Verified: "bg-blue-50 text-blue-600",
  Plus: "bg-violet-50 text-violet-600",
  Free: "bg-gray-100 text-gray-600",
  Expired: "bg-red-50 text-red-600",
};

export function StatusPill({ status, className = "" }) {
  return (
    <span
      className={`inline-block rounded-md px-2 py-0.5 text-xs font-semibold ${pillColors[status] ?? pillColors.Scheduled} ${className}`}
    >
      {status}
    </span>
  );
}

export function Avatar({ name, photo, size = "h-10 w-10" }) {
  if (photo)
    return (
      <img src={photo} alt="" className={`${size} rounded-full object-cover`} />
    );
  const initials = String(name)
    .replace("Dr. ", "")
    .split(" ")
    .map((w) => w[0])
    .join("")
    .slice(0, 2);
  return (
    <span
      className={`grid shrink-0 place-items-center rounded-full bg-brand-50 font-bold text-brand-700 ${size.includes("text-") ? "" : "text-[11px]"} ${size}`}
    >
      {initials}
    </span>
  );
}

// Marks widgets that still show placeholder data
export function SampleTag() {
  return (
    <span className="rounded-full bg-gray-100 px-2.5 py-1 text-[10px] font-semibold text-gray-500">
      Sample data
    </span>
  );
}
