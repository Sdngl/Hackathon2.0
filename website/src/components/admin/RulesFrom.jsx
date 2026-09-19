import { useState } from "react";
import { LoaderCircle } from "lucide-react";
import Modal from "./Modal";
import { ACTIONS, OPERATORS, PRIORITIES, TRIGGERS } from "../../lib/rules";

const EMPTY = {
  name: "",
  trigger: "report",
  metric: "",
  operator: "<",
  value: "",
  unit: "",
  action: "tip",
  specialization: "",
  message: "",
  priority: "medium",
  enabled: true,
};

const box =
  "w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";
const input = `mt-1.5 ${box}`;

// Pop-up for adding or editing a rule. `rule` is null when adding.
export default function RuleForm({ rule, specializations, onSave, onClose }) {
  const [form, setForm] = useState(() => ({
    ...EMPTY,
    ...rule,
    value: rule?.value ?? "",
  }));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const set = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));
  const hint = TRIGGERS.find((t) => t.key === form.trigger)?.hint;

  async function submit(e) {
    e.preventDefault();
    setSaving(true);
    setError("");
    const value =
      form.value !== "" && !Number.isNaN(Number(form.value))
        ? Number(form.value)
        : form.value.trim();
    try {
      await onSave({
        name: form.name.trim(),
        trigger: form.trigger,
        metric: form.metric.trim(),
        operator: form.operator,
        value,
        unit: form.unit.trim(),
        action: form.action,
        specialization:
          form.action === "doctor" ? form.specialization.trim() : "",
        message: form.message.trim(),
        priority: form.priority,
        enabled: form.enabled,
      });
      onClose();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to save rules."
          : err.message,
      );
      setSaving(false);
    }
  }

  return (
    <Modal title={rule ? "Edit rule" : "New suggestion rule"} onClose={onClose}>
      <form
        onSubmit={submit}
        className="max-h-[70vh] space-y-4 overflow-y-auto pr-1"
      >
        <label className="block text-sm font-medium">
          Rule name
          <input
            required
            value={form.name}
            onChange={set("name")}
            className={input}
            placeholder="Low Vitamin D"
          />
        </label>

        <div>
          <p className="text-sm font-medium">When</p>
          <div className="mt-1.5 grid grid-cols-2 gap-2">
            <select
              value={form.trigger}
              onChange={set("trigger")}
              className={box}
            >
              {TRIGGERS.map((t) => (
                <option key={t.key} value={t.key}>
                  {t.label}
                </option>
              ))}
            </select>
            <input
              required
              value={form.metric}
              onChange={set("metric")}
              className={box}
              placeholder="Metric"
            />
            <select
              value={form.operator}
              onChange={set("operator")}
              className={box}
            >
              {OPERATORS.map((o) => (
                <option key={o.key} value={o.key}>
                  {o.label}
                </option>
              ))}
            </select>
            <div className="flex gap-2">
              <input
                required
                value={form.value}
                onChange={set("value")}
                className={`${box} min-w-0`}
                placeholder="Value"
              />
              <input
                value={form.unit}
                onChange={set("unit")}
                className={`${box} w-20`}
                placeholder="Unit"
              />
            </div>
          </div>
          {hint && <p className="mt-1.5 text-xs text-gray-400">{hint}</p>}
        </div>

        <div className="grid grid-cols-2 gap-2">
          <label className="block text-sm font-medium">
            Then
            <select
              value={form.action}
              onChange={set("action")}
              className={input}
            >
              {ACTIONS.map((a) => (
                <option key={a.key} value={a.key}>
                  {a.label}
                </option>
              ))}
            </select>
          </label>
          <label className="block text-sm font-medium">
            Priority
            <select
              value={form.priority}
              onChange={set("priority")}
              className={`${input} capitalize`}
            >
              {PRIORITIES.map((p) => (
                <option key={p} value={p}>
                  {p}
                </option>
              ))}
            </select>
          </label>
        </div>

        {form.action === "doctor" && (
          <label className="block text-sm font-medium">
            Specialization
            <input
              required
              list="specializations"
              value={form.specialization}
              onChange={set("specialization")}
              className={input}
              placeholder="Cardiologist"
            />
            {/* suggestions come from your doctors' specializations */}
            <datalist id="specializations">
              {specializations.map((s) => (
                <option key={s} value={s} />
              ))}
            </datalist>
          </label>
        )}

        <label className="block text-sm font-medium">
          Message shown to the user
          <textarea
            required
            rows={3}
            value={form.message}
            onChange={set("message")}
            className={input}
          />
        </label>

        {error && (
          <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
          >
            {saving && <LoaderCircle size={15} className="animate-spin" />}
            {rule ? "Save rule" : "Add rule"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
