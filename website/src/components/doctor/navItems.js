import {
  CalendarClock,
  CalendarDays,
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
  { label: "Availability", path: "availability", icon: CalendarClock },
  { label: "My Profile", path: "profile", icon: UserRound },
  { label: "Settings", path: "settings", icon: Settings },
];
