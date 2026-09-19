import { useMemo, useState } from "react";
import { Link } from "react-router";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
} from "firebase/firestore";
import {
  CalendarDays,
  CheckCheck,
  CircleAlert,
  Crown,
  LoaderCircle,
  Megaphone,
  Send,
  Stethoscope,
  Trash2,
  UserPlus,
} from "lucide-react";
import { db } from "../../lib/firebase";
import useCollection from "../../hooks/useCollection";
import { useAdmin } from "../../context/AdminContext";
import { Card } from "../../components/admin/ui";
import Modal from "../../components/admin/Modal";
import Tabs from "../../components/admin/Tabs";
import Pagination from "../../components/admin/Pagination";
import { ALERT_TYPES } from "../../lib/alerts";
import { AUDIENCES, audienceLabel } from "../../lib/content";
import { toDate } from "../../lib/dashboardStats";
import { timeAgo } from "../../lib/format";

const ANNOUNCEMENTS = "announcements";
const PAGE_SIZE = 10;

const alertStyle = {
  user: { icon: UserPlus, tint: "bg-brand-50 text-brand-700" },
  subscription: { icon: Crown, tint: "bg-violet-50 text-violet-600" },
  appointment: { icon: CalendarDays, tint: "bg-blue-50 text-blue-600" },
  doctor: { icon: Stethoscope, tint: "bg-sky-50 text-sky-600" },
  warning: { icon: CircleAlert, tint: "bg-amber-50 text-amber-600" },
};

