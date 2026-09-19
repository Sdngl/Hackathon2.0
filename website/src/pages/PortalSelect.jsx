import { Link } from "react-router";
import { ChevronRight, ShieldCheck, Stethoscope } from "lucide-react";
import Logo from "../components/Logo";

const portals = [
  {
    to: "/admin/login",
    icon: ShieldCheck,
    title: "Admin",
    text: "Manage users, doctors, subscriptions and app content.",
  },
  {
    to: "/doctor/login",
    icon: Stethoscope,
    title: "Doctor",
    text: "See your consultations and patient reports.",
  },
];

export default function PortalSelect() {
  return (
    <div className="flex min-h-screen flex-col bg-mist">
      <header className="mx-auto w-full max-w-6xl px-5 py-5 lg:px-8">
        <Logo />
      </header>

      <main className="grid flex-1 place-items-center px-5 pb-20">
        <div className="w-full max-w-md">
          <h1 className="text-center text-3xl font-bold tracking-tight">
            Sign in to SEVA
          </h1>
          <p className="mt-2 text-center text-gray-600">
            Choose your portal to continue.
          </p>

          <div className="mt-8 space-y-3">
            {portals.map(({ to, icon: Icon, title, text }) => (
              <Link
                key={title}
                to={to}
                className="flex items-center gap-4 rounded-2xl border border-black/5 bg-white p-5 transition-colors hover:border-brand-500"
              >
                <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700">
                  <Icon size={22} />
                </span>
                <span className="flex-1">
                  <span className="block font-semibold">{title}</span>
                  <span className="block text-sm text-gray-500">{text}</span>
                </span>
                <ChevronRight size={18} className="text-gray-400" />
              </Link>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
