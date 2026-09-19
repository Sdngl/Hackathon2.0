import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router";
import { CornerDownLeft, Search } from "lucide-react";
import { useAdmin } from "../../context/AdminContext";
import { adminNav } from "./navItems";
import { Avatar } from "./ui";

const PER_GROUP = 5;
const includes = (text, q) =>
  String(text ?? "")
    .toLowerCase()
    .includes(q);
const specs = (d) =>
  Array.isArray(d.specialization)
    ? d.specialization.join(", ")
    : (d.specialization ?? "");

// Search box in the top bar: finds pages, users and doctors as you type.
// Shortcut: ⌘K / Ctrl+K or "/" focuses it. Arrow keys + Enter to pick.
export default function GlobalSearch() {
  const { users, doctors } = useAdmin();
  const navigate = useNavigate();
  const inputRef = useRef(null);
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return [];

    const pages = adminNav
      .filter((p) => includes(p.label, q))
      .slice(0, PER_GROUP)
      .map((p) => ({
        key: `page-${p.path}`,
        group: "Pages",
        to: p.path ? `/admin/${p.path}` : "/admin",
        title: p.label,
        icon: p.icon,
      }));

    const people = users
      .filter((u) => includes(u.displayName, q) || includes(u.email, q))
      .slice(0, PER_GROUP)
      .map((u) => ({
        key: `user-${u.id}`,
        group: "Users",
        to: `/admin/users/${u.id}`,
        title: u.displayName || u.email,
        subtitle: u.email,
        avatar: u,
      }));

    const docs = doctors
      .filter(
        (d) =>
          includes(d.name, q) ||
          includes(specs(d), q) ||
          includes(d.hospital ?? d.clinicName ?? d.Clinic, q),
      )
      .slice(0, PER_GROUP)
      .map((d) => ({
        key: `doc-${d.id}`,
        group: "Doctors",
        to: `/admin/doctors/${d.id}`,
        title: d.name,
        subtitle: specs(d),
        avatar: { displayName: d.name, photoUrl: d.imageUrl },
      }));

    return [...pages, ...people, ...docs];
  }, [query, users, doctors]);

  // ⌘K / Ctrl+K / "/" anywhere on the page focuses the search box
  useEffect(() => {
    function onKey(e) {
      const typing = ["INPUT", "TEXTAREA", "SELECT"].includes(
        document.activeElement?.tagName,
      );
      if (
        (e.key === "k" && (e.metaKey || e.ctrlKey)) ||
        (e.key === "/" && !typing)
      ) {
        e.preventDefault();
        inputRef.current?.focus();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  function go(result) {
    navigate(result.to);
    setQuery("");
    setOpen(false);
    document.activeElement?.blur?.();
  }

  function onKeyDown(e) {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActive((i) => Math.min(i + 1, results.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter" && results[active]) {
      go(results[active]);
    } else if (e.key === "Escape") {
      setOpen(false);
      e.currentTarget.blur();
    }
  }

  const showPanel = open && query.trim() !== "";

  return (
    <div className="relative w-full max-w-sm">
      <Search
        size={16}
        className="absolute top-1/2 left-3.5 -translate-y-1/2 text-gray-400"
      />
      <input
        ref={inputRef}
        type="search"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setActive(0);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => setTimeout(() => setOpen(false), 150)} // let a click on a result land first
        onKeyDown={onKeyDown}
        placeholder="Search users, doctors or pages…"
        aria-label="Search"
        className="w-full rounded-xl border border-black/5 bg-mist py-2.5 pr-12 pl-10 text-sm outline-none focus:border-brand-500 focus:bg-white"
      />
      {!query && (
        <kbd className="pointer-events-none absolute top-1/2 right-3 hidden -translate-y-1/2 rounded-md border border-black/10 bg-white px-1.5 py-0.5 text-[10px] font-semibold text-gray-400 sm:block">
          ⌘K
        </kbd>
      )}

      {showPanel && (
        <div className="absolute inset-x-0 top-full z-30 mt-2 max-h-[70vh] overflow-y-auto rounded-2xl border border-black/5 bg-white p-2 shadow-xl">
          {results.length === 0 ? (
            <p className="px-3 py-6 text-center text-sm text-gray-500">
              No matches for “{query}”
            </p>
          ) : (
            results.map((r, i) => {
              const Icon = r.icon;
              return (
                <div key={r.key}>
                  {r.group !== results[i - 1]?.group && (
                    <p className="px-3 pt-2 pb-1 text-[11px] font-semibold tracking-wide text-gray-400 uppercase">
                      {r.group}
                    </p>
                  )}
                  <button
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => go(r)}
                    onMouseEnter={() => setActive(i)}
                    className={`flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm ${i === active ? "bg-mist" : ""}`}
                  >
                    {Icon ? (
                      <span className="grid h-8 w-8 place-items-center rounded-lg bg-brand-50 text-brand-700">
                        <Icon size={16} />
                      </span>
                    ) : (
                      <Avatar
                        name={r.avatar.displayName || "?"}
                        photo={r.avatar.photoUrl}
                        size="h-8 w-8"
                      />
                    )}
                    <span className="min-w-0 flex-1">
                      <span className="block truncate font-medium">
                        {r.title}
                      </span>
                      {r.subtitle && (
                        <span className="block truncate text-xs text-gray-500">
                          {r.subtitle}
                        </span>
                      )}
                    </span>
                    {i === active && (
                      <CornerDownLeft size={14} className="text-gray-400" />
                    )}
                  </button>
                </div>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}
