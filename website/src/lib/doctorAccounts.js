// Creates login accounts for doctors, from the admin dashboard.
//
// Why a "second" Firebase instance? Creating an account with the normal one would
// sign the admin out and sign in as the new doctor. A separate, temporary instance
// creates the account in the background and is thrown away afterwards.
//
// Why no password in the email? The doctor gets Firebase's own "set your password" link,
// so nobody (including the admin) ever sees or sends their password.
import { deleteApp, initializeApp } from "firebase/app";
import {
  createUserWithEmailAndPassword,
  getAuth,
  sendPasswordResetEmail,
  signOut,
} from "firebase/auth";
import {
  collection,
  doc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import { auth, db, firebaseConfig } from "./firebase";

// After setting their password, the "Continue" button brings the doctor to the login page
const continueTo = () => ({ url: `${window.location.origin}/doctor/login` });

// A long random password nobody will ever use: the doctor replaces it straight away
function randomPassword() {
  const bytes = crypto.getRandomValues(new Uint8Array(24));
  return btoa(String.fromCharCode(...bytes));
}

export async function createDoctorLogin(doctorId, email) {
  const temp = initializeApp(firebaseConfig, `doctor-signup-${Date.now()}`);
  try {
    const tempAuth = getAuth(temp);
    const { user } = await createUserWithEmailAndPassword(
      tempAuth,
      email,
      randomPassword(),
    );
    await signOut(tempAuth);

    // link the new login to the doctor's profile
    await updateDoc(doc(db, "doctors", doctorId), {
      authUid: user.uid,
      loginEmail: email,
      loginCreatedAt: serverTimestamp(),
    });

    await sendSetPasswordEmail(email);
  } finally {
    await deleteApp(temp);
  }
}

export function sendSetPasswordEmail(email) {
  return sendPasswordResetEmail(auth, email, continueTo());
}

// Finds the doctor profile that belongs to a logged-in account (or null)
export async function findDoctorByUid(uid) {
  const snap = await getDocs(
    query(collection(db, "doctors"), where("authUid", "==", uid), limit(1)),
  );
  return snap.empty ? null : { id: snap.docs[0].id, ...snap.docs[0].data() };
}

export function doctorLoginError(err) {
  if (err.code === "auth/email-already-in-use") {
    return "This email already has a SEVA account (maybe as a patient in the app). Use a different email for the doctor login.";
  }
  if (err.code === "auth/invalid-email")
    return "That email address is not valid.";
  if (err.code === "permission-denied")
    return "The login was created, but saving it on the profile was blocked by Firestore rules.";
  if (err.code === "auth/too-many-requests")
    return "Too many attempts. Wait a minute and try again.";
  return err.message;
}
