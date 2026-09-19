import { useState } from "react";
import { ImageUp, LoaderCircle, Trash2 } from "lucide-react";
import { Avatar } from "./admin/ui";
import { ACCEPT_ATTR, isDataUrl, photoToDataUrl } from "../lib/imageUpload";

// Photo picker: upload a photo (saved as base64 text) or paste an image link.
// value is the imageUrl: either "https://..." or "data:image/jpeg;base64,..."
export default function PhotoUpload({ value, onChange, name = "?" }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [showLink, setShowLink] = useState(!!value && !isDataUrl(value));

  async function pick(e) {
    const file = e.target.files?.[0];
    e.target.value = ""; // lets you pick the same file again after removing it
    if (!file) return;
    setBusy(true);
    setError("");
    try {
      onChange(await photoToDataUrl(file));
      setShowLink(false);
    } catch (err) {
      setError(err.message);
    }
    setBusy(false);
  }

  const sizeKb = isDataUrl(value)
    ? Math.round((value.length * 0.75) / 1024)
    : null;

  return (
    <div className="sm:col-span-2">
      <p className="text-sm font-medium">Profile photo</p>
      <div className="mt-2 flex flex-wrap items-center gap-4">
        <Avatar name={name} photo={value} size="h-20 w-20 text-xl" />

        <div className="flex flex-col gap-2">
          <div className="flex flex-wrap gap-2">
            {/* the label opens the file picker; the real input is hidden */}
            <label
              className={`flex cursor-pointer items-center gap-2 rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-brand-800 ${busy ? "pointer-events-none opacity-60" : ""}`}
            >
              {busy ? (
                <LoaderCircle size={15} className="animate-spin" />
              ) : (
                <ImageUp size={15} />
              )}
              {value ? "Change photo" : "Upload photo"}
              <input
                type="file"
                accept={ACCEPT_ATTR}
                onChange={pick}
                className="sr-only"
              />
            </label>
            {value && (
              <button
                type="button"
                onClick={() => {
                  onChange("");
                  setShowLink(false);
                }}
                className="flex items-center gap-2 rounded-full border border-black/10 px-4 py-2 text-sm font-semibold hover:bg-mist"
              >
                <Trash2 size={15} /> Remove
              </button>
            )}
          </div>
          <p className="text-xs text-gray-500">
            JPG, PNG or WebP. Cropped to a square and shrunk automatically
            {sizeKb ? ` (now ${sizeKb} KB)` : ""}.
            {!showLink && (
              <>
                {" "}
                <button
                  type="button"
                  onClick={() => setShowLink(true)}
                  className="font-semibold text-brand-700 hover:underline"
                >
                  Use a link instead
                </button>
              </>
            )}
          </p>
        </div>
      </div>

      {showLink && (
        <input
          type="url"
          value={isDataUrl(value) ? "" : value}
          onChange={(e) => onChange(e.target.value.trim())}
          placeholder="https://…"
          aria-label="Photo link"
          className="mt-3 w-full rounded-xl border border-black/10 bg-white px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
        />
      )}

      {error && (
        <p className="mt-2 rounded-xl bg-red-50 px-4 py-2.5 text-sm text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
