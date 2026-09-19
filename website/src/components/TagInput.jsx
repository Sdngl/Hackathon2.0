import { useId, useMemo, useState } from "react";
import { Plus, X } from "lucide-react";

const MAX_SUGGESTIONS = 8;

// Pick several values from suggestions, or type your own.
//   Type to filter · ↑ ↓ to move · Enter or comma to add · Backspace removes the last one
// value is an array of strings, e.g. ['Cardiologist', 'Internal Medicine']
export default function TagInput({
  value,
  onChange,
  suggestions = [],
  placeholder = "Type to search…",
  invalid = false,
  id,
}) {
  const autoId = useId();
  const inputId = id ?? autoId;
  const listId = `${inputId}-list`;
  const [text, setText] = useState("");
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);

  const chosen = useMemo(
    () => new Set(value.map((v) => v.toLowerCase())),
    [value],
  );
  const query = text.trim().toLowerCase();

  const options = useMemo(() => {
    const matches = suggestions
      .filter(
        (s) => !chosen.has(s.toLowerCase()) && s.toLowerCase().includes(query),
      )
      // names that START with what you typed come first
      .sort(
        (a, b) =>
          Number(!a.toLowerCase().startsWith(query)) -
          Number(!b.toLowerCase().startsWith(query)),
      )
      .slice(0, MAX_SUGGESTIONS)
      .map((s) => ({ label: s, value: s }));
    const exact = suggestions.some((s) => s.toLowerCase() === query);
    if (query && !exact && !chosen.has(query))
      matches.push({
        label: `Add “${text.trim()}”`,
        value: text.trim(),
        custom: true,
      });
    return matches;
  }, [suggestions, chosen, query, text]);

  function add(item) {
    const clean = item.trim();
    if (clean && !chosen.has(clean.toLowerCase())) onChange([...value, clean]);
    setText("");
    setActive(0);
  }

  const remove = (item) => onChange(value.filter((v) => v !== item));

  function onKeyDown(e) {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
      setActive((i) => Math.min(i + 1, options.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter" || e.key === ",") {
      if (!text.trim()) return; // an empty Enter still submits the form
      e.preventDefault();
      add(options[active]?.value ?? text);
    } else if (e.key === "Backspace" && !text && value.length) {
      remove(value[value.length - 1]);
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  }

  return (
    <div className="relative mt-1.5">
      <div
        // clicking anywhere in the box puts the cursor in the text field
        onMouseDown={(e) => {
          if (e.target === e.currentTarget) {
            e.preventDefault();
            e.currentTarget.querySelector("input")?.focus();
          }
        }}
        className={`flex min-h-11 w-full cursor-text flex-wrap items-center gap-1.5 rounded-xl border bg-white px-2 py-1.5 text-sm focus-within:border-brand-500 focus-within:ring-2 focus-within:ring-brand-100 ${
          invalid ? "border-red-400" : "border-black/10"
        }`}
      >
        {value.map((item) => (
          <span
            key={item}
            className="flex items-center gap-1 rounded-lg bg-brand-50 py-1 pr-1 pl-2.5 text-xs font-semibold text-brand-700"
          >
            {item}
            <button
              type="button"
              onClick={() => remove(item)}
              className="rounded p-0.5 hover:bg-brand-100"
              aria-label={`Remove ${item}`}
            >
              <X size={12} />
            </button>
          </span>
        ))}
        <input
          id={inputId}
          role="combobox"
          aria-expanded={open && options.length > 0}
          aria-controls={listId}
          aria-autocomplete="list"
          value={text}
          onChange={(e) => {
            setText(e.target.value);
            setOpen(true);
            setActive(0);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => {
            // a full suggestion typed out is added; a half-typed word stays in the box instead of being saved
            const match = suggestions.find(
              (sug) => sug.toLowerCase() === query,
            );
            if (match) add(match);
            setOpen(false);
          }}
          onKeyDown={onKeyDown}
          placeholder={value.length ? "" : placeholder}
          className="min-w-32 flex-1 bg-transparent px-1.5 py-1 outline-none"
        />
      </div>

      {open && options.length > 0 && (
        <ul
          id={listId}
          role="listbox"
          className="absolute inset-x-0 top-full z-20 mt-1.5 max-h-64 overflow-y-auto rounded-2xl border border-black/5 bg-white p-1.5 shadow-xl"
        >
          {options.map((o, i) => (
            <li
              key={o.label}
              role="option"
              aria-selected={i === active}
              onMouseDown={(e) => {
                e.preventDefault();
                add(o.value);
              }} // before the input loses focus
              onMouseEnter={() => setActive(i)}
              className={`flex cursor-pointer items-center gap-2 rounded-xl px-3 py-2 text-sm ${i === active ? "bg-mist" : ""} ${o.custom ? "font-medium text-brand-700" : ""}`}
            >
              {o.custom && <Plus size={14} />}
              {o.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
