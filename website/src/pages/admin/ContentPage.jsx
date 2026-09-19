import { useMemo, useState } from "react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {
  Eye,
  EyeOff,
  LoaderCircle,
  Newspaper,
  Pencil,
  Plus,
  Trash2,
} from "lucide-react";
import { db } from "../../lib/firebase";
import useCollection from "../../hooks/useCollection";
import { Card } from "../../components/admin/ui";
import Modal from "../../components/admin/Modal";
import Tabs from "../../components/admin/Tabs";
import SearchInput from "../../components/admin/SearchInput";
import ContentForm from "../../components/admin/ContentForm";
import {
  CONTENT_COLLECTION,
  CONTENT_TYPES,
  STARTER_CONTENT,
  audienceLabel,
  typeOf,
} from "../../lib/content";
import { toDate } from "../../lib/dashboardStats";
import { formatDate } from "../../lib/format";

function ContentCard({ item, onEdit, onDelete, onTogglePublish }) {
  const type = typeOf(item.type);

  return (
    <article className="flex flex-col overflow-hidden rounded-3xl border border-black/5 bg-white">
      {item.imageUrl && (
        <img src={item.imageUrl} alt="" className="h-36 w-full object-cover" />
      )}
      <div className="flex flex-1 flex-col p-5">
        <div className="flex flex-wrap items-center gap-2 text-[11px] font-semibold">
          <span className={`rounded-md px-2 py-0.5 ${type.tint}`}>
            {type.label}
          </span>
          {item.category && (
            <span className="rounded-md bg-mist px-2 py-0.5 text-gray-600">
              {item.category}
            </span>
          )}
          <span className="rounded-md bg-mist px-2 py-0.5 text-gray-600">
            {audienceLabel(item.audience)}
          </span>
          <span
            className={`ml-auto rounded-md px-2 py-0.5 ${item.published ? "bg-brand-50 text-brand-700" : "bg-gray-100 text-gray-500"}`}
          >
            {item.published ? "Published" : "Draft"}
          </span>
        </div>

        <h3 className="mt-3 font-semibold">{item.title}</h3>
        <p className="mt-1.5 line-clamp-3 flex-1 text-sm text-gray-600">
          {item.body}
        </p>

        <div className="mt-4 flex items-center justify-between border-t border-black/5 pt-3">
          <p className="text-xs text-gray-400">
            Updated {formatDate(item.updatedAt ?? item.createdAt)}
          </p>
          <div className="flex gap-1">
            <button
              onClick={onTogglePublish}
              className="rounded-lg p-2 text-gray-500 hover:bg-mist hover:text-ink"
              aria-label={item.published ? "Unpublish" : "Publish"}
              title={item.published ? "Unpublish" : "Publish"}
            >
              {item.published ? <EyeOff size={15} /> : <Eye size={15} />}
            </button>
            <button
              onClick={onEdit}
              className="rounded-lg p-2 text-gray-500 hover:bg-mist hover:text-ink"
              aria-label="Edit"
            >
              <Pencil size={15} />
            </button>
            <button
              onClick={onDelete}
              className="rounded-lg p-2 text-gray-500 hover:bg-red-50 hover:text-red-600"
              aria-label="Delete"
            >
              <Trash2 size={15} />
            </button>
          </div>
        </div>
      </div>
    </article>
  );
}

