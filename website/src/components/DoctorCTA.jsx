import { Link } from "react-router";
import { ArrowRight, BadgeCheck, CalendarDays, Users } from "lucide-react";

const perks = [
  {
    icon: Users,
    title: "Reach more patients",
    text: "SEVA suggests you when a user’s report matches your specialty.",
  },
  {
    icon: CalendarDays,
    title: "Bookings in one place",
    text: "In-clinic and video consultations, with reminders for patients.",
  },
  {
    icon: BadgeCheck,
    title: "Verified profile",
    text: "We check your NMC registration so patients can trust you.",
  },
];

// Landing page section: "Are you a doctor?" → /join-doctor
export default function DoctorCTA() {
  return (
    <section
      id="for-doctors"
      className="scroll-mt-16 bg-white px-5 pb-20 lg:px-8 lg:pb-28"
    >
      <div className="mx-auto grid max-w-6xl items-center gap-10 rounded-3xl border border-black/5 bg-mist p-8 lg:grid-cols-[1fr_1.2fr] lg:p-14">
        <div>
          <span className="inline-block rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
            For doctors
          </span>
          <h2 className="mt-4 text-3xl leading-tight font-bold tracking-tight sm:text-4xl">
            Are you a doctor? Join SEVA.
          </h2>
          <p className="mt-4 text-gray-600">
            Fill in a short form. Once we verify your registration, patients can
            find and book you from the app.
          </p>
          <Link
            to="/join-doctor"
            className="mt-8 inline-flex items-center gap-2 rounded-full bg-ink px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-800"
          >
            Join as a doctor <ArrowRight size={16} />
          </Link>
        </div>

        <ul className="grid gap-4">
          {perks.map(({ icon: Icon, title, text }) => (
            <li key={title} className="flex gap-4 rounded-2xl bg-white p-5">
              <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700">
                <Icon size={20} />
              </span>
              <div>
                <p className="font-semibold">{title}</p>
                <p className="mt-1 text-sm text-gray-600">{text}</p>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
