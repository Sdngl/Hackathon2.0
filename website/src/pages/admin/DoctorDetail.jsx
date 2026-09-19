import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";
import { deleteDoc, doc, updateDoc } from "firebase/firestore";
import {
  ArrowLeft,
  BadgeCheck,
  Briefcase,
  Clock,
  LoaderCircle,
  Mail,
  MapPin,
  Pencil,
  Phone,
  Star,
  Trash2,
  Users,
  Wallet,
  Building2,
} from "lucide-react";
import { db } from "../../lib/firebase";
import useDocument from "../../hooks/useDocument";
import { Avatar, Card, StatusPill } from "../../components/admin/ui";
import Modal from "../../components/admin/Modal";
import DoctorForm from "../../components/admin/DoctorForm";

const asList = (v) => (Array.isArray(v) ? v : v ? [v] : []);

function Chips({ items, empty = "Not added yet" }) {
  if (items.length === 0)
    return <p className="text-sm text-gray-400">{empty}</p>;
  return (
    <div className="flex flex-wrap gap-2">
      {items.map((item) => (
        <span
          key={item}
          className="rounded-full bg-mist px-3 py-1 text-xs font-medium"
        >
          {item}
        </span>
      ))}
    </div>
  );
}

function Info({ icon: Icon, label, value }) {
  return (
    <div className="flex gap-3">
      <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-mist text-gray-500">
        <Icon size={16} />
      </span>
      <div className="min-w-0">
        <p className="text-xs text-gray-500">{label}</p>
        <p className="truncate text-sm font-medium">{value || "—"}</p>
      </div>
    </div>
  );
}

