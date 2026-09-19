import { useMemo, useState } from "react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {
  FileText,
  LoaderCircle,
  Pencil,
  Pill,
  Plus,
  Sparkles,
  Stethoscope,
  Trash2,
  UtensilsCrossed,
} from "lucide-react";
import { db } from "../../lib/firebase";
import useCollection from "../../hooks/useCollection";
import { Card } from "../../components/admin/ui";
import Modal from "../../components/admin/Modal";
import Tabs from "../../components/admin/Tabs";
import RuleForm from "../../components/admin/RulesFrom";
import {
  ACTIONS,
  RULES_COLLECTION,
  STARTER_RULES,
  TRIGGERS,
  describeCondition,
  labelOf,
  matchingDoctors,
} from "../../lib/rules";

const triggerIcon = { report: FileText, meal: UtensilsCrossed, medicine: Pill };
const triggerTint = {
  report: "bg-blue-50 text-blue-600",
  meal: "bg-orange-50 text-orange-500",
  medicine: "bg-amber-50 text-amber-600",
};
const priorityStyle = {
  high: "bg-red-50 text-red-600",
  medium: "bg-amber-50 text-amber-600",
  low: "bg-gray-100 text-gray-600",
};
const priorityOrder = { high: 0, medium: 1, low: 2 };

function Toggle({ checked, onChange, label }) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={onChange}
      className={`relative h-6 w-11 shrink-0 rounded-full transition-colors ${checked ? "bg-brand-600" : "bg-gray-300"}`}
    >
      <span
        className={`absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${checked ? "translate-x-5" : ""}`}
      />
    </button>
  );
}

