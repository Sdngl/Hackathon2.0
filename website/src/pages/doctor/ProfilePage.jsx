import { useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { BadgeCheck } from "lucide-react";
import { db } from "../../lib/firebase";
import { useDoctor } from "../../context/DoctorContext";
import { Avatar, Card } from "../../components/admin/ui";
import TagInput from "../../components/TagInput";
import PhotoUpload from "../../components/PhotoUpload";
import SaveButton from "../../components/admin/settings/SaveButton";
import { Field, inputClass } from "../../components/admin/settings/fields";
import { SPECIALIZATIONS, SPOKEN_LANGUAGES } from "../../lib/specializations";

const TEXT = [
  "qualification",
  "about",
  "hospital",
  "clinicName",
  "clinicAddress",
  "phone",
  "email",
  "imageUrl",
];
const asList = (v) => (Array.isArray(v) ? v : v ? [v] : []);

function toForm(d) {
  const form = {};
  for (const k of TEXT) form[k] = d[k] ?? "";
  form.hospital ||= d.Clinic ?? "";
  form.consultationFee = d.consultationFee ?? "";
  form.specialties = asList(d.specialties);
  form.languages = asList(d.languages);
  return form;
}

function ProfileForm({ doctor }) {
  const [form, setForm] = useState(() => toForm(doctor));
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));
  const original = toForm(doctor);
  const changed = JSON.stringify(form) !== JSON.stringify(original);

  async function save() {
    // only send what changed
    const changes = {};
    for (const k of TEXT)
      if (form[k] !== original[k]) changes[k] = form[k].trim();
    if (form.consultationFee !== original.consultationFee)
      changes.consultationFee =
        form.consultationFee === "" ? 0 : Number(form.consultationFee);
    for (const k of ["specialties", "languages"])
      if (JSON.stringify(form[k]) !== JSON.stringify(original[k]))
        changes[k] = form[k];
    if (changes.hospital !== undefined) changes.Clinic = changes.hospital; // keep the older field the app reads in sync
    await updateDoc(doc(db, "doctors", doctor.id), changes);
  }

  const specs = asList(doctor.specialization).join(", ");

  return (
    <div className="space-y-5">
      <Card>
        <div className="flex flex-wrap items-center gap-5">
          <Avatar
            name={doctor.name ?? "?"}
            photo={form.imageUrl || doctor.imageUrl}
            size="h-20 w-20 text-xl"
          />
          <div className="flex-1">
            <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
              {doctor.name}
              {doctor.verified && (
                <BadgeCheck
                  size={22}
                  className="text-blue-500"
                  aria-label="Verified"
                />
              )}
            </h1>
            <p className="mt-1 text-sm text-gray-600">{specs}</p>
            <p className="mt-2 text-xs text-gray-500">
              Name, specialization and NMC number (
              {doctor.licenseNumber || "not set"}) are verified by SEVA. Contact
              the SEVA team to change them.
            </p>
          </div>
        </div>
      </Card>

      <Card title="About">
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <PhotoUpload
            value={form.imageUrl}
            onChange={(url) => setForm((f) => ({ ...f, imageUrl: url }))}
            name={doctor.name}
          />
          <Field label="Qualification">
            <input
              value={form.qualification}
              onChange={set("qualification")}
              className={inputClass}
              placeholder="MBBS, MD"
            />
          </Field>
          <label
            className="block text-sm font-medium sm:col-span-2"
            htmlFor="specialties"
          >
            Special interests
            <TagInput
              id="specialties"
              value={form.specialties}
              onChange={(v) => setForm((f) => ({ ...f, specialties: v }))}
              suggestions={SPECIALIZATIONS}
              placeholder="e.g. Diabetes care"
            />
          </label>
          <label className="block text-sm font-medium sm:col-span-2">
            About you
            <textarea
              rows={4}
              maxLength={600}
              value={form.about}
              onChange={set("about")}
              className={inputClass}
              placeholder="A few lines patients will see on your profile"
            />
          </label>
        </div>
      </Card>

      <Card title="Clinic & contact">
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <Field label="Hospital">
            <input
              value={form.hospital}
              onChange={set("hospital")}
              className={inputClass}
            />
          </Field>
          <Field label="Clinic name">
            <input
              value={form.clinicName}
              onChange={set("clinicName")}
              className={inputClass}
            />
          </Field>
          <Field label="Clinic address">
            <input
              value={form.clinicAddress}
              onChange={set("clinicAddress")}
              className={inputClass}
            />
          </Field>
          <Field label="Consultation fee (Rs.)">
            <input
              type="number"
              min="0"
              value={form.consultationFee}
              onChange={set("consultationFee")}
              className={inputClass}
            />
          </Field>
          <Field label="Phone">
            <input
              type="tel"
              value={form.phone}
              onChange={set("phone")}
              className={inputClass}
            />
          </Field>
          <Field
            label="Contact email"
            hint="Shown to patients; your login email doesn't change"
          >
            <input
              type="email"
              value={form.email}
              onChange={set("email")}
              className={inputClass}
            />
          </Field>
          <label
            className="block text-sm font-medium sm:col-span-2"
            htmlFor="languages"
          >
            Languages you speak
            <TagInput
              id="languages"
              value={form.languages}
              onChange={(v) => setForm((f) => ({ ...f, languages: v }))}
              suggestions={SPOKEN_LANGUAGES}
              placeholder="e.g. Nepali"
            />
          </label>
        </div>
      </Card>

      <div className="sticky bottom-4 rounded-2xl border border-black/5 bg-white/95 p-3 shadow-lg backdrop-blur">
        <SaveButton disabled={!changed} onSave={save} />
      </div>
    </div>
  );
}

// /doctor/profile
export default function DoctorProfilePage() {
  const { doctor } = useDoctor();
  return <ProfileForm doctor={doctor} />;
}