function ActivityFeed() {
  const { alerts, lastSeen, unreadCount, markAllRead } = useAdmin();
  const [type, setType] = useState("all");
  const [page, setPage] = useState(1);

  const list = useMemo(
    () => alerts.filter((a) => type === "all" || a.type === type),
    [alerts, type],
  );
  const pageCount = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = list.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  return (
    <Card
      title="Activity"
      subtitle={
        unreadCount
          ? `${unreadCount} new since you last checked`
          : "You’re all caught up"
      }
      action={
        <div className="flex items-center gap-3">
          <Pagination page={current} pageCount={pageCount} onChange={setPage} />
          <button
            onClick={markAllRead}
            disabled={!unreadCount}
            className="flex items-center gap-1.5 rounded-lg border border-black/10 px-3 py-1.5 text-xs font-semibold hover:bg-mist disabled:opacity-40"
          >
            <CheckCheck size={14} /> Mark all read
          </button>
        </div>
      }
    >
      <div className="mt-4">
        <Tabs
          tabs={ALERT_TYPES}
          value={type}
          onChange={(k) => {
            setType(k);
            setPage(1);
          }}
        />
      </div>

      <ul className="mt-3 divide-y divide-black/5">
        {visible.map((a) => {
          const { icon: Icon, tint } =
            alertStyle[a.tone === "warning" ? "warning" : a.type];
          const unread = a.time.getTime() > lastSeen;
          return (
            <li key={a.id}>
              <Link
                to={a.link}
                className="-mx-2 flex items-start gap-3 rounded-xl px-2 py-3 hover:bg-mist/70"
              >
                <span
                  className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl ${tint}`}
                >
                  <Icon size={16} />
                </span>
                <span className="min-w-0 flex-1">
                  <span
                    className={`block text-sm ${unread ? "font-semibold" : "font-medium text-gray-700"}`}
                  >
                    {a.title}
                  </span>
                  {a.body && (
                    <span className="block truncate text-xs text-gray-500">
                      {a.body}
                    </span>
                  )}
                </span>
                <span className="shrink-0 text-xs text-gray-400">
                  {timeAgo(a.time)}
                </span>
                {unread && (
                  <span
                    className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-red-500"
                    aria-label="Unread"
                  />
                )}
              </Link>
            </li>
          );
        })}
      </ul>
      {list.length === 0 && (
        <p className="py-10 text-center text-sm text-gray-500">
          Nothing in the last 14 days.
        </p>
      )}
    </Card>
  );
}

function AnnouncementForm({ onClose }) {
  const [form, setForm] = useState({ title: "", message: "", audience: "all" });
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));
  const input =
    "mt-1.5 w-full rounded-xl border border-black/10 bg-white px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100";

  async function send(e) {
    e.preventDefault();
    setSending(true);
    try {
      await addDoc(collection(db, ANNOUNCEMENTS), {
        title: form.title.trim(),
        message: form.message.trim(),
        audience: form.audience,
        createdAt: serverTimestamp(),
      });
      onClose();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to send announcements."
          : err.message,
      );
      setSending(false);
    }
  }

  return (
    <Modal title="New announcement" onClose={onClose}>
      <form onSubmit={send} className="space-y-4">
        <label className="block text-sm font-medium">
          Send to
          <select
            value={form.audience}
            onChange={set("audience")}
            className={input}
          >
            {AUDIENCES.map((a) => (
              <option key={a.key} value={a.key}>
                {a.label}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-sm font-medium">
          Title
          <input
            required
            maxLength={60}
            value={form.title}
            onChange={set("title")}
            className={input}
            placeholder="New doctors on SEVA"
          />
        </label>
        <label className="block text-sm font-medium">
          Message
          <textarea
            required
            maxLength={240}
            rows={3}
            value={form.message}
            onChange={set("message")}
            className={input}
          />
          <span className="mt-1 block text-right text-xs font-normal text-gray-400">
            {form.message.length}/240
          </span>
        </label>
        {error && (
          <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </p>
        )}
        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={sending}
            className="flex items-center gap-2 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
          >
            {sending ? (
              <LoaderCircle size={15} className="animate-spin" />
            ) : (
              <Send size={15} />
            )}{" "}
            Send
          </button>
        </div>
      </form>
    </Modal>
  );
}

function Announcements() {
  const { data, loading, error } = useCollection(ANNOUNCEMENTS);
  const [composing, setComposing] = useState(false);
  const [deleteError, setDeleteError] = useState("");

  const sorted = useMemo(
    () =>
      [...data].sort(
        (a, b) =>
          (toDate(b.createdAt)?.getTime() ?? 0) -
          (toDate(a.createdAt)?.getTime() ?? 0),
      ),
    [data],
  );

  async function remove(id) {
    setDeleteError("");
    try {
      await deleteDoc(doc(db, ANNOUNCEMENTS, id));
    } catch (err) {
      setDeleteError(err.message);
    }
  }

  return (
    <Card
      title="Announcements"
      subtitle="In-app messages for your users"
      action={
        <button
          onClick={() => setComposing(true)}
          className="flex items-center gap-1.5 rounded-full bg-ink px-3.5 py-2 text-xs font-semibold text-white hover:bg-brand-800"
        >
          <Megaphone size={14} /> New
        </button>
      }
    >
      {error && (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          Couldn't load announcements: {error.message}
        </p>
      )}
      {deleteError && (
        <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {deleteError}
        </p>
      )}
      {loading ? (
        <div className="grid place-items-center py-10">
          <LoaderCircle className="animate-spin text-brand-700" />
        </div>
      ) : sorted.length === 0 ? (
        <p className="py-10 text-center text-sm text-gray-500">
          No announcements sent yet.
        </p>
      ) : (
        <ul className="mt-4 space-y-3">
          {sorted.map((a) => (
            <li key={a.id} className="rounded-2xl bg-mist p-4">
              <div className="flex items-start justify-between gap-3">
                <p className="text-sm font-semibold">{a.title}</p>
                <button
                  onClick={() => remove(a.id)}
                  className="rounded-lg p-1 text-gray-400 hover:bg-white hover:text-red-600"
                  aria-label="Delete announcement"
                >
                  <Trash2 size={14} />
                </button>
              </div>
              <p className="mt-1 text-sm text-gray-600">{a.message}</p>
              <p className="mt-2 text-xs text-gray-400">
                {audienceLabel(a.audience)} · {timeAgo(a.createdAt)}
              </p>
            </li>
          ))}
        </ul>
      )}
      {composing && <AnnouncementForm onClose={() => setComposing(false)} />}
    </Card>
  );
}

// /admin/notifications
export default function NotificationsPage() {
  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold tracking-tight">Notifications</h1>
      <div className="grid items-start gap-5 xl:grid-cols-[1.5fr_1fr]">
        <ActivityFeed />
        <Announcements />
      </div>
    </div>
  );
}
