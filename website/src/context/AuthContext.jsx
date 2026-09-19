import { createContext, useContext, useEffect, useState } from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";
import { auth, ADMIN_EMAIL } from "../lib/firebase";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Firebase remembers the session, so a page refresh keeps you logged in
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const isAdmin = !!user && user.email === ADMIN_EMAIL;

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

  const logout = () => signOut(auth);

  return (
    <AuthContext.Provider
      value={{ user, isAdmin, loading, loginAdmin, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  return useContext(AuthContext);
}
