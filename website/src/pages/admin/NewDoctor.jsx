import { Link, useNavigate } from "react-router";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { ArrowLeft } from "lucide-react";
import { db } from "../../lib/firebase";
import DoctorForm from "../../components/admin/DoctorForm";

// Starting values for a brand-new doctor
const NEW_DOCTOR = { available: true, isActive: true, verified: false };

// /admin/doctors/new
export default function NewDoctor() {
  const navigate = useNavigate();

  async function create(fields) {
    const ref = await addDoc(collection(db, "doctors"), {
      imageUrl: "",
      rating: 0,
      reviewCount: 0, // defaults the app expects on every doctor
      ...fields,
      Clinic: fields.hospital || fields.clinicName || "", // older field name the app already reads
      createdAt: serverTimestamp(),
    });
    navigate(`/admin/doctors/${ref.id}`, { replace: true });
  }

  return (
    <div className="space-y-5">
      <Link
        to="/admin/doctors"
        className="flex w-fit items-center gap-1.5 text-sm text-gray-600 hover:text-ink"
      >
        <ArrowLeft size={16} /> All doctors
      </Link>
      <h1 className="text-xl font-bold tracking-tight">Add a doctor</h1>
      <DoctorForm
        doctor={NEW_DOCTOR}
        onSave={create}
        onCancel={() => navigate("/admin/doctors")}
        submitLabel="Add doctor"
      />
    </div>
  );
}
