import { useState } from "react";
import { Timestamp, doc, serverTimestamp, updateDoc } from "firebase/firestore";
import { LoaderCircle } from "lucide-react";
import { db } from "../../lib/firebase";
import Modal from "../admin/Modal";
import { formatStatusForSave } from "../../lib/appointments";

// "2:30 PM" → { h: 14, m: 30 }
function parseSlot(slot) {
  const match = slot.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (!match) return null;
  const [, h, m, ap] = match;
  return {
    h: (Number(h) % 12) + (ap.toUpperCase() === "PM" ? 12 : 0),
    m: Number(m),
  };
}

// "14:30" (from <input type="time">) → "2:30 PM"
function toSlotLabel(value) {
  const [h, m] = value.split(":").map(Number);
  return `${h % 12 || 12}:${String(m).padStart(2, "0")} ${h < 12 ? "AM" : "PM"}`;
}

// a Date → "2026-09-21", the format <input type="date"> uses
function toInput(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}
const todayInput = () => toInput(new Date()); // stops picking a past date

// Doctor picks the date and time for a clinic booking (or moves an existing one)
export default function ScheduleModal({ appointment: a, slots = [], onClose }) {
  const [date, setDate] = useState(() => (a.date ? toInput(a.date) : "")); // rescheduling starts on the current date
  const [slot, setSlot] = useState(a.date && a.time !== "—" ? a.time : "");
  const [custom, setCustom] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const time = custom ? toSlotLabel(custom) : slot;
  const ready = date && time;

  async function save() {
    const parsed = parseSlot(time);
    if (!parsed) return setError("Pick a time.");
    const [y, mo, d] = date.split("-").map(Number);
    const when = new Date(y, mo - 1, d, parsed.h, parsed.m);
    if (when < new Date())
      return setError("That time has already passed. Pick a later one.");

    setSaving(true);
    setError("");
    try {
      await updateDoc(doc(db, a.path), {
        appointmentDate: Timestamp.fromDate(when), // full date + time, easy for the app to read
        appointmentTime: time, // "10:30 AM", for display
        status: formatStatusForSave("Confirmed", a.rawStatus),
        scheduledAt: serverTimestamp(),
      });
      onClose();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to schedule this appointment."
          : err.message,
      );
      setSaving(false);
    }
  }

  const input =
    "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

  return (
    <Modal
      title={a.date ? "Reschedule appointment" : "Set appointment time"}
      onClose={onClose}
      footer={
        <>
          <button
            onClick={onClose}
            className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
          >
            Cancel
          </button>
          <button
            onClick={save}
            disabled={!ready || saving}
            className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-40"
          >
            {saving && <LoaderCircle size={15} className="animate-spin" />}{" "}
            Confirm time
          </button>
        </>
      }
    >
      <div className="rounded-2xl bg-mist p-4 text-sm">
        <p className="font-semibold">{a.patient}</p>
        <p className="mt-0.5 text-gray-500">
          {a.type}
          {a.bookedLabel ? ` · requested ${a.bookedLabel}` : ""}
        </p>
      </div>

      <label className="mt-5 block text-sm font-medium">
        Date
        <input
          type="date"
          min={todayInput()}
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className={input}
        />
      </label>

      <p className="mt-4 text-sm font-medium">Time</p>
      {slots.length > 0 ? (
        <div className="mt-2 flex flex-wrap gap-2">
          {slots.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => {
                setSlot(s);
                setCustom("");
              }}
              className={`rounded-xl border px-3.5 py-2 text-sm transition-colors ${
                !custom && slot === s
                  ? "border-brand-500 bg-brand-50 font-semibold text-brand-700"
                  : "border-black/10 hover:bg-mist"
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      ) : (
        <p className="mt-1 text-xs text-gray-500">
          Add your usual time slots on the Availability page to pick them here.
        </p>
      )}
      <label className="mt-3 block text-xs text-gray-500">
        Or another time
        <input
          type="time"
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
          className={input}
        />
      </label>

      <p className="mt-4 text-xs text-gray-500">
        The patient sees the confirmed date and time in the app.
      </p>
      {error && (
        <p className="mt-3 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}
    </Modal>
  );
}