function RuleCard({ rule, doctors, onEdit, onDelete, onToggle }) {
  const Icon = triggerIcon[rule.trigger] ?? FileText;
  const matches = matchingDoctors(rule, doctors);

  return (
    <article
      className={`rounded-3xl border border-black/5 bg-white p-5 transition-opacity ${rule.enabled ? "" : "opacity-60"}`}
    >
      <div className="flex items-start gap-4">
        <span
          className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl ${triggerTint[rule.trigger] ?? "bg-mist"}`}
        >
          <Icon size={20} />
        </span>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="font-semibold">{rule.name}</h3>
            <span
              className={`rounded-md px-2 py-0.5 text-[11px] font-semibold capitalize ${priorityStyle[rule.priority] ?? priorityStyle.low}`}
            >
              {rule.priority}
            </span>
          </div>

          <p className="mt-2 text-sm">
            <span className="font-semibold text-gray-400">IF </span>
            <span className="text-gray-700">{describeCondition(rule)}</span>
          </p>
          <p className="mt-1 text-sm">
            <span className="font-semibold text-gray-400">THEN </span>
            <span className="text-gray-700">
              {labelOf(ACTIONS, rule.action)}
              {rule.action === "doctor" && rule.specialization && (
                <strong className="font-semibold">
                  : {rule.specialization}
                </strong>
              )}
            </span>
          </p>

          <p className="mt-3 rounded-xl bg-mist px-3.5 py-2.5 text-sm text-gray-600">
            “{rule.message}”
          </p>

          {rule.action === "doctor" && (
            <p
              className={`mt-2 flex items-center gap-1.5 text-xs ${matches.length ? "text-brand-700" : "text-red-600"}`}
            >
              <Stethoscope size={13} />
              {matches.length
                ? `${matches.length} active doctor${matches.length > 1 ? "s" : ""} match: ${matches.map((d) => d.name).join(", ")}`
                : "No active doctor has this specialization yet"}
            </p>
          )}
        </div>

        <div className="flex flex-col items-end gap-3">
          <Toggle
            checked={!!rule.enabled}
            onChange={onToggle}
            label={`Turn ${rule.name} ${rule.enabled ? "off" : "on"}`}
          />
          <div className="flex gap-1">
            <button
              onClick={onEdit}
              className="rounded-lg p-2 text-gray-500 hover:bg-mist hover:text-ink"
              aria-label="Edit rule"
            >
              <Pencil size={15} />
            </button>
            <button
              onClick={onDelete}
              className="rounded-lg p-2 text-gray-500 hover:bg-red-50 hover:text-red-600"
              aria-label="Delete rule"
            >
              <Trash2 size={15} />
            </button>
          </div>
        </div>
      </div>
    </article>
  );
}

// /admin/suggestion-rules
export default function SuggestionRulesPage() {
  const rules = useCollection(RULES_COLLECTION);
  const { data: doctors } = useCollection("doctors");
  const [filter, setFilter] = useState("all");
  const [editing, setEditing] = useState(undefined); // undefined = closed, null = new rule, object = edit
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const specializations = useMemo(
    () =>
      [
        ...new Set(
          doctors
            .flatMap((d) =>
              Array.isArray(d.specialization)
                ? d.specialization
                : [d.specialization],
            )
            .filter(Boolean),
        ),
      ].sort(),
    [doctors],
  );

  const visible = useMemo(
    () =>
      rules.data
        .filter((r) => filter === "all" || r.trigger === filter)
        .sort(
          (a, b) =>
            (priorityOrder[a.priority] ?? 3) -
              (priorityOrder[b.priority] ?? 3) ||
            (a.name ?? "").localeCompare(b.name ?? ""),
        ),
    [rules.data, filter],
  );
  const enabledCount = rules.data.filter((r) => r.enabled).length;

  const run = async (fn) => {
    setError("");
    try {
      await fn();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to change rules."
          : err.message,
      );
    }
  };

  const saveRule = async (data) => {
    if (editing?.id) {
      await updateDoc(doc(db, RULES_COLLECTION, editing.id), {
        ...data,
        updatedAt: serverTimestamp(),
      });
    } else {
      await addDoc(collection(db, RULES_COLLECTION), {
        ...data,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    }
  };

  const addStarterRules = async () => {
    setBusy(true);
    await run(async () => {
      const batch = writeBatch(db);
      for (const rule of STARTER_RULES) {
        batch.set(doc(collection(db, RULES_COLLECTION)), {
          ...rule,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      }
      await batch.commit();
    });
    setBusy(false);
  };

  if (rules.loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (rules.error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load rules: {rules.error.message}
      </p>
    );

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Suggestion Rules</h1>
          <p className="mt-0.5 text-sm text-gray-500">
            What the app suggests after a scan. {rules.data.length} rules ·{" "}
            {enabledCount} on
          </p>
        </div>
        <button
          onClick={() => setEditing(null)}
          className="flex items-center gap-2 rounded-full bg-ink px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-800"
        >
          <Plus size={16} /> New rule
        </button>
      </div>

      {error && (
        <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}

      {rules.data.length === 0 ? (
        <Card className="text-center">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-violet-50 text-violet-600">
            <Sparkles size={24} />
          </span>
          <h2 className="mt-4 text-lg font-semibold">No rules yet</h2>
          <p className="mx-auto mt-1 max-w-md text-sm text-gray-500">
            Rules decide what SEVA suggests when a scan matches, like
            recommending a cardiologist when cholesterol is high.
          </p>
          <div className="mt-5 flex justify-center gap-2">
            <button
              onClick={addStarterRules}
              disabled={busy}
              className="flex items-center gap-2 rounded-full bg-brand-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
            >
              {busy && <LoaderCircle size={15} className="animate-spin" />} Add
              5 starter rules
            </button>
            <button
              onClick={() => setEditing(null)}
              className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
            >
              Start from scratch
            </button>
          </div>
        </Card>
      ) : (
        <>
          <Tabs
            tabs={[
              { key: "all", label: "All" },
              ...TRIGGERS.map((t) => ({ key: t.key, label: t.label })),
            ]}
            value={filter}
            onChange={setFilter}
          />
          <div className="grid gap-4 xl:grid-cols-2">
            {visible.map((rule) => (
              <RuleCard
                key={rule.id}
                rule={rule}
                doctors={doctors}
                onEdit={() => setEditing(rule)}
                onDelete={() => setDeleting(rule)}
                onToggle={() =>
                  run(() =>
                    updateDoc(doc(db, RULES_COLLECTION, rule.id), {
                      enabled: !rule.enabled,
                      updatedAt: serverTimestamp(),
                    }),
                  )
                }
              />
            ))}
          </div>
          {visible.length === 0 && (
            <p className="py-10 text-center text-sm text-gray-500">
              No rules for this type yet.
            </p>
          )}
        </>
      )}

      {editing !== undefined && (
        <RuleForm
          rule={editing}
          specializations={specializations}
          onSave={saveRule}
          onClose={() => setEditing(undefined)}
        />
      )}

      {deleting && (
        <Modal
          title="Delete rule?"
          onClose={() => setDeleting(null)}
          footer={
            <>
              <button
                onClick={() => setDeleting(null)}
                className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
              >
                Cancel
              </button>
              <button
                onClick={() =>
                  run(async () => {
                    await deleteDoc(doc(db, RULES_COLLECTION, deleting.id));
                    setDeleting(null);
                  })
                }
                className="rounded-full bg-red-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-red-700"
              >
                Delete
              </button>
            </>
          }
        >
          <p className="text-sm text-gray-600">
            <strong className="text-ink">{deleting.name}</strong> will stop
            showing in the app. To pause it instead, use its on/off switch.
          </p>
        </Modal>
      )}
    </div>
  );
}
