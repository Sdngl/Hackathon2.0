import {
  createContext,
  useContext,
  useEffect,
  useReducer,
  useState,
} from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";
import { auth, ADMIN_EMAIL } from "../lib/firebase";
import { findDoctorByUid } from "../lib/doctorAccounts";

const AuthContext = createContext(null);

// Who is logged in, and as what:
//   admin  → email matches VITE_ADMIN_EMAIL
//   doctor → a document in "doctors" has authUid equal to this account's uid
export function AuthProvider({ children }) {
  const [state, setState] = useState({
    user: null,
    doctor: null,
    loading: true,
  });
  // bumps after the profile changes (e.g. new display name) so the UI re-renders
  const [, refreshUser] = useReducer((n) => n + 1, 0);

  // Firebase remembers the session, so a page refresh keeps you logged in
  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) return setState({ user: null, doctor: null, loading: false });
      setState((s) => ({ ...s, loading: true }));
      let doctor = null;
      if (user.email !== ADMIN_EMAIL) {
        try {
          doctor = await findDoctorByUid(user.uid);
        } catch {
          doctor = null;
        }
      }
      setState({ user, doctor, loading: false });
    });
  }, []);

  const { user, doctor, loading } = state;
  const isAdmin = !!user && user.email === ADMIN_EMAIL;
  const isDoctor = !!user && !!doctor;

  async function loginAdmin(email, password) {
    const { user: signedIn } = await signInWithEmailAndPassword(
      auth,
      email,
      password,
    );
    if (signedIn.email !== ADMIN_EMAIL) {
      await signOut(auth);
      throw new Error("not-admin");
    }
  }

  async function loginDoctor(email, password) {
    const { user: signedIn } = await signInWithEmailAndPassword(
      auth,
      email,
      password,
    );
    const profile = await findDoctorByUid(signedIn.uid);
    if (!profile) {
      await signOut(auth);
      throw new Error("not-doctor");
    }
    if (profile.isActive === false) {
      await signOut(auth);
      throw new Error("inactive");
    }
    setState({ user: signedIn, doctor: profile, loading: false }); // ready before we navigate
  }

  const logout = () => signOut(auth);

  return (
    <AuthContext.Provider
      value={{
        user,
        doctor,
        isAdmin,
        isDoctor,
        loading,
        loginAdmin,
        loginDoctor,
        logout,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  return useContext(AuthContext);
}
