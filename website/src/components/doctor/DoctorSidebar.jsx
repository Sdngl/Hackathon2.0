import { NavLink } from "react-router";
import { LogOut } from "lucide-react";
import Logo from "../Logo";
import { Avatar } from "../admin/ui";
import { doctorNav } from "./navItems";
import { useAuth } from "../../context/AuthContext";
import { useDoctor } from "../../context/DoctorContext";

export default function DoctorSidebar({ open, onClose }) {
  const { logout } = useAuth();
  const { doctor } = useDoctor();
  const specs = Array.isArray(doctor.specialization)
    ? doctor.specialization[0]
    : doctor.specialization;

  return (
    <>
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
        <div className="flex items-center gap-2 px-3">
          <Logo />
          <span className="rounded-md bg-brand-50 px-1.5 py-0.5 text-[10px] font-bold tracking-wide text-brand-700 uppercase">
            Doctor
          </span>
        </div>

        <nav className="mt-8 flex-1 space-y-1 overflow-y-auto">
          {doctorNav.map(({ label, path, icon: Icon }) => (
            <NavLink
              key={label}
              to={path ? `/doctor/${path}` : "/doctor"}
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
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="mt-4 flex items-center gap-3 rounded-2xl bg-mist p-3">
          <Avatar
            name={doctor.name ?? "?"}
            photo={doctor.imageUrl}
            size="h-9 w-9"
          />
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate text-sm font-semibold">{doctor.name}</p>
            <p className="truncate text-xs text-gray-500">
              {specs ?? "Doctor"}
            </p>
          </div>
          <button
            onClick={logout}
            aria-label="Sign out"
            className="rounded-lg p-2 text-gray-500 hover:bg-white hover:text-ink"
          >
            <LogOut size={17} />
          </button>
        </div>
      </aside>
    </>
  );
}
