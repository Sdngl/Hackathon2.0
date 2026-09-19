import { useState } from "react";
import { Link } from "react-router";
import { addDoc, collection } from "firebase/firestore";
import { ArrowLeft, CircleCheck, LoaderCircle } from "lucide-react";
import { db } from "../lib/firebase";
import Logo from "../components/Logo";
import TagInput from "../components/TagInput";
import { SPECIALIZATIONS, SPOKEN_LANGUAGES } from "../lib/specializations";
import { APPLICATIONS, applicationFromForm } from "../lib/applications";

const EMPTY = {
  name: "",
  email: "",
  phone: "",
  specialization: [],
  qualification: "",
  licenseNumber: "",
  experienceYears: "",
  hospital: "",
  clinicName: "",
  clinicAddress: "",
  consultationFee: "",
  languages: ["Nepali", "English"],
  about: "",
  agree: false,
  website: "", // hidden "honeypot" field: people never see it, spam bots fill it in
};

const input =
  "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

function Field({ label, hint, optional, children, wide, htmlFor }) {
  return (
    <label
      htmlFor={htmlFor}
      className={`block text-sm font-medium ${wide ? "sm:col-span-2" : ""}`}
    >
      {label}{" "}
      {optional && (
        <span className="font-normal text-gray-400">(optional)</span>
      )}
      {children}
      {hint && (
        <span className="mt-1 block text-xs font-normal text-gray-500">
          {hint}
        </span>
      )}
    </label>
  );
}

// Turns a Firebase error into something the doctor can act on
function friendlyError(err) {
  if (err.code === "permission-denied")
    return "The server refused the application (permission denied). Please tell the SEVA team.";
  if (err.code === "unavailable")
    return "No connection to the server. Check your internet and try again.";
  return `Something went wrong sending your application (${err.code ?? err.message}). Please try again.`;
}

function Section({ title, children }) {
  return (
    <fieldset className="rounded-3xl border border-black/5 bg-white p-6 sm:p-8">
      <legend className="sr-only">{title}</legend>
      <h2 className="text-lg font-semibold">{title}</h2>
      <div className="mt-5 grid gap-4 sm:grid-cols-2">{children}</div>
    </fieldset>
  );
}

