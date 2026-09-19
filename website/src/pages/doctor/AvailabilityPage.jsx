import { useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { db } from "../../lib/firebase";
import { useDoctor } from "../../context/DoctorContext";
import { Card } from "../../components/admin/ui";
import TagInput from "../../components/TagInput";
import SaveButton from "../../components/admin/settings/SaveButton";
import {
  Field,
  SwitchRow,
  inputClass,
} from "../../components/admin/settings/fields";

// 7:00 AM to 8:00 PM every 30 minutes
const SLOT_SUGGESTIONS = Array.from({ length: 27 }, (_, i) => {
  const minutes = 7 * 60 + i * 30;
  const h = Math.floor(minutes / 60);
  return `${h % 12 || 12}:${String(minutes % 60).padStart(2, "0")} ${h < 12 ? "AM" : "PM"}`;
});

// Sort "2:00 PM" after "10:00 AM"
const toMinutes = (slot) => {
  const [, h, m, ap] = slot.match(/(\d+):(\d+)\s*(AM|PM)/i) ?? [];
  return h
    ? ((Number(h) % 12) + (ap.toUpperCase() === "PM" ? 12 : 0)) * 60 + Number(m)
    : 9999;
};

function AvailabilityForm({ doctor }) {
  const [available, setAvailable] = useState(!!doctor.available);
  const [slots, setSlots] = useState(
    Array.isArray(doctor.availableSlots) ? doctor.availableSlots : [],
  );
  const [hours, setHours] = useState(doctor.clinicHours ?? "");

  const changed =
    available !== !!doctor.available ||
    hours !== (doctor.clinicHours ?? "") ||
    JSON.stringify(slots) !== JSON.stringify(doctor.availableSlots ?? []);

  const save = () =>
    updateDoc(doc(db, "doctors", doctor.id), {
      available,
      availableSlots: [...slots].sort((a, b) => toMinutes(a) - toMinutes(b)),
      clinicHours: hours.trim(),
    });

  return (
    <div className="space-y-5">
      <Card title="Bookings">
        <SwitchRow
          label="Accepting bookings"
          hint="Turn off when you're on leave or fully booked"
          checked={available}
          onChange={setAvailable}
        />
      </Card>

      <Card
        title="Time slots"
        subtitle="The times patients can pick when booking you in the app"
      >
        <div className="mt-2">
          <TagInput
            value={slots}
            onChange={setSlots}
            suggestions={SLOT_SUGGESTIONS}
            placeholder="e.g. 10:00 AM"
          />
        </div>
        <p className="mt-2 text-xs text-gray-500">
          Type a time or pick one. They're sorted from morning to evening when
          you save.
        </p>
      </Card>

      <Card title="Clinic hours" subtitle="Shown on your profile">
        <div className="mt-2">
          <Field label="Hours">
            <input
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              className={inputClass}
              placeholder="Sun–Fri, 9:00 AM – 5:00 PM"
            />
          </Field>
        </div>
      </Card>

      <div className="sticky bottom-4 rounded-2xl border border-black/5 bg-white/95 p-3 shadow-lg backdrop-blur">
        <SaveButton disabled={!changed} onSave={save} />
      </div>
    </div>
  );
}

// /doctor/availability
export default function DoctorAvailabilityPage() {
  const { doctor } = useDoctor();
  // restart the form if the profile changes somewhere else
  return (
    <AvailabilityForm
      key={JSON.stringify([
        doctor.available,
        doctor.availableSlots,
        doctor.clinicHours,
      ])}
      doctor={doctor}
    />
  );
}
