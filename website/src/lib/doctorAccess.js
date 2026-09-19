// Access "passes" that let a doctor see a patient's name and the report they shared.
//
// Firestore rules can't search ("does an appointment with this doctor exist?"),
// they can only check documents at a known path. So for each appointment, the
// doctor dashboard writes a small pass the rules can check:
//
//   doctorAccess/{doctorUid}_{userId}                 → may read that patient's profile
//   reportAccess/{doctorUid}_{userId}_{reportId}      → may read that one report
//
// The rules only allow creating a pass if the appointment really exists, belongs
// to this doctor, and (for reports) really shares that report.
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "./firebase";

export async function grantDoctorAccess({ doctorId, doctorUid, appointments }) {
  const writes = [];
  const seenPatients = new Set();

  for (const a of appointments) {
    if (!a.userId) continue;
    const base = {
      doctorUid,
      doctorId,
      userId: a.userId,
      appointmentId: a.id,
      grantedAt: serverTimestamp(),
    };

    if (!seenPatients.has(a.userId)) {
      seenPatients.add(a.userId);
      writes.push(
        setDoc(doc(db, "doctorAccess", `${doctorUid}_${a.userId}`), base),
      );
    }
    if (a.reportId && a.reportShared !== false) {
      writes.push(
        setDoc(
          doc(db, "reportAccess", `${doctorUid}_${a.userId}_${a.reportId}`),
          { ...base, reportId: a.reportId },
        ),
      );
    }
  }

  // one refused pass (e.g. an old appointment) shouldn't block the others
  await Promise.allSettled(writes);
}
