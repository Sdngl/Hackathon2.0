import { useMemo, useState } from "react";
import { deleteField } from "firebase/firestore";
import { LoaderCircle } from "lucide-react";
import TagInput from "../TagInput";
import PhotoUpload from "../PhotoUpload";
import { useAdmin } from "../../context/AdminContext";
import { SPECIALIZATIONS, SPOKEN_LANGUAGES } from "../../lib/specializations";

// Which form control each doctor field uses
const TEXT = [
  "name",
  "qualification",
  "hospital",
  "clinicName",
  "clinicAddress",
  "clinicHours",
  "phone",
  "email",
  "imageUrl",
];
const NUMBER = [
  "rating",
  "reviewCount",
  "patientCount",
  "experienceYears",
  "consultationFee",
];
const LIST = ["specialization", "specialties", "languages", "availableSlots"]; // picked with the tag picker

// 8:00 AM to 8:00 PM every 30 minutes, as suggestions for Available slots
const SLOT_SUGGESTIONS = Array.from({ length: 25 }, (_, i) => {
  const minutes = 8 * 60 + i * 30;
  const h = Math.floor(minutes / 60);
  const m = String(minutes % 60).padStart(2, "0");
  return `${h % 12 || 12}:${m} ${h < 12 ? "AM" : "PM"}`;
});
const TOGGLE = ["verified", "available", "isActive"];

const LABELS = {
  name: "Full name",
  qualification: "Qualification",
  hospital: "Hospital",
  clinicName: "Clinic name",
  clinicAddress: "Clinic address",
  clinicHours: "Clinic hours",
  phone: "Phone",
  email: "Email",
  imageUrl: "Photo URL",
  rating: "Rating (0–5)",
  reviewCount: "Reviews",
  patientCount: "Patients",
  experienceYears: "Experience (years)",
  consultationFee: "Consultation fee (Rs.)",
  specialization: "Specialization",
  specialties: "Specialties",
  languages: "Languages",
  availableSlots: "Available slots",
  verified: "Verified",
  available: "Available now",
  isActive: "Active on SEVA",
  about: "About",
};

function toForm(doctor) {
  const form = {};
  for (const k of TEXT) form[k] = doctor[k] ?? "";
  form.hospital ||= doctor.Clinic ?? ""; // older documents store the hospital as "Clinic"
  for (const k of NUMBER) form[k] = doctor[k] ?? "";
  for (const k of LIST)
    form[k] = Array.isArray(doctor[k])
      ? doctor[k]
      : doctor[k]
        ? [doctor[k]]
        : [];
  for (const k of TOGGLE) form[k] = !!doctor[k];
  form.about = doctor.about ?? "";
  return form;
}

// Converts the form back into Firestore values.
// A blank field that the document never had is skipped; a blank field that did exist is
// cleared ("" or []) rather than removed, so the mobile app always finds the field it expects.
function toFirestore(form, original) {
  const out = {};
  const had = (k) => k in original;

  for (const k of [...TEXT, "about"]) {
    const v = form[k].trim();
    if (v || had(k)) out[k] = v;
  }
  for (const k of NUMBER) {
    if (form[k] !== "") out[k] = Number(form[k]);
    else if (had(k)) out[k] = deleteField();
  }
  for (const k of LIST) {
    const items = form[k];
    if (items.length === 0 && !had(k)) continue;
    // specialization is a plain string in some documents; keep it that way if it was
    const keepString = typeof original[k] === "string" && items.length <= 1;
    out[k] = keepString ? (items[0] ?? "") : items;
  }
  for (const k of TOGGLE) out[k] = form[k];
  return out;
}

const input =
  "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

function Section({ title, children }) {
  return (
    <fieldset className="rounded-3xl border border-black/5 bg-white p-6">
      <legend className="sr-only">{title}</legend>
      <h2 className="font-semibold">{title}</h2>
      <div className="mt-4 grid gap-4 sm:grid-cols-2">{children}</div>
    </fieldset>
  );
}

