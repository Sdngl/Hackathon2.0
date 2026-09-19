import { useState } from "react";
import { Link } from "react-router";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { ChevronRight, LoaderCircle, TriangleAlert } from "lucide-react";
import { db } from "../../../lib/firebase";
import useDocument from "../../../hooks/useDocument";
import { APP_CONFIG, LANGUAGES, mergeAppConfig } from "../../../lib/settings";
import { Card } from "../ui";
import SaveButton from "./SaveButton";
import { Field, SwitchRow, inputClass } from "./fields";

const RELATED = [
  {
    to: "/admin/content",
    label: "Content",
    text: "Articles, tips, banners and FAQs in the app",
  },
  {
    to: "/admin/suggestion-rules",
    label: "Suggestion Rules",
    text: "What the app suggests after a scan",
  },
  {
    to: "/admin/notifications",
    label: "Announcements",
    text: "In-app messages to your users",
  },
  { to: "/admin/doctors", label: "Doctors", text: "Who users can book" },
];

function AppSettingsForm({ saved }) {
  const [form, setForm] = useState(saved);
  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }));
  const changed = JSON.stringify(form) !== JSON.stringify(saved);

  function toggleLanguage(key) {
    const list = form.supportedLanguages.includes(key)
      ? form.supportedLanguages.filter((l) => l !== key)
      : [...form.supportedLanguages, key];
    // the default language must stay switched on
    if (list.length && list.includes(form.defaultLanguage))
      set("supportedLanguages", list);
  }

  const save = () =>
    setDoc(
      doc(db, APP_CONFIG.collection, APP_CONFIG.id),
      { ...form, updatedAt: serverTimestamp() },
      { merge: true },
    );

  return (
    <div className="space-y-5">
      <Card
        title="Language"
        subtitle="Which languages the mobile app offers, and which one new users see first"
      >
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          <Field label="Default language">
            <select
              value={form.defaultLanguage}
              onChange={(e) => {
                const lang = e.target.value;
                setForm((f) => ({
                  ...f,
                  defaultLanguage: lang,
                  supportedLanguages: [
                    ...new Set([...f.supportedLanguages, lang]),
                  ],
                }));
              }}
              className={inputClass}
            >
              {LANGUAGES.map((l) => (
                <option key={l.key} value={l.key}>
                  {l.label}
                </option>
              ))}
            </select>
          </Field>
          <div className="text-sm font-medium">
            Available in the app
            <div className="mt-1.5 flex flex-wrap gap-2">
              {LANGUAGES.map((l) => {
                const on = form.supportedLanguages.includes(l.key);
                return (
                  <button
                    key={l.key}
                    type="button"
                    onClick={() => toggleLanguage(l.key)}
                    className={`rounded-xl border px-3.5 py-2.5 text-sm transition-colors ${on ? "border-brand-500 bg-brand-50 text-brand-700" : "border-black/10 text-gray-500 hover:bg-mist"}`}
                  >
                    {l.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
        <p className="mt-4 text-xs text-gray-500">
          This admin dashboard itself is in English.
        </p>
      </Card>

      <Card title="Support contact" subtitle="Shown in the app's help screen">
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          <Field label="Support email">
            <input
              type="email"
              value={form.supportEmail}
              onChange={(e) => set("supportEmail", e.target.value)}
              className={inputClass}
              placeholder="support@seva.app"
            />
          </Field>
          <Field label="Support phone">
            <input
              type="tel"
              value={form.supportPhone}
              onChange={(e) => set("supportPhone", e.target.value)}
              className={inputClass}
              placeholder="+977 98…"
            />
          </Field>
        </div>
      </Card>

      <Card
        title="Maintenance mode"
        subtitle="Temporarily show a message instead of the app, e.g. during an update"
      >
        <div className="mt-2">
          <SwitchRow
            label="Maintenance mode"
            hint="Users see the message below until you turn this off"
            checked={form.maintenanceMode}
            onChange={(on) => set("maintenanceMode", on)}
          />
        </div>
        {form.maintenanceMode && (
          <p className="mb-3 flex items-center gap-2 rounded-xl bg-amber-50 px-4 py-3 text-sm text-amber-700">
            <TriangleAlert size={16} /> When saved, users can't use the app
            until you switch this off.
          </p>
        )}
        <Field label="Message">
          <textarea
            rows={2}
            value={form.maintenanceMessage}
            onChange={(e) => set("maintenanceMessage", e.target.value)}
            className={inputClass}
          />
        </Field>
      </Card>

      <div className="sticky bottom-4 rounded-2xl border border-black/5 bg-white/95 p-3 shadow-lg backdrop-blur">
        <SaveButton
          disabled={!changed}
          onSave={save}
          label="Save app settings"
        />
      </div>

      <Card
        title="Related pages"
        subtitle="Other things that change what users see in the app"
      >
        <ul className="mt-3 divide-y divide-black/5">
          {RELATED.map((r) => (
            <li key={r.to}>
              <Link
                to={r.to}
                className="-mx-2 flex items-center justify-between rounded-xl px-2 py-3 hover:bg-mist"
              >
                <span>
                  <span className="block text-sm font-semibold">{r.label}</span>
                  <span className="block text-xs text-gray-500">{r.text}</span>
                </span>
                <ChevronRight size={16} className="text-gray-400" />
              </Link>
            </li>
          ))}
        </ul>
      </Card>
    </div>
  );
}

// Settings the MOBILE APP reads (saved in appConfig/general)
export default function AppSettings() {
  const { data, loading, error } = useDocument(
    APP_CONFIG.collection,
    APP_CONFIG.id,
  );

  if (loading)
    return (
      <div className="grid place-items-center py-20">
        <LoaderCircle className="animate-spin text-brand-700" />
      </div>
    );
  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load app settings: {error.message}
      </p>
    );

  // key: when someone else saves, the form restarts from the new values
  const formValues = mergeAppConfig(data)
  delete formValues.updatedAt // a timestamp, not a form field
  return (
    <AppSettingsForm
      key={String(data?.updatedAt?.seconds ?? "new")}
      saved={formValues}
    />
  );
}
