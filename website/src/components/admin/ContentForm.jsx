import { useState } from "react";
import { LoaderCircle } from "lucide-react";
import Modal from "./Modal";
import { AUDIENCES, CONTENT_TYPES } from "../../lib/content";

const EMPTY = {
  type: "article",
  title: "",
  category: "",
  body: "",
  imageUrl: "",
  audience: "all",
  published: false,
};
const input =
  "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

// Add / edit pop-up for one content item. `item` is null when adding.
export default function ContentForm({ item, onSave, onClose }) {
  const [form, setForm] = useState(() => ({ ...EMPTY, ...item }));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const set = (key) => (e) =>
    setForm((f) => ({
      ...f,
      [key]: e.target.type === "checkbox" ? e.target.checked : e.target.value,
    }));

  async function submit(e) {
    e.preventDefault();
    setSaving(true);
    setError("");
    try {
      await onSave({
        type: form.type,
        title: form.title.trim(),
        category: form.category.trim(),
        body: form.body.trim(),
        imageUrl: form.imageUrl.trim(),
        audience: form.audience,
        published: form.published,
      });
      onClose();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to save content."
          : err.message,
      );
      setSaving(false);
    }
  }

  return (
    <Modal title={item ? "Edit content" : "New content"} onClose={onClose} wide>
      <form
        onSubmit={submit}
        className="max-h-[72vh] space-y-4 overflow-y-auto pr-1"
      >
        <div className="grid gap-4 sm:grid-cols-3">
          <label className="block text-sm font-medium">
            Type
            <select value={form.type} onChange={set("type")} className={input}>
              {CONTENT_TYPES.map((t) => (
                <option key={t.key} value={t.key}>
                  {t.label}
                </option>
              ))}
            </select>
          </label>
          <label className="block text-sm font-medium">
            Category
            <input
              value={form.category}
              onChange={set("category")}
              className={input}
              placeholder="Nutrition"
            />
          </label>
          <label className="block text-sm font-medium">
            Show to
            <select
              value={form.audience}
              onChange={set("audience")}
              className={input}
            >
              {AUDIENCES.map((a) => (
                <option key={a.key} value={a.key}>
                  {a.label}
                </option>
              ))}
            </select>
          </label>
        </div>

        <label className="block text-sm font-medium">
          {form.type === "faq" ? "Question" : "Title"}
          <input
            required
            value={form.title}
            onChange={set("title")}
            className={input}
          />
        </label>

        <label className="block text-sm font-medium">
          {form.type === "faq" ? "Answer" : "Text"}
          <textarea
            required
            rows={form.type === "article" ? 8 : 4}
            value={form.body}
            onChange={set("body")}
            className={input}
          />
        </label>

        {form.type !== "faq" && (
          <label className="block text-sm font-medium">
            Image URL{" "}
            <span className="font-normal text-gray-400">(optional)</span>
            <input
              type="url"
              value={form.imageUrl}
              onChange={set("imageUrl")}
              className={input}
              placeholder="https://…"
            />
          </label>
        )}

        <label className="flex items-center gap-3 rounded-xl border border-black/10 px-4 py-3 text-sm font-medium">
          <input
            type="checkbox"
            checked={form.published}
            onChange={set("published")}
            className="h-4 w-4 accent-brand-700"
          />
          Published (visible in the app)
        </label>

        {error && (
          <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-1">
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
            {item ? "Save" : "Add content"}
          </button>
        </div>
      </form>
    </Modal>
  );
}
