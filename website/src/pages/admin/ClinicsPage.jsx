import { useMemo, useState } from "react";
import { Link } from "react-router";
import {
  Building2,
  Clock,
  LoaderCircle,
  Mail,
  MapPin,
  Phone,
} from "lucide-react";
import useCollection from "../../hooks/useCollection";
import { Avatar, Card } from "../../components/admin/ui";
import SearchInput from "../../components/admin/SearchInput";
import { doctorsWithoutClinic, groupClinics } from "../../lib/clinics";

function ClinicCard({ clinic }) {
  const details = [
    { icon: MapPin, value: clinic.address },
    { icon: Clock, value: clinic.hours },
    { icon: Phone, value: clinic.phone },
    { icon: Mail, value: clinic.email },
  ].filter((d) => d.value);

  return (
    <article className="flex flex-col rounded-3xl border border-black/5 bg-white p-6">
      <div className="flex items-start gap-3">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700">
          <Building2 size={20} />
        </span>
        <div className="min-w-0 flex-1">
          <h2 className="font-semibold">{clinic.name}</h2>
          <p className="text-xs text-gray-500">
            {clinic.doctors.length} doctor{clinic.doctors.length !== 1 && "s"} ·{" "}
            {clinic.availableCount} available now
          </p>
        </div>
      </div>

      {details.length > 0 && (
        <ul className="mt-4 space-y-1.5 text-sm text-gray-600">
          {details.map(({ icon: Icon, value }) => (
            <li key={value} className="flex items-center gap-2">
              <Icon size={14} className="shrink-0 text-gray-400" />
              {value}
            </li>
          ))}
        </ul>
      )}

      {clinic.specializations.length > 0 && (
        <div className="mt-4 flex flex-wrap gap-1.5">
          {clinic.specializations.map((s) => (
            <span
              key={s}
              className="rounded-full bg-mist px-2.5 py-1 text-xs font-medium"
            >
              {s}
            </span>
          ))}
        </div>
      )}

      <ul className="mt-5 flex-1 space-y-2 border-t border-black/5 pt-4">
        {clinic.doctors.map((d) => (
          <li key={d.id}>
            <Link
              to={`/admin/doctors/${d.id}`}
              className="group flex items-center gap-3 text-sm"
            >
              <Avatar name={d.name ?? "?"} photo={d.imageUrl} size="h-8 w-8" />
              <span className="flex-1 font-medium group-hover:text-brand-700 group-hover:underline">
                {d.name}
              </span>
              <span
                className={`h-2 w-2 rounded-full ${d.available && d.isActive ? "bg-brand-500" : "bg-gray-300"}`}
                title={d.available && d.isActive ? "Available" : "Unavailable"}
              />
            </Link>
          </li>
        ))}
      </ul>
    </article>
  );
}

// /admin/clinics
export default function ClinicsPage() {
  const { data: doctors, loading, error } = useCollection("doctors");
  const [search, setSearch] = useState("");

  const clinics = useMemo(() => groupClinics(doctors), [doctors]);
  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return clinics;
    return clinics.filter((c) =>
      [c.name, c.address, ...c.specializations, ...c.doctors.map((d) => d.name)]
        .filter(Boolean)
        .some((text) => text.toLowerCase().includes(q)),
    );
  }, [clinics, search]);
  const unassigned = doctorsWithoutClinic(doctors).length;

  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load clinics: {error.message}
      </p>
    );

  return (
    <div className="space-y-5">
      <Card
        title="Clinics"
        subtitle={`${clinics.length} clinics from ${doctors.length} doctors${unassigned ? ` · ${unassigned} doctor${unassigned > 1 ? "s" : ""} with no clinic set` : ""}`}
        action={
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Search clinic, area or specialty…"
          />
        }
      />

      {visible.length === 0 ? (
        <p className="rounded-3xl bg-white py-16 text-center text-sm text-gray-500">
          {clinics.length === 0
            ? "No clinics yet. Add a clinic name to a doctor to see it here."
            : "No clinics match your search."}
        </p>
      ) : (
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {visible.map((c) => (
            <ClinicCard key={c.id} clinic={c} />
          ))}
        </div>
      )}
    </div>
  );
}
