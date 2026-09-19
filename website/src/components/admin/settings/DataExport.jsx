import { Download, FileSpreadsheet } from "lucide-react";
import { useAdmin } from "../../../context/AdminContext";
import { Card } from "../ui";
import { downloadCSV, toCSV } from "../../../lib/csv";
import { formatDate } from "../../../lib/format";
import { planStatus } from "../../../lib/users";
import { mapAppointment } from "../../../lib/appointments";

const list = (v) => (Array.isArray(v) ? v.join("; ") : (v ?? ""));
const today = () => new Date().toISOString().slice(0, 10);

export default function DataExport() {
  const { users, doctors, appointments } = useAdmin();

  const exports = [
    {
      key: "users",
      label: "Users",
      count: users.length,
      text: "Name, email, plan, subscription dates, joined and last active",
      build: () =>
        toCSV(users, [
          { label: "Name", value: (u) => u.displayName },
          { label: "Email", value: (u) => u.email },
          { label: "Plan", value: (u) => planStatus(u) },
          {
            label: "Subscription",
            value: (u) => u.subscriptionTitle ?? u.subscriptionPlan,
          },
          { label: "Price (Rs.)", value: (u) => u.subscriptionPrice },
          {
            label: "Started",
            value: (u) => formatDate(u.subscriptionStartedAt),
          },
          {
            label: "Expires",
            value: (u) => formatDate(u.subscriptionExpiresAt),
          },
          {
            label: "Payment",
            value: (u) =>
              [u.paymentProvider, u.paymentMode].filter(Boolean).join(" / "),
          },
          { label: "Joined", value: (u) => formatDate(u.createdAt) },
          { label: "Last active", value: (u) => formatDate(u.lastLoginAt) },
          { label: "User ID", value: (u) => u.id },
        ]),
    },
    {
      key: "subscriptions",
      label: "Subscriptions",
      count: users.filter((u) => u.isPaid).length,
      text: "Only users who have paid, with amount, provider and status",
      build: () =>
        toCSV(
          users.filter((u) => u.isPaid),
          [
            { label: "Name", value: (u) => u.displayName },
            { label: "Email", value: (u) => u.email },
            {
              label: "Plan",
              value: (u) => u.subscriptionTitle ?? u.subscriptionPlan,
            },
            { label: "Amount (Rs.)", value: (u) => u.subscriptionPrice },
            { label: "Months", value: (u) => u.subscriptionMonths },
            {
              label: "Started",
              value: (u) => formatDate(u.subscriptionStartedAt),
            },
            {
              label: "Expires",
              value: (u) => formatDate(u.subscriptionExpiresAt),
            },
            { label: "Status", value: (u) => planStatus(u) },
            {
              label: "Cancels at period end",
              value: (u) => (u.subscriptionCancelAtPeriodEnd ? "Yes" : "No"),
            },
            { label: "Provider", value: (u) => u.paymentProvider },
            { label: "Mode", value: (u) => u.paymentMode },
          ],
        ),
    },
    {
      key: "doctors",
      label: "Doctors",
      count: doctors.length,
      text: "Profile, clinic, contact, rating and availability",
      build: () =>
        toCSV(doctors, [
          { label: "Name", value: (d) => d.name },
          { label: "Specialization", value: (d) => list(d.specialization) },
          { label: "Qualification", value: (d) => d.qualification },
          {
            label: "Hospital",
            value: (d) => d.hospital ?? d.Clinic ?? d.clinic,
          },
          { label: "Clinic", value: (d) => d.clinicName },
          { label: "Address", value: (d) => d.clinicAddress },
          { label: "Phone", value: (d) => d.phone },
          { label: "Email", value: (d) => d.email },
          { label: "Experience (years)", value: (d) => d.experienceYears },
          { label: "Rating", value: (d) => d.rating },
          { label: "Fee (Rs.)", value: (d) => d.consultationFee },
          { label: "Available", value: (d) => (d.available ? "Yes" : "No") },
          { label: "Active", value: (d) => (d.isActive ? "Yes" : "No") },
        ]),
    },
    {
      key: "appointments",
      label: "Appointments",
      count: appointments.length,
      text: "Patient, doctor, date, time, type and status",
      build: () => {
        const usersById = Object.fromEntries(users.map((u) => [u.id, u]));
        const doctorsById = Object.fromEntries(doctors.map((d) => [d.id, d]));
        const rows = appointments.map((a) =>
          mapAppointment(a, usersById, doctorsById),
        );
        return toCSV(rows, [
          { label: "Patient", value: (a) => a.patient },
          { label: "Doctor", value: (a) => a.doctor },
          { label: "Date", value: (a) => formatDate(a.date) },
          { label: "Time", value: (a) => a.time },
          { label: "Type", value: (a) => a.type },
          { label: "Status", value: (a) => a.status },
        ]);
      },
    },
  ];

  return (
    <Card
      title="Export data"
      subtitle="Download a CSV that opens in Excel or Google Sheets"
    >
      <ul className="mt-4 divide-y divide-black/5">
        {exports.map((e) => (
          <li key={e.key} className="flex items-center gap-4 py-3.5">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700">
              <FileSpreadsheet size={18} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold">
                {e.label}{" "}
                <span className="font-normal text-gray-400">
                  · {e.count} rows
                </span>
              </p>
              <p className="text-xs text-gray-500">{e.text}</p>
            </div>
            <button
              onClick={() =>
                downloadCSV(`seva-${e.key}-${today()}.csv`, e.build())
              }
              disabled={e.count === 0}
              className="flex items-center gap-1.5 rounded-full border border-black/10 px-4 py-2 text-xs font-semibold hover:bg-mist disabled:opacity-40"
            >
              <Download size={14} /> CSV
            </button>
          </li>
        ))}
      </ul>
      <p className="mt-3 text-xs text-gray-500">
        These files contain personal and health-related information. Keep them
        private and delete them when you're done.
      </p>
    </Card>
  );
}
