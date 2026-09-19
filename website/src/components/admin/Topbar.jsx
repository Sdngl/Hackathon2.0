import { Link, useLocation } from "react-router";
import { Bell, Menu } from "lucide-react";
import GlobalSearch from "./GlobalSearch";
import DateRangePicker from "./DateRangePicker";
import { useAdmin } from "../../context/AdminContext";

// Pages where the date picker actually changes something
const RANGE_PAGES = ["/admin", "/admin/subscriptions"];

export default function Topbar({ onMenu }) {
  const { unreadCount } = useAdmin();
  const { pathname } = useLocation();
  const showRange = RANGE_PAGES.includes(pathname.replace(/\/$/, ""));

  return (
    <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-black/5 bg-white/90 px-5 py-4 backdrop-blur lg:px-8">
      <button
        onClick={onMenu}
        className="rounded-lg p-2 lg:hidden"
        aria-label="Open menu"
      >
        <Menu size={20} />
      </button>

      <GlobalSearch />

      <div className="ml-auto flex items-center gap-3">
        {showRange && (
          <div className="hidden sm:block">
            <DateRangePicker />
          </div>
        )}
        <Link
          to="/admin/notifications"
          className="relative rounded-xl border border-black/10 p-2.5 hover:bg-mist"
          aria-label={
            unreadCount
              ? `Notifications, ${unreadCount} unread`
              : "Notifications"
          }
        >
          <Bell size={18} />
          {unreadCount > 0 && (
            <span className="absolute -top-1.5 -right-1.5 grid h-5 min-w-5 place-items-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {unreadCount > 9 ? "9+" : unreadCount}
            </span>
          )}
        </Link>
      </div>
    </header>
  );
}
