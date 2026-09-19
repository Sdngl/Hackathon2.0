import { useState } from "react";
import { Check, LoaderCircle } from "lucide-react";

// Save button with "Saving…" and "Saved" states and an error line.
// onSave should return a promise.
export default function SaveButton({
  onSave,
  disabled,
  label = "Save changes",
}) {
  const [status, setStatus] = useState("idle"); // idle | saving | saved
  const [error, setError] = useState("");

  async function save() {
    setStatus("saving");
    setError("");
    try {
      await onSave();
      setStatus("saved");
      setTimeout(() => setStatus("idle"), 2000);
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to save this."
          : err.message,
      );
      setStatus("idle");
    }
  }

  return (
    <div className="flex flex-wrap items-center justify-end gap-3">
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        type="button"
        onClick={save}
        disabled={disabled || status === "saving"}
        className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-40"
      >
        {status === "saving" && (
          <LoaderCircle size={15} className="animate-spin" />
        )}
        {status === "saved" && <Check size={15} />}
        {status === "saved" ? "Saved" : label}
      </button>
    </div>
  );
}
