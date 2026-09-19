import { useState } from "react";
import { Link } from "react-router";
import {
  collection,
  doc,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import { LoaderCircle } from "lucide-react";
import { db } from "../../lib/firebase";
import Modal from "./Modal";
import { StatusPill } from "./ui";
import { APPLICATIONS, doctorFromApplication } from "../../lib/applications";
import { formatDate, npr } from "../../lib/format";

const list = (v) => (Array.isArray(v) ? v.join(", ") : v || "—");

function Row({ label, value }) {
  return (
    <div className="grid grid-cols-[140px_1fr] gap-3 py-2 text-sm">
      <dt className="text-gray-500">{label}</dt>
      <dd className="font-medium break-words">{value || "—"}</dd>
    </div>
  );
}

// Pop-up with the full application and Approve / Reject
export default function ApplicationReview({ application: app, onClose }) {
  const [licenseChecked, setLicenseChecked] = useState(false);
  const [busy, setBusy] = useState(null); // 'approve' | 'reject'
  const [error, setError] = useState("");
  const [createdDoctorId, setCreatedDoctorId] = useState(app.doctorId ?? null);

  async function approve() {
    setBusy("approve");
    setError("");
    try {
      // both writes succeed together or not at all
      const batch = writeBatch(db);
      const doctorRef = doc(collection(db, "doctors"));
      batch.set(
        doctorRef,
        doctorFromApplication(app, { verified: licenseChecked }),
      );
      batch.update(doc(db, APPLICATIONS, app.id), {
        status: "approved",
        doctorId: doctorRef.id,
        reviewedAt: serverTimestamp(),
      });
      await batch.commit();
      setCreatedDoctorId(doctorRef.id);
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to approve doctors."
          : err.message,
      );
    }
    setBusy(null);
  }

  async function reject() {
    setBusy("reject");
    setError("");
    try {
      await updateDoc(doc(db, APPLICATIONS, app.id), {
        status: "rejected",
        reviewedAt: serverTimestamp(),
      });
      onClose();
    } catch (err) {
      setError(err.message);
      setBusy(null);
    }
  }

  const pending = app.status === "pending" && !createdDoctorId;

  return (
    <Modal title="Doctor application" onClose={onClose} wide>
      <div className="max-h-[65vh] overflow-y-auto pr-1">
        <div className="flex flex-wrap items-center gap-2">
          <p className="text-lg font-semibold">{app.name}</p>
          <StatusPill
            status={
              createdDoctorId
                ? "Approved"
                : app.status === "rejected"
                  ? "Rejected"
                  : "Pending"
            }
          />
        </div>
        <p className="text-sm text-gray-500">
          Applied {formatDate(app.createdAt)}
        </p>

        <dl className="mt-4 divide-y divide-black/5">
          <Row
            label="NMC number"
            value={<span className="font-mono">{app.licenseNumber}</span>}
          />
          <Row label="Specialization" value={list(app.specialization)} />
          <Row label="Qualification" value={app.qualification} />
          <Row
            label="Experience"
            value={
              app.experienceYears != null
                ? `${app.experienceYears} years`
                : null
            }
          />
          <Row label="Hospital" value={app.hospital} />
          <Row label="Clinic" value={app.clinicName} />
          <Row label="Address" value={app.clinicAddress} />
          <Row
            label="Fee"
            value={
              app.consultationFee != null ? npr(app.consultationFee) : null
            }
          />
          <Row label="Languages" value={list(app.languages)} />
          <Row
            label="Email"
            value={
              app.email && (
                <a
                  href={`mailto:${app.email}`}
                  className="text-brand-700 hover:underline"
                >
                  {app.email}
                </a>
              )
            }
          />
          <Row
            label="Phone"
            value={
              app.phone && (
                <a
                  href={`tel:${app.phone}`}
                  className="text-brand-700 hover:underline"
                >
                  {app.phone}
                </a>
              )
            }
          />
          <Row label="About" value={app.about} />
        </dl>
      </div>

      {error && (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}

      {createdDoctorId ? (
        <div className="mt-5 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-brand-50 p-4">
          <p className="text-sm font-medium text-brand-700">
            Approved. {app.name} is now on SEVA.
          </p>
          <Link
            to={`/admin/doctors/${createdDoctorId}`}
            className="rounded-full bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-brand-800"
          >
            Open profile
          </Link>
        </div>
      ) : pending ? (
        <div className="mt-5 space-y-4">
          <label className="flex items-start gap-3 rounded-2xl border border-black/10 p-4 text-sm">
            <input
              type="checkbox"
              checked={licenseChecked}
              onChange={(e) => setLicenseChecked(e.target.checked)}
              className="mt-0.5 h-4 w-4 accent-brand-700"
            />
            <span>
              I've checked <strong>{app.licenseNumber}</strong> with the Nepal
              Medical Council.
              <span className="block text-xs text-gray-500">
                The profile is marked Verified only if this is ticked.
              </span>
            </span>
          </label>
          <div className="flex justify-end gap-2">
            <button
              onClick={reject}
              disabled={!!busy}
              className="flex items-center gap-2 rounded-full border border-red-200 px-5 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50"
            >
              {busy === "reject" && (
                <LoaderCircle size={15} className="animate-spin" />
              )}{" "}
              Reject
            </button>
            <button
              onClick={approve}
              disabled={!!busy}
              className="flex items-center gap-2 rounded-full bg-brand-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-50"
            >
              {busy === "approve" && (
                <LoaderCircle size={15} className="animate-spin" />
              )}{" "}
              Approve &amp; add doctor
            </button>
          </div>
        </div>
      ) : null}
    </Modal>
  );
}