// /admin/content
export default function ContentPage() {
  const content = useCollection(CONTENT_COLLECTION);
  const [type, setType] = useState("all");
  const [search, setSearch] = useState("");
  const [editing, setEditing] = useState(undefined); // undefined = closed, null = new, object = edit
  const [deleting, setDeleting] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    return content.data
      .filter((c) => type === "all" || c.type === type)
      .filter(
        (c) =>
          !q || `${c.title} ${c.body} ${c.category}`.toLowerCase().includes(q),
      )
      .sort(
        (a, b) =>
          (toDate(b.updatedAt ?? b.createdAt)?.getTime() ?? 0) -
          (toDate(a.updatedAt ?? a.createdAt)?.getTime() ?? 0),
      );
  }, [content.data, type, search]);
  const publishedCount = content.data.filter((c) => c.published).length;

  const run = async (fn) => {
    setError("");
    try {
      await fn();
    } catch (err) {
      setError(
        err.code === "permission-denied"
          ? "You do not have permission to change content."
          : err.message,
      );
    }
  };

  const save = async (data) => {
    if (editing?.id)
      await updateDoc(doc(db, CONTENT_COLLECTION, editing.id), {
        ...data,
        updatedAt: serverTimestamp(),
      });
    else
      await addDoc(collection(db, CONTENT_COLLECTION), {
        ...data,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
  };

  const addStarter = async () => {
    setBusy(true);
    await run(async () => {
      const batch = writeBatch(db);
      for (const item of STARTER_CONTENT) {
        batch.set(doc(collection(db, CONTENT_COLLECTION)), {
          ...item,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      }
      await batch.commit();
    });
    setBusy(false);
  };

  if (content.loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (content.error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load content: {content.error.message}
      </p>
    );

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight">Content</h1>
          <p className="mt-0.5 text-sm text-gray-500">
            Articles, tips, banners and FAQs shown in the app.{" "}
            {content.data.length} items · {publishedCount} published
          </p>
        </div>
        <button
          onClick={() => setEditing(null)}
          className="flex items-center gap-2 rounded-full bg-ink px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-800"
        >
          <Plus size={16} /> New content
        </button>
      </div>

      {error && (
        <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </p>
      )}

      {content.data.length === 0 ? (
        <Card className="text-center">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-blue-50 text-blue-600">
            <Newspaper size={24} />
          </span>
          <h2 className="mt-4 text-lg font-semibold">No content yet</h2>
          <p className="mx-auto mt-1 max-w-md text-sm text-gray-500">
            Write health articles, daily tips, promo banners and FAQs for the
            app.
          </p>
          <div className="mt-5 flex justify-center gap-2">
            <button
              onClick={addStarter}
              disabled={busy}
              className="flex items-center gap-2 rounded-full bg-brand-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-800 disabled:opacity-60"
            >
              {busy && <LoaderCircle size={15} className="animate-spin" />} Add
              4 starter items
            </button>
            <button
              onClick={() => setEditing(null)}
              className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
            >
              Start from scratch
            </button>
          </div>
        </Card>
      ) : (
        <>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <Tabs
              tabs={[{ key: "all", label: "All" }, ...CONTENT_TYPES]}
              value={type}
              onChange={setType}
            />
            <SearchInput
              value={search}
              onChange={setSearch}
              placeholder="Search content…"
            />
          </div>
          <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
            {visible.map((item) => (
              <ContentCard
                key={item.id}
                item={item}
                onEdit={() => setEditing(item)}
                onDelete={() => setDeleting(item)}
                onTogglePublish={() =>
                  run(() =>
                    updateDoc(doc(db, CONTENT_COLLECTION, item.id), {
                      published: !item.published,
                      updatedAt: serverTimestamp(),
                    }),
                  )
                }
              />
            ))}
          </div>
          {visible.length === 0 && (
            <p className="py-10 text-center text-sm text-gray-500">
              Nothing matches.
            </p>
          )}
        </>
      )}

      {editing !== undefined && (
        <ContentForm
          item={editing}
          onSave={save}
          onClose={() => setEditing(undefined)}
        />
      )}

      {deleting && (
        <Modal
          title="Delete content?"
          onClose={() => setDeleting(null)}
          footer={
            <>
              <button
                onClick={() => setDeleting(null)}
                className="rounded-full border border-black/10 px-5 py-2.5 text-sm font-semibold hover:bg-mist"
              >
                Cancel
              </button>
              <button
                onClick={() =>
                  run(async () => {
                    await deleteDoc(doc(db, CONTENT_COLLECTION, deleting.id));
                    setDeleting(null);
                  })
                }
                className="rounded-full bg-red-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-red-700"
              >
                Delete
              </button>
            </>
          }
        >
          <p className="text-sm text-gray-600">
            <strong className="text-ink">{deleting.title}</strong> will be
            removed from the app. To hide it for now, unpublish it instead.
          </p>
        </Modal>
      )}
    </div>
  );
}
