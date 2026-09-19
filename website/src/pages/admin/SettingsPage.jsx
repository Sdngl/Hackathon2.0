import { useSearchParams } from "react-router";
import { Database, LayoutDashboard, Smartphone, UserRound } from "lucide-react";
import AccountSettings from "../../components/admin/settings/AccountSettings";
import DashboardSettings from "../../components/admin/settings/DashboardSettings";
import AppSettings from "../../components/admin/settings/AppSettings";
import DataExport from "../../components/admin/settings/DataExport";

// Each tab has its own URL, e.g. /admin/settings?tab=app, so other pages can link straight to it
const TABS = [
  {
    key: "account",
    label: "Account",
    text: "Your name and password",
    icon: UserRound,
    element: <AccountSettings />,
  },
  {
    key: "dashboard",
    label: "Dashboard",
    text: "Date range and notification types",
    icon: LayoutDashboard,
    element: <DashboardSettings />,
  },
  {
    key: "app",
    label: "Mobile app",
    text: "Language, support, maintenance",
    icon: Smartphone,
    element: <AppSettings />,
  },
  {
    key: "data",
    label: "Data",
    text: "Export to CSV",
    icon: Database,
    element: <DataExport />,
  },
];

// /admin/settings
export default function SettingsPage() {
  const [params, setParams] = useSearchParams();
  const active = TABS.find((t) => t.key === params.get("tab")) ?? TABS[0];

  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold tracking-tight">Settings</h1>

      <div className="grid items-start gap-5 lg:grid-cols-[240px_1fr]">
        <nav
          className="flex gap-2 overflow-x-auto rounded-3xl border border-black/5 bg-white p-2 lg:flex-col"
          aria-label="Settings sections"
        >
          {TABS.map(({ key, label, text, icon: Icon }) => (
            <button
              key={key}
              onClick={() => setParams({ tab: key })}
              aria-current={active.key === key ? "page" : undefined}
              className={`flex shrink-0 items-center gap-3 rounded-2xl px-3 py-2.5 text-left transition-colors ${
                active.key === key
                  ? "bg-brand-50 text-brand-700"
                  : "text-gray-600 hover:bg-mist hover:text-ink"
              }`}
            >
              <Icon size={18} className="shrink-0" />
              <span>
                <span className="block text-sm font-semibold">{label}</span>
                <span className="hidden text-xs text-gray-500 lg:block">
                  {text}
                </span>
              </span>
            </button>
          ))}
        </nav>

        <div key={active.key}>{active.element}</div>
      </div>
    </div>
  );
}
