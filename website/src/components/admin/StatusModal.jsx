import { useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { LoaderCircle } from "lucide-react";
import Modal from "./Modal";
import { db } from "../../lib/firebase";
import {
  STATUS_OPTIONS,
  capitalize,
  formatStatusForSave,
} from "../../lib/appointments";

export default function StatusModal({ appointment, onClose }) {
  const [status, setStatus] = useState(appointment.status);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  // keep any status the app uses that isn't in our list (e.g. "Pending")
  const options = STATUS_OPTIONS.includes(appointment.status)
    ? STATUS_OPTIONS
    : [appointment.status, ...STATUS_OPTIONS];

  async function save() {
    setSaving(true);
    setError("");
    try {
      await updateDoc(doc(db, appointment.path), {
        status: formatStatusForSave(status, appointment.rawStatus),
      });
      onClose();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to update appointments."
          : err.message,
      );
      setSaving(false);
    }
  }

  return (
    <Modal
      title="Update appointment"
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
            disabled={saving || status === appointment.status}
            className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-50"
          >
            {saving && <LoaderCircle size={15} className="animate-spin" />}
            Save status
          </button>
        </>
      }
    >
      <div className="rounded-2xl bg-mist p-4 text-sm">
        <p className="font-semibold">{appointment.patient}</p>
        <p className="mt-0.5 text-gray-500">
          {appointment.doctor} · {appointment.dateLabel} · {appointment.time}
        </p>
      </div>

      <fieldset className="mt-5">
        <legend className="text-sm font-medium">Status</legend>
        <div className="mt-2 grid grid-cols-2 gap-2">
          {options.map((option) => (
            <label
              key={option}
              className={`flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-2.5 text-sm transition-colors ${
                status === option
                  ? "border-brand-500 bg-brand-50 font-semibold text-brand-700"
                  : "border-black/10 hover:bg-mist"
              }`}
            >
              <input
                type="radio"
                name="status"
                value={option}
                checked={status === option}
                onChange={() => setStatus(option)}
                className="accent-brand-700"
              />
              {capitalize(option)}
            </label>
          ))}
        </div>
      </fieldset>

      {error && (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}
    </Modal>
  );
}
