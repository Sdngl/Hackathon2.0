import { useState } from "react";
import { KeyRound, LoaderCircle, MailCheck, Send } from "lucide-react";
import { Card } from "./ui";
import {
  createDoctorLogin,
  doctorLoginError,
  sendSetPasswordEmail,
} from "../../lib/doctorAccounts";
import { formatDate } from "../../lib/format";

// On the doctor's profile: create their login, or resend the set-password email
export default function DoctorLoginCard({ doctor }) {
  const [email, setEmail] = useState(doctor.loginEmail ?? doctor.email ?? "");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState(null); // { tone: 'ok' | 'error', text }

  async function run(action, success) {
    setBusy(true);
    setMessage(null);
    try {
      await action();
      setMessage({ tone: "ok", text: success });
    } catch (err) {
      setMessage({ tone: "error", text: doctorLoginError(err) });
    }
    setBusy(false);
  }

  const hasLogin = !!doctor.authUid;

  return (
    <Card
      title="Doctor login"
      action={<KeyRound size={18} className="text-gray-400" />}
    >
      {hasLogin ? (
        <>
          <div className="mt-4 flex items-start gap-3 rounded-2xl bg-brand-50 p-4">
            <MailCheck size={18} className="mt-0.5 shrink-0 text-brand-700" />
            <div className="text-sm">
              <p className="font-semibold text-brand-700">Login active</p>
              <p className="text-gray-600">{doctor.loginEmail}</p>
              <p className="mt-1 text-xs text-gray-500">
                Created {formatDate(doctor.loginCreatedAt)}
              </p>
            </div>
          </div>
          <button
            onClick={() =>
              run(
                () => sendSetPasswordEmail(doctor.loginEmail),
                `Sent a new set-password link to ${doctor.loginEmail}.`,
              )
            }
            disabled={busy}
            className="mt-4 flex items-center gap-2 rounded-full border border-black/10 px-4 py-2 text-sm font-semibold hover:bg-mist disabled:opacity-50"
          >
            {busy ? (
              <LoaderCircle size={15} className="animate-spin" />
            ) : (
              <Send size={15} />
            )}{" "}
            Resend set-password email
          </button>
          <p className="mt-2 text-xs text-gray-500">
            Use this if they lost the first email or forgot their password.
          </p>
        </>
      ) : (
        <>
          <p className="mt-3 text-sm text-gray-600">
            Creates an account for the doctor portal and emails a link to choose
            their own password.
          </p>
          <label
            className="mt-4 block text-sm font-medium"
            htmlFor="login-email"
          >
            Login email
            <input
              id="login-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-black/10 px-3.5 py-2.5 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
            />
          </label>
          <button
            onClick={() =>
              run(
                () => createDoctorLogin(doctor.id, email.trim().toLowerCase()),
                   `Login created. ${email.trim()} will get an email titled "Reset your password for SEVA". Tell the doctor to open it and choose their password (check spam too).`,
              )
            }
            disabled={busy || !email.includes("@")}
            className="mt-4 flex w-full items-center justify-center gap-2 rounded-full bg-ink px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-50"
          >
            {busy ? (
              <LoaderCircle size={15} className="animate-spin" />
            ) : (
              <Send size={15} />
            )}{" "}
            Create login &amp; send email
          </button>
        </>
      )}

      {message && (
        <p
          className={`mt-4 rounded-xl px-4 py-3 text-sm ${message.tone === "ok" ? "bg-brand-50 text-brand-700" : "bg-red-50 text-red-700"}`}
        >
          {message.text}
        </p>
      )}
    </Card>
  );
}
