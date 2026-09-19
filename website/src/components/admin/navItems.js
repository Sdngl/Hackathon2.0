import {
  Bell,
  Building2,
  CalendarDays,
  CreditCard,
  LayoutGrid,
  Newspaper,
  ScanLine,
  Settings,
  SlidersVertical,
  Stethoscope,
  Users,
} from "lucide-react";

// One list drives the sidebar links, the routes in App.jsx and the page
// shortcuts in the search box. path is relative to /admin ('' = /admin itself).
export const adminNav = [
  { label: "Overview", path: "", icon: LayoutGrid },
  { label: "Users", path: "users", icon: Users },
  { label: "Doctors", path: "doctors", icon: Stethoscope },
  { label: "Clinics", path: "clinics", icon: Building2 },
  { label: "Appointments", path: "appointments", icon: CalendarDays },
  { label: "Subscriptions & Revenue", path: "subscriptions", icon: CreditCard },
  { label: "Scans & AI Usage", path: "scans", icon: ScanLine },
  {
    label: "Suggestion Rules",
    path: "suggestion-rules",
    icon: SlidersVertical,
  },
  { label: "Content", path: "content", icon: Newspaper },
  { label: "Notifications", path: "notifications", icon: Bell },
  { label: "Settings", path: "settings", icon: Settings },
];
