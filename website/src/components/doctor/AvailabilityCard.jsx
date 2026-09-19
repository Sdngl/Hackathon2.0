import { useState } from "react";
import { Link } from "react-router";
import { doc, updateDoc } from "firebase/firestore";
import { db } from "../../lib/firebase";
import { Card } from "../admin/ui";
import { SwitchRow } from "../admin/settings/fields";

// Quick on/off for bookings, plus today's open slots
export default function AvailabilityCard({ doctor }) {
  const [error, setError] = useState("");
  const slots = Array.isArray(doctor.availableSlots)
    ? doctor.availableSlots
    : [];

  async function toggle(on) {
    setError("");
    try {
      await updateDoc(doc(db, "doctors", doctor.id), { available: on });
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to change this."
          : err.message,
      );
    }
  }

  return (
    <Card
      title="Availability"
      action={
        <Link
          to="/doctor/availability"
          className="text-sm font-semibold text-brand-700 hover:underline"
        >
          Edit
        </Link>
      }
    >
      <SwitchRow
        label="Accepting bookings"
        hint="Turn off when you're away; patients won't see you as available"
        checked={!!doctor.available}
        onChange={toggle}
      />
      <p className="mt-2 text-xs font-medium text-gray-500">Your time slots</p>
      <div className="mt-2 flex flex-wrap gap-2">
        {slots.length ? (
          slots.map((s) => (
            <span
              key={s}
              className="rounded-full bg-mist px-3 py-1 text-xs font-medium"
            >
              {s}
            </span>
          ))
        ) : (
          <Link
            to="/doctor/availability"
            className="text-sm text-brand-700 hover:underline"
          >
            Add your time slots →
          </Link>
        )}
      </div>
      {error && (
        <p className="mt-3 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}
    </Card>
  );
}
