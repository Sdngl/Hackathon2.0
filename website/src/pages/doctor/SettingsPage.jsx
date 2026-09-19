import { useState } from "react";
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword,
} from "firebase/auth";
import { LogOut } from "lucide-react";
import { useAuth } from "../../context/AuthContext";
import { Card } from "../../components/admin/ui";
import SaveButton from "../../components/admin/settings/SaveButton";
import { Field, inputClass } from "../../components/admin/settings/fields";
import { formatDate } from "../../lib/format";

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

// /doctor/settings
export default function DoctorSettingsPage() {
  const { user, logout } = useAuth();
  const [pw, setPw] = useState({ current: "", next: "", confirm: "" });
  const setField = (k) => (e) => setPw((p) => ({ ...p, [k]: e.target.value }));
  const mismatch = pw.confirm !== "" && pw.next !== pw.confirm;
  const ready = pw.current && pw.next.length >= 8 && pw.next === pw.confirm;

  async function save() {
    try {
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
      <Card title="Login">
        <dl className="mt-3 divide-y divide-black/5 text-sm">
          <div className="flex justify-between py-2.5">
            <dt className="text-gray-500">Login email</dt>
            <dd className="font-medium">{user.email}</dd>
          </div>
          <div className="flex justify-between py-2.5">
            <dt className="text-gray-500">Last sign-in</dt>
            <dd className="font-medium">
              {formatDate(user.metadata.lastSignInTime)}
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

      <Card title="Change password">
        <div className="mt-5 grid gap-4 sm:grid-cols-3">
          <Field label="Current password">
            <input
              type="password"
              autoComplete="current-password"
              value={pw.current}
              onChange={setField("current")}
              className={inputClass}
            />
          </Field>
          <Field label="New password" hint="At least 8 characters">
            <input
              type="password"
              autoComplete="new-password"
              value={pw.next}
              onChange={setField("next")}
              className={inputClass}
            />
          </Field>
          <Field
            label="Confirm new password"
            hint={
              mismatch ? (
                <span className="text-red-600">Passwords don't match</span>
              ) : null
            }
          >
            <input
              type="password"
              autoComplete="new-password"
              value={pw.confirm}
              onChange={setField("confirm")}
              className={inputClass}
            />
          </Field>
        </div>
        <div className="mt-5">
          <SaveButton onSave={save} disabled={!ready} label="Update password" />
        </div>
      </Card>
    </div>
  );
}
