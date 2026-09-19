import { Link, useParams } from "react-router";
import {
  ArrowLeft,
  Bell,
  CalendarDays,
  Clock,
  CreditCard,
  FileText,
  Fingerprint,
  LoaderCircle,
  Pill,
  UtensilsCrossed,
} from "lucide-react";
import useDocument from "../../hooks/useDocument";
import useCollection from "../../hooks/useCollection";
import { Avatar, Card, StatusPill } from "../../components/admin/ui";
import { planStatus } from "../../lib/users";
import { formatDate, npr, timeAgo } from "../../lib/format";

function Row({ label, value }) {
  return (
    <div className="flex justify-between gap-4 py-2.5 text-sm">
      <dt className="text-gray-500">{label}</dt>
      <dd className="text-right font-medium">{value ?? "—"}</dd>
    </div>
  );
}

// Counts the documents in one of the user's subcollections
function useCount(userId, name) {
  const { data, loading } = useCollection(`users/${userId}/${name}`);
  return loading ? "…" : data.length;
}

// /admin/users/:id (view only: users manage their own accounts in the app)
export default function UserDetail() {
  const { id } = useParams();
  const { data: user, loading, error } = useDocument("users", id);

  const counts = {
    appointments: useCount(id, "appointments"),
    medicines: useCount(id, "medicines"),
    meals: useCount(id, "meals"),
    reports: useCount(id, "reports"),
  };

  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );

  if (error || !user) {
    return (
      <Card>
        <p className="font-semibold">
          {error ? "Couldn't load this user." : "User not found."}
        </p>
        <p className="mt-1 text-sm text-gray-500">{error?.message}</p>
        <Link
          to="/admin/users"
          className="mt-4 inline-block text-sm font-semibold text-brand-700"
        >
          ← Back to users
        </Link>
      </Card>
    );
  }

  const status = planStatus(user);

  return (
    <div className="space-y-5">
      <Link
        to="/admin/users"
        className="flex w-fit items-center gap-1.5 text-sm text-gray-600 hover:text-ink"
      >
        <ArrowLeft size={16} /> All users
      </Link>

      <Card>
        <div className="flex flex-wrap items-center gap-5">
          <Avatar
            name={user.displayName || user.email || "?"}
            photo={user.photoUrl}
            size="h-20 w-20 text-xl"
          />
          <div className="flex-1">
            <h1 className="text-2xl font-bold tracking-tight">
              {user.displayName || "No name"}
            </h1>
            <p className="mt-1 text-sm text-gray-600">{user.email}</p>
            <div className="mt-3">
              <StatusPill status={status} />
            </div>
          </div>
        </div>
      </Card>

      <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {[
          {
            icon: CalendarDays,
            label: "Appointments",
            value: counts.appointments,
            tint: "bg-brand-50 text-brand-700",
          },
          {
            icon: Pill,
            label: "Medicines scanned",
            value: counts.medicines,
            tint: "bg-amber-50 text-amber-600",
          },
          {
            icon: UtensilsCrossed,
            label: "Meals logged",
            value: counts.meals,
            tint: "bg-orange-50 text-orange-500",
          },
          {
            icon: FileText,
            label: "Reports uploaded",
            value: counts.reports,
            tint: "bg-blue-50 text-blue-600",
          },
        ].map(({ icon: Icon, label, value, tint }) => (
          <div
            key={label}
            className="rounded-3xl border border-black/5 bg-white p-5"
          >
            <span
              className={`grid h-9 w-9 place-items-center rounded-xl ${tint}`}
            >
              <Icon size={18} />
            </span>
            <p className="mt-3 text-2xl font-bold tracking-tight">{value}</p>
            <p className="text-xs text-gray-500">{label}</p>
          </div>
        ))}
      </div>

      <div className="grid gap-5 xl:grid-cols-2">
        <Card
          title="Subscription"
          action={<CreditCard size={18} className="text-gray-400" />}
        >
          <dl className="mt-3 divide-y divide-black/5">
            <Row
              label="Plan"
              value={
                status === "Free"
                  ? "Free"
                  : (user.subscriptionTitle ?? user.subscriptionPlan)
              }
            />
            {status !== "Free" && (
              <>
                <Row
                  label="Price"
                  value={
                    user.subscriptionPrice != null
                      ? npr(user.subscriptionPrice)
                      : null
                  }
                />
                <Row
                  label="Started"
                  value={formatDate(user.subscriptionStartedAt)}
                />
                <Row
                  label={status === "Expired" ? "Expired" : "Renews / expires"}
                  value={formatDate(user.subscriptionExpiresAt)}
                />
                <Row
                  label="Cancels at period end"
                  value={user.subscriptionCancelAtPeriodEnd ? "Yes" : "No"}
                />
                <Row
                  label="Paid with"
                  value={[
                    user.paymentProvider,
                    user.paymentMode === "test" ? "(test)" : null,
                  ]
                    .filter(Boolean)
                    .join(" ")}
                />
              </>
            )}
          </dl>
        </Card>

        <Card
          title="Account"
          action={<Fingerprint size={18} className="text-gray-400" />}
        >
          <dl className="mt-3 divide-y divide-black/5">
            <Row label="Joined" value={formatDate(user.createdAt)} />
            <Row
              label="Last active"
              value={
                <span className="flex items-center gap-1.5">
                  <Clock size={13} />
                  {timeAgo(user.lastLoginAt)}
                </span>
              }
            />
            <Row
              label="Medicine reminders"
              value={
                <span className="flex items-center gap-1.5">
                  <Bell size={13} />
                  {user.medicineAlarms ? "On" : "Off"}
                </span>
              }
            />
            <Row
              label="User ID"
              value={
                <code className="text-xs text-gray-500">
                  {user.uid ?? user.id}
                </code>
              }
            />
          </dl>
        </Card>
      </div>
    </div>
  );
}