// /join-doctor: public form, no login needed
export default function DoctorApplication() {
  const [form, setForm] = useState(EMPTY);
  const [status, setStatus] = useState("idle"); // idle | sending | sent
  const [error, setError] = useState("");
  const [showErrors, setShowErrors] = useState(false);
  const set = (key) => (e) =>
    setForm((f) => ({
      ...f,
      [key]: e.target.type === "checkbox" ? e.target.checked : e.target.value,
    }));
  const setList = (key) => (list) => setForm((f) => ({ ...f, [key]: list }));
  const missingSpecialization = form.specialization.length === 0;

  async function submit(e) {
    e.preventDefault();
    setError("");
    if (form.website) return setStatus("sent"); // a bot filled the hidden field: pretend it worked
    if (missingSpecialization) {
      setShowErrors(true);
      document.getElementById("specialization")?.focus();
      return;
    }
    setStatus("sending");
    try {
      await addDoc(collection(db, APPLICATIONS), applicationFromForm(form));
      setStatus("sent");
      window.scrollTo(0, 0);
    } catch (err) {
      console.error("Doctor application failed:", err); // full details in the browser console
      setError(friendlyError(err));
      setStatus("idle");
    }
  }

  return (
    <div className="min-h-screen bg-mist">
      <header className="mx-auto flex w-full max-w-3xl items-center justify-between px-5 py-5">
        <Logo />
        <Link
          to="/"
          className="flex items-center gap-1 text-sm text-gray-600 hover:text-ink"
        >
          <ArrowLeft size={16} /> Back to home
        </Link>
      </header>

      <main className="mx-auto max-w-3xl px-5 pb-20">
        {status === "sent" ? (
          <div className="rounded-3xl border border-black/5 bg-white px-6 py-16 text-center">
            <span className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-brand-50 text-brand-700">
              <CircleCheck size={28} />
            </span>
            <h1 className="mt-5 text-2xl font-bold tracking-tight">
              Application received
            </h1>
            <p className="mx-auto mt-2 max-w-md text-gray-600">
              Thank you{form.name ? `, ${form.name.split(" ")[0]}` : ""}. Our
              team will check your details and NMC registration, then contact
              you at <strong>{form.email}</strong>.
            </p>
            <Link
              to="/"
              className="mt-8 inline-block rounded-full bg-ink px-6 py-3 text-sm font-semibold text-white hover:bg-brand-800"
            >
              Back to SEVA
            </Link>
          </div>
        ) : (
          <>
            <h1 className="text-3xl font-bold tracking-tight">
              Join SEVA as a doctor
            </h1>
            <p className="mt-2 text-gray-600">
              Tell us about your practice. After we verify your registration,
              your profile goes live and patients can book you from the app.
            </p>

            <form onSubmit={submit} className="mt-8 space-y-5">
              <Section title="About you">
                <Field label="Full name">
                  <input
                    required
                    value={form.name}
                    onChange={set("name")}
                    className={input}
                    placeholder="Dr. Sita Rai"
                    autoComplete="name"
                  />
                </Field>
                <Field label="Qualification">
                  <input
                    required
                    value={form.qualification}
                    onChange={set("qualification")}
                    className={input}
                    placeholder="MBBS, MD (Pediatrics)"
                  />
                </Field>
                <Field
                  label="Specialization"
                  htmlFor="specialization"
                  hint={
                    showErrors && missingSpecialization ? (
                      <span className="text-red-600">
                        Add at least one specialization
                      </span>
                    ) : (
                      "Pick from the list or type your own. You can add several."
                    )
                  }
                >
                  <TagInput
                    id="specialization"
                    value={form.specialization}
                    onChange={setList("specialization")}
                    suggestions={SPECIALIZATIONS}
                    placeholder="e.g. Pediatrician"
                    invalid={showErrors && missingSpecialization}
                  />
                </Field>
                <Field label="Years of experience">
                  <input
                    required
                    type="number"
                    min="0"
                    max="70"
                    value={form.experienceYears}
                    onChange={set("experienceYears")}
                    className={input}
                  />
                </Field>
                <Field
                  label="NMC registration number"
                  hint="Used to verify you with the Nepal Medical Council"
                  wide
                >
                  <input
                    required
                    value={form.licenseNumber}
                    onChange={set("licenseNumber")}
                    className={input}
                    placeholder="NMC-12345"
                  />
                </Field>
              </Section>

              <Section title="Where you practise">
                <Field label="Hospital">
                  <input
                    required
                    value={form.hospital}
                    onChange={set("hospital")}
                    className={input}
                    placeholder="Grande Hospital"
                  />
                </Field>
                <Field label="Clinic name" optional>
                  <input
                    value={form.clinicName}
                    onChange={set("clinicName")}
                    className={input}
                  />
                </Field>
                <Field label="Address" wide>
                  <input
                    required
                    value={form.clinicAddress}
                    onChange={set("clinicAddress")}
                    className={input}
                    placeholder="Tokha, Kathmandu"
                  />
                </Field>
                <Field label="Consultation fee (Rs.)" optional>
                  <input
                    type="number"
                    min="0"
                    value={form.consultationFee}
                    onChange={set("consultationFee")}
                    className={input}
                  />
                </Field>
                <Field label="Languages you speak" htmlFor="languages">
                  <TagInput
                    id="languages"
                    value={form.languages}
                    onChange={setList("languages")}
                    suggestions={SPOKEN_LANGUAGES}
                    placeholder="e.g. Nepali"
                  />
                </Field>
              </Section>

              <Section title="Contact">
                <Field label="Email">
                  <input
                    required
                    type="email"
                    value={form.email}
                    onChange={set("email")}
                    className={input}
                    autoComplete="email"
                  />
                </Field>
                <Field label="Phone">
                  <input
                    required
                    type="tel"
                    value={form.phone}
                    onChange={set("phone")}
                    className={input}
                    placeholder="98XXXXXXXX"
                    autoComplete="tel"
                  />
                </Field>
                <Field
                  label="About you"
                  optional
                  hint="A few lines patients will see on your profile"
                  wide
                >
                  <textarea
                    rows={4}
                    maxLength={600}
                    value={form.about}
                    onChange={set("about")}
                    className={input}
                  />
                </Field>
              </Section>

              {/* honeypot: hidden from people, visible to bots */}
              <input
                type="text"
                name="website"
                value={form.website}
                onChange={set("website")}
                tabIndex={-1}
                autoComplete="off"
                aria-hidden="true"
                className="hidden"
              />

              <label className="flex items-start gap-3 rounded-2xl border border-black/5 bg-white p-5 text-sm">
                <input
                  required
                  type="checkbox"
                  checked={form.agree}
                  onChange={set("agree")}
                  className="mt-0.5 h-4 w-4 accent-brand-700"
                />
                <span className="text-gray-600">
                  I confirm these details are correct and agree that SEVA may
                  verify my registration and contact me about this application.
                </span>
              </label>

              {error && (
                <p
                  role="alert"
                  className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700"
                >
                  {error}
                </p>
              )}

              <button
                type="submit"
                disabled={status === "sending"}
                className="flex w-full items-center justify-center gap-2 rounded-full bg-ink py-3.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60 sm:w-auto sm:px-10"
              >
                {status === "sending" && (
                  <LoaderCircle size={16} className="animate-spin" />
                )}
                {status === "sending" ? "Sending…" : "Submit application"}
              </button>
            </form>
          </>
        )}
      </main>
    </div>
  );
}
