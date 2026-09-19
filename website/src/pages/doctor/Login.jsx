import { useState } from "react";
import { Link, Navigate, useNavigate } from "react-router";
import { ArrowLeft, LoaderCircle, Lock, Mail } from "lucide-react";
import Logo from "../../components/Logo";
import { useAuth } from "../../context/AuthContext";
import { sendSetPasswordEmail } from "../../lib/doctorAccounts";

function errorMessage(err) {
  if (err.message === "not-doctor")
    return "This account is not linked to a doctor profile. Contact the SEVA team.";
  if (err.message === "inactive")
    return "Your doctor profile is currently inactive. Contact the SEVA team.";
  if (err.code === "auth/invalid-credential")
    return "Email or password is incorrect.";
  if (err.code === "auth/too-many-requests")
    return "Too many attempts. Wait a minute and try again.";
  if (err.code === "auth/network-request-failed")
    return "No connection. Check your internet and try again.";
  return "Could not sign in. Try again.";
}

// /doctor/login
export default function DoctorLogin() {
  const { isDoctor, loginDoctor } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (isDoctor) return <Navigate to="/doctor" replace />;

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    setInfo("");
    setSubmitting(true);
    try {
      await loginDoctor(email, password);
      navigate("/doctor", { replace: true });
    } catch (err) {
      setError(errorMessage(err));
      setSubmitting(false);
    }
  }

  async function forgotPassword() {
    setError("");
    if (!email.includes("@"))
      return setError(
        "Type your email above first, then click “Forgot password?”.",
      );
    try {
      await sendSetPasswordEmail(email.trim());
    } catch {
      // same message either way, so the page doesn't reveal which emails have accounts
    }
    setInfo(
      `If ${email.trim()} has a doctor account, a link to reset the password is on its way.`,
    );
  }

  const input =
    "w-full rounded-xl border border-black/10 bg-white py-3 pr-4 pl-11 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

  return (
    <div className="flex min-h-screen flex-col bg-mist">
      <header className="mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-5 lg:px-8">
        <Logo />
        <Link
          to="/portal"
          className="flex items-center gap-1 text-sm text-gray-600 hover:text-ink"
        >
          <ArrowLeft size={16} /> Back
        </Link>
      </header>

      <main className="grid flex-1 place-items-center px-5 pb-20">
        <div className="w-full max-w-sm">
          <form
            onSubmit={handleSubmit}
            className="rounded-3xl border border-black/5 bg-white p-8 shadow-xl shadow-black/5"
          >
            <h1 className="text-2xl font-bold tracking-tight">
              Doctor sign in
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              Use the email SEVA set up for you.
            </p>

            <label className="mt-6 block text-sm font-medium" htmlFor="email">
              Email
            </label>
            <div className="relative mt-1.5">
              <Mail
                size={16}
                className="absolute top-1/2 left-4 -translate-y-1/2 text-gray-400"
              />
              <input
                id="email"
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={input}
              />
            </div>

            <div className="mt-4 flex items-center justify-between">
              <label className="text-sm font-medium" htmlFor="password">
                Password
              </label>
              <button
                type="button"
                onClick={forgotPassword}
                className="text-xs font-semibold text-brand-700 hover:underline"
              >
                Forgot password?
              </button>
            </div>
            <div className="relative mt-1.5">
              <Lock
                size={16}
                className="absolute top-1/2 left-4 -translate-y-1/2 text-gray-400"
              />
              <input
                id="password"
                type="password"
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={input}
              />
            </div>

            {error && (
              <p
                role="alert"
                className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700"
              >
                {error}
              </p>
            )}
            {info && (
              <p className="mt-4 rounded-xl bg-brand-50 px-4 py-3 text-sm text-brand-700">
                {info}
              </p>
            )}

            <button
              type="submit"
              disabled={submitting}
              className="mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-ink py-3 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
            >
              {submitting && (
                <LoaderCircle size={16} className="animate-spin" />
              )}
              {submitting ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <p className="mt-6 text-center text-sm text-gray-600">
            Not on SEVA yet?{" "}
            <Link
              to="/join-doctor"
              className="font-semibold text-brand-700 hover:underline"
            >
              Apply as a doctor
            </Link>
          </p>
        </div>
      </main>
    </div>
  );
}