export default function DoctorForm({
  doctor,
  onSave,
  onCancel,
  submitLabel = "Save changes",
}) {
  const [form, setForm] = useState(() => toForm(doctor));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const { doctors } = useAdmin();

  // the built-in list plus anything other doctors already use
  const specialtySuggestions = useMemo(
    () =>
      [
        ...new Set([
          ...SPECIALIZATIONS,
          ...doctors
            .flatMap((d) => [d.specialization, d.specialties].flat())
            .filter(Boolean),
        ]),
      ].sort(),
    [doctors],
  );

  const set = (key) => (e) =>
    setForm((f) => ({
      ...f,
      [key]: e.target.type === "checkbox" ? e.target.checked : e.target.value,
    }));

  const tags = (key, suggestions, placeholder, wide) => (
    <label
      key={key}
      htmlFor={`doctor-${key}`}
      className={`block text-sm font-medium ${wide ? "sm:col-span-2" : ""}`}
    >
      {LABELS[key]}
      <TagInput
        id={`doctor-${key}`}
        value={form[key]}
        onChange={(list) => setForm((f) => ({ ...f, [key]: list }))}
        suggestions={suggestions}
        placeholder={placeholder}
      />
    </label>
  );

  const field = (key, props = {}) => (
    <label
      key={key}
      className={`block text-sm font-medium ${props.wide ? "sm:col-span-2" : ""}`}
    >
      {LABELS[key]}
      {props.hint && (
        <span className="ml-1 text-xs font-normal text-gray-400">
          {props.hint}
        </span>
      )}
      <input
        value={form[key]}
        onChange={set(key)}
        className={input}
        type={props.type ?? "text"}
        step={props.step}
        min={props.min}
        max={props.max}
        required={props.required}
      />
    </label>
  );

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true);
    setError("");
    try {
      await onSave(toFirestore(form, doctor));
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to edit doctors."
          : err.message,
      );
      setSaving(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <Section title="Profile">
        {field("name", { required: true })}
        {field("qualification")}
        {tags("specialization", specialtySuggestions, "e.g. Cardiologist")}
        {tags("specialties", specialtySuggestions, "e.g. Metabolic Health")}
        <PhotoUpload
          value={form.imageUrl}
          onChange={(url) => setForm((f) => ({ ...f, imageUrl: url }))}
          name={form.name || "?"}
        />
        <label className="block text-sm font-medium sm:col-span-2">
          {LABELS.about}
          <textarea
            value={form.about}
            onChange={set("about")}
            rows={4}
            className={input}
          />
        </label>
      </Section>

      <Section title="Numbers">
        {field("experienceYears", { type: "number", min: 0 })}
        {field("consultationFee", { type: "number", min: 0 })}
        {field("rating", { type: "number", min: 0, max: 5, step: 0.1 })}
        {field("reviewCount", { type: "number", min: 0 })}
        {field("patientCount", { type: "number", min: 0 })}
      </Section>

      <Section title="Clinic & contact">
        {field("hospital")}
        {field("clinicName")}
        {field("clinicAddress")}
        {field("clinicHours")}
        {field("phone", { type: "tel" })}
        {field("email", { type: "email" })}
        {tags("languages", SPOKEN_LANGUAGES, "e.g. Nepali")}
        {tags("availableSlots", SLOT_SUGGESTIONS, "e.g. 10:00 AM")}
      </Section>

      <Section title="Status">
        {TOGGLE.map((key) => (
          <label
            key={key}
            className="flex items-center gap-3 rounded-xl border border-black/10 px-4 py-3 text-sm font-medium"
          >
            <input
              type="checkbox"
              checked={form[key]}
              onChange={set(key)}
              className="h-4 w-4 accent-brand-700"
            />
            {LABELS[key]}
          </label>
        ))}
      </Section>

      {error && (
        <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onCancel}
          className="rounded-full border border-black/10 bg-white px-5 py-2.5 text-sm font-semibold hover:bg-mist"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={saving}
          className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
        >
          {saving && <LoaderCircle size={15} className="animate-spin" />}
          {submitLabel}
        </button>
      </div>
    </form>
  );
}
