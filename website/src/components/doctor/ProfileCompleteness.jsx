import { Link } from "react-router";
import { CircleCheck } from "lucide-react";
import { Card } from "../admin/ui";
import { profileCompleteness } from "../../lib/doctorStats";

// How much of the profile patients see is filled in
export default function ProfileCompleteness({ doctor }) {
  const { percent, missing } = profileCompleteness(doctor);

  return (
    <Card title="Your profile" subtitle="A complete profile gets more bookings">
      <div className="mt-4 flex items-end justify-between">
        <p className="text-3xl font-bold tracking-tight">{percent}%</p>
        <p className="text-sm text-gray-500">complete</p>
      </div>
      <div className="mt-3 h-2.5 rounded-full bg-gray-100">
        <div
          className="h-full rounded-full bg-brand-500 transition-all"
          style={{ width: `${percent}%` }}
        />
      </div>

      {missing.length === 0 ? (
        <p className="mt-4 flex items-center gap-2 text-sm font-medium text-brand-700">
          <CircleCheck size={16} /> Everything is filled in.
        </p>
      ) : (
        <>
          <p className="mt-4 text-xs font-medium text-gray-500">
            Still missing
          </p>
          <div className="mt-2 flex flex-wrap gap-2">
            {missing.map((f) => (
              <span
                key={f.key}
                className="rounded-full bg-amber-50 px-3 py-1 text-xs font-medium text-amber-700"
              >
                {f.label}
              </span>
            ))}
          </div>
          <Link
            to="/doctor/profile"
            className="mt-4 inline-block text-sm font-semibold text-brand-700 hover:underline"
          >
            Complete your profile →
          </Link>
        </>
      )}
    </Card>
  );
}
