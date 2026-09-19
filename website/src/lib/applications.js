// Doctor applications from the public "Join as a doctor" form.
// Stored in "doctorApplications"; the admin reviews them on the Doctors page.
// Approving creates a real document in "doctors".
import { serverTimestamp } from "firebase/firestore";

export const APPLICATIONS = "doctorApplications";

export const APPLICATION_STATUSES = [
  { key: "pending", label: "Pending" },
  { key: "approved", label: "Approved" },
  { key: "rejected", label: "Rejected" },
];

const toNumber = (text) => (text === "" ? null : Number(text));

// Form values → the document saved in doctorApplications
export function applicationFromForm(form) {
  return {
    name: form.name.trim(),
    email: form.email.trim().toLowerCase(),
    phone: form.phone.trim(),
    specialization: form.specialization, // already a list from the picker
    qualification: form.qualification.trim(),
    licenseNumber: form.licenseNumber.trim().toUpperCase(),
    experienceYears: toNumber(form.experienceYears),
    hospital: form.hospital.trim(),
    clinicName: form.clinicName.trim(),
    clinicAddress: form.clinicAddress.trim(),
    consultationFee: toNumber(form.consultationFee),
    languages: form.languages,
    about: form.about.trim(),
    status: "pending",
    createdAt: serverTimestamp(),
  };
}

// An approved application → a new document in "doctors".
// Fields the app may expect (rating, imageUrl, Clinic) get safe defaults.
export function doctorFromApplication(app, { verified }) {
  return {
    name: app.name,
    email: app.email,
    phone: app.phone,
    specialization: app.specialization ?? [],
    qualification: app.qualification ?? "",
    licenseNumber: app.licenseNumber ?? "",
    experienceYears: app.experienceYears ?? 0,
    hospital: app.hospital ?? "",
    clinicName: app.clinicName ?? "",
    Clinic: app.hospital || app.clinicName || "", // older field name the app already reads
    clinicAddress: app.clinicAddress ?? "",
    consultationFee: app.consultationFee ?? 0,
    languages: app.languages ?? [],
    about: app.about ?? "",
    imageUrl: "",
    rating: 0,
    reviewCount: 0,
    verified,
    available: true,
    isActive: true,
    applicationId: app.id,
    createdAt: serverTimestamp(),
  };
}