export default function DoctorDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { data: doctor, loading, error } = useDocument("doctors", id);
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState("");

  if (loading) {
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  }

  if (error || !doctor) {
    return (
      <Card>
        <p className="font-semibold">
          {error ? "Couldn't load this doctor." : "Doctor not found."}
        </p>
        <p className="mt-1 text-sm text-gray-500">
          {error?.message ?? "It may have been deleted."}
        </p>
        <Link
          to="/admin/doctors"
          className="mt-4 inline-block text-sm font-semibold text-brand-700"
        >
          ← Back to doctors
        </Link>
      </Card>
    );
  }

  async function save(changes) {
    await updateDoc(doc(db, "doctors", id), changes);
    setEditing(false);
  }

  async function remove() {
    setDeleting(true);
    try {
      await deleteDoc(doc(db, "doctors", id));
      navigate("/admin/doctors", { replace: true });
    } catch (err) {
      setDeleteError(
        err.code === "permission-denied"
          ? "You do not have permission to delete doctors."
          : err.message,
      );
      setDeleting(false);
    }
  }

  const hospital = doctor.hospital ?? doctor.Clinic ?? doctor.clinic;
  const fee =
    doctor.consultationFee != null
      ? `Rs. ${Number(doctor.consultationFee).toLocaleString("en-IN")}`
      : "—";

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Link
          to="/admin/doctors"
          className="flex items-center gap-1.5 text-sm text-gray-600 hover:text-ink"
        >
          <ArrowLeft size={16} /> All doctors
        </Link>
        {!editing && (
          <div className="flex gap-2">
            <button
              onClick={() => setEditing(true)}
              className="flex items-center gap-2 rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-brand-800"
            >
              <Pencil size={14} /> Edit
            </button>
            <button
              onClick={() => setConfirmDelete(true)}
              className="flex items-center gap-2 rounded-full border border-red-200 bg-white px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50"
            >
              <Trash2 size={14} /> Delete
            </button>
          </div>
        )}
      </div>

      {editing ? (
        <DoctorForm
          doctor={doctor}
          onSave={save}
          onCancel={() => setEditing(false)}
        />
      ) : (
        <>
          {/* header */}
          <Card>
            <div className="flex flex-wrap items-center gap-5">
              <Avatar
                name={doctor.name ?? "?"}
                photo={doctor.imageUrl}
                size="h-20 w-20 text-xl"
              />
              <div className="flex-1">
                <h1 className="flex flex-wrap items-center gap-2 text-2xl font-bold tracking-tight">
                  {doctor.name ?? "Unnamed doctor"}
                  {doctor.verified && (
                    <BadgeCheck
                      size={22}
                      className="text-blue-500"
                      aria-label="Verified"
                    />
                  )}
                </h1>
                <p className="mt-1 text-sm text-gray-600">
                  {[
                    asList(doctor.specialization).join(", "),
                    doctor.qualification,
                  ]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
                <div className="mt-3 flex flex-wrap gap-2">
                  <StatusPill
                    status={doctor.isActive ? "Active" : "Inactive"}
                  />
                  <StatusPill
                    status={doctor.available ? "Available" : "Busy"}
                  />
                  {doctor.verified && <StatusPill status="Verified" />}
                </div>
              </div>
            </div>
          </Card>

          {/* numbers */}
          <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-5">
            {[
              {
                icon: Star,
                label: "Rating",
                value: doctor.rating ?? "—",
                note:
                  doctor.reviewCount != null
                    ? `${doctor.reviewCount} reviews`
                    : null,
              },
              {
                icon: Users,
                label: "Patients",
                value: doctor.patientCount?.toLocaleString("en-IN") ?? "—",
              },
              {
                icon: Briefcase,
                label: "Experience",
                value: `${doctor.experienceYears ?? 0} yrs`,
              },
              { icon: Wallet, label: "Consultation fee", value: fee },
              {
                icon: Clock,
                label: "Open slots",
                value: asList(doctor.availableSlots).length,
              },
            ].map(({ icon: Icon, label, value, note }) => (
              <div
                key={label}
                className="rounded-3xl border border-black/5 bg-white p-5"
              >
                <Icon size={18} className="text-brand-700" />
                <p className="mt-3 text-2xl font-bold tracking-tight">
                  {value}
                </p>
                <p className="text-xs text-gray-500">{note ?? label}</p>
              </div>
            ))}
          </div>

          <div className="grid gap-5 xl:grid-cols-[1.4fr_1fr]">
            <div className="space-y-5">
              <Card title="About">
                <p className="mt-3 text-sm leading-relaxed text-gray-600">
                  {doctor.about || "No description added yet."}
                </p>
              </Card>
              <Card title="Specialties">
                <div className="mt-3">
                  <Chips items={asList(doctor.specialties)} />
                </div>
              </Card>
              <Card title="Available slots">
                <div className="mt-3">
                  <Chips
                    items={asList(doctor.availableSlots)}
                    empty="No slots added"
                  />
                </div>
              </Card>
            </div>

            <Card title="Clinic & contact">
              <div className="mt-4 space-y-4">
                <Info icon={Building2} label="Hospital" value={hospital} />
                <Info
                  icon={Building2}
                  label="Clinic"
                  value={doctor.clinicName}
                />
                <Info
                  icon={MapPin}
                  label="Address"
                  value={doctor.clinicAddress}
                />
                <Info icon={Clock} label="Hours" value={doctor.clinicHours} />
                <Info icon={Phone} label="Phone" value={doctor.phone} />
                <Info icon={Mail} label="Email" value={doctor.email} />
                <div>
                  <p className="mb-2 text-xs text-gray-500">Languages</p>
                  <Chips items={asList(doctor.languages)} />
                </div>
              </div>
            </Card>
          </div>
        </>
      )}

      {confirmDelete && (
        <Modal
          title="Delete doctor?"
          onClose={() => setConfirmDelete(false)}
          footer={
            <>
              <button
                onClick={() => setConfirmDelete(false)}
                className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
              >
                Cancel
              </button>
              <button
                onClick={remove}
                disabled={deleting}
                className="flex items-center gap-2 rounded-full bg-red-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60"
              >
                {deleting && (
                  <LoaderCircle size={15} className="animate-spin" />
                )}
                Delete permanently
              </button>
            </>
          }
        >
          <p className="text-sm text-gray-600">
            <strong className="text-ink">{doctor.name}</strong> will be removed
            from SEVA and disappear from the app straight away. This can't be
            undone.
          </p>
          {deleteError && (
            <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
              {deleteError}
            </p>
          )}
        </Modal>
      )}
    </div>
  );
}
