import {
  CalendarClock,
  CalendarDays,
  FileText,
  LayoutGrid,
  Settings,
  UserRound,
  Users,
} from "lucide-react";

// Sidebar links for the doctor portal. path is relative to /doctor ('' = /doctor itself).
export const doctorNav = [
  { label: "Overview", path: "", icon: LayoutGrid },
  { label: "Appointments", path: "appointments", icon: CalendarDays },
  { label: "Patients", path: "patients", icon: Users },
  { label: "Shared Reports", path: "reports", icon: FileText },
  { label: "Availability", path: "availability", icon: CalendarClock },
  { label: "My Profile", path: "profile", icon: UserRound },
  { label: "Settings", path: "settings", icon: Settings },
];
