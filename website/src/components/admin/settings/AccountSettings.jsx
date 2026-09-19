import { useState } from "react";
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword,
  updateProfile,
} from "firebase/auth";
import { LogOut } from "lucide-react";
import { useAuth } from "../../../context/AuthContext";
import { Card } from "../ui";
import SaveButton from "./SaveButton";
import { Field, inputClass } from "./fields";
import { formatDate } from "../../../lib/format";

function passwordError(err) {
  if (
    err.code === "auth/invalid-credential" ||
    err.code === "auth/wrong-password"
  )
    return new Error("Your current password is incorrect.");
  if (err.code === "auth/weak-password")
    return new Error("Choose a stronger password (at least 8 characters).");
  if (err.code === "auth/too-many-requests")
    return new Error("Too many attempts. Wait a minute and try again.");
  return err;
}

export default function AccountSettings() {
  const { user, refreshUser, logout } = useAuth();
  const [name, setName] = useState(user.displayName ?? "");
  const [pw, setPw] = useState({ current: "", next: "", confirm: "" });

  const setPwField = (key) => (e) =>
    setPw((p) => ({ ...p, [key]: e.target.value }));
  const pwMismatch = pw.confirm !== "" && pw.next !== pw.confirm;
  const pwReady = pw.current && pw.next.length >= 8 && pw.next === pw.confirm;

  async function saveName() {
    await updateProfile(user, { displayName: name.trim() });
    refreshUser(); // updates the name in the sidebar
  }

  async function savePassword() {
    try {
      // Firebase asks for the current password before allowing a change
      await reauthenticateWithCredential(
        user,
        EmailAuthProvider.credential(user.email, pw.current),
      );
      await updatePassword(user, pw.next);
      setPw({ current: "", next: "", confirm: "" });
    } catch (err) {
      throw passwordError(err);
    }
  }

  return (
    <div className="space-y-5">
      <Card title="Profile" subtitle="Shown at the bottom of the sidebar">
        <div className="mt-5 grid gap-4 sm:grid-cols-2">
          <Field label="Display name">
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className={inputClass}
              placeholder="Anjali Shrestha"
            />
          </Field>
          <Field
            label="Email"
            hint="The admin email is set in Firebase Authentication and .env"
          >
            <input value={user.email} disabled className={inputClass} />
          </Field>
        </div>
        <div className="mt-5">
          <SaveButton
            onSave={saveName}
            disabled={!name.trim() || name.trim() === (user.displayName ?? "")}
          />
        </div>
      </Card>

      <Card title="Change password">
        <div className="mt-5 grid gap-4 sm:grid-cols-3">
          <Field label="Current password">
            <input
              type="password"
              autoComplete="current-password"
              value={pw.current}
              onChange={setPwField("current")}
              className={inputClass}
            />
          </Field>
          <Field label="New password" hint="At least 8 characters">
            <input
              type="password"
              autoComplete="new-password"
              value={pw.next}
              onChange={setPwField("next")}
              className={inputClass}
            />
          </Field>
          <Field
            label="Confirm new password"
            hint={
              pwMismatch ? (
                <span className="text-red-600">Passwords don't match</span>
              ) : null
            }
          >
            <input
              type="password"
              autoComplete="new-password"
              value={pw.confirm}
              onChange={setPwField("confirm")}
              className={inputClass}
            />
          </Field>
        </div>
        <div className="mt-5">
          <SaveButton
            onSave={savePassword}
            disabled={!pwReady}
            label="Update password"
          />
        </div>
      </Card>

      <Card title="Session">
        <dl className="mt-3 divide-y divide-black/5 text-sm">
          <div className="flex justify-between py-2.5">
            <dt className="text-gray-500">Last sign-in</dt>
            <dd className="font-medium">
              {formatDate(user.metadata.lastSignInTime)}
            </dd>
          </div>
          <div className="flex justify-between py-2.5">
            <dt className="text-gray-500">Account created</dt>
            <dd className="font-medium">
              {formatDate(user.metadata.creationTime)}
            </dd>
          </div>
          <div className="flex justify-between py-2.5">
            <dt className="text-gray-500">Firebase project</dt>
            <dd className="font-mono text-xs text-gray-600">
              {import.meta.env.VITE_FIREBASE_PROJECT_ID}
            </dd>
          </div>
        </dl>
        <button
          onClick={logout}
          className="mt-4 flex items-center gap-2 rounded-full border border-black/10 px-4 py-2 text-sm font-semibold hover:bg-mist"
        >
          <LogOut size={15} /> Sign out
        </button>
      </Card>
    </div>
  );
}
