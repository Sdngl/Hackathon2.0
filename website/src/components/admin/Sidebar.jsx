import { NavLink } from "react-router";
import { LogOut } from "lucide-react";
import Logo from "../Logo";
import { adminNav } from "./navItems";
import { useAuth } from "../../context/AuthContext";
import { useAdmin } from "../../context/AdminContext";

export default function Sidebar({ open, onClose }) {
  const { user, logout } = useAuth();
  const { unreadCount } = useAdmin();
  const name = user?.displayName || "Admin";
  const initials = name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  return (
    <>
      {/* dark overlay behind the drawer on mobile */}
      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/30 lg:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-black/5 bg-white px-4 py-6 transition-transform lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="px-3">
          <Logo />
        </div>

        <nav className="mt-8 flex-1 space-y-1 overflow-y-auto">
          {adminNav.map(({ label, path, icon: Icon }) => {
            // live unread count from the notification feed
            const badge =
              path === "notifications" && unreadCount > 0
                ? unreadCount > 99
                  ? "99+"
                  : unreadCount
                : null;

            return (
              <NavLink
                key={label}
                to={path ? `/admin/${path}` : "/admin"}
                end={path === ""}
                onClick={onClose}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-colors ${
                    isActive
                      ? "bg-brand-50 font-semibold text-brand-700"
                      : "text-gray-600 hover:bg-mist hover:text-ink"
                  }`
                }
              >
                <Icon size={18} />
                <span className="flex-1">{label}</span>
                {badge && (
                  <span className="rounded-full bg-red-500 px-2 py-0.5 text-[10px] font-bold text-white">
                    {badge}
                  </span>
                )}
              </NavLink>
            );
          })}
        </nav>

        <div className="mt-4 flex items-center gap-3 rounded-2xl bg-mist p-3">
          <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">
            {initials}
          </span>
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate text-sm font-semibold">{name}</p>
            <p className="truncate text-xs text-gray-500">Super Admin</p>
          </div>
          <button
            onClick={logout}
            aria-label="Log out"
            className="rounded-lg p-2 text-gray-500 hover:bg-white hover:text-ink"
          >
            <LogOut size={17} />
          </button>
        </div>
      </aside>
    </>
  );
}
