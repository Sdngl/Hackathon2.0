import { useMemo, useState } from "react";
import { Link } from "react-router";
import { ChevronRight, LoaderCircle } from "lucide-react";
import useCollection from "../../hooks/useCollection";
import { Avatar, Card, StatusPill } from "../../components/admin/ui";
import Pagination from "../../components/admin/Pagination";
import SearchInput from "../../components/admin/SearchInput";
import { filterUsers, planStatus } from "../../lib/users";
import { formatDate, timeAgo } from "../../lib/format";

const PAGE_SIZE = 10;
const PLAN_TABS = [
  { key: "all", label: "All" },
  { key: "Plus", label: "Plus" },
  { key: "Free", label: "Free" },
  { key: "Expired", label: "Expired" },
];

// /admin/users
export default function UsersPage() {
  const { data: users, loading, error } = useCollection("users");
  const [search, setSearch] = useState("");
  const [plan, setPlan] = useState("all");
  const [page, setPage] = useState(1);

  const list = useMemo(
    () => filterUsers(users, { search, plan }),
    [users, search, plan],
  );
  const plusCount = useMemo(
    () => users.filter((u) => planStatus(u) === "Plus").length,
    [users],
  );

  const pageCount = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
  const current = Math.min(page, pageCount);
  const visible = list.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  if (loading)
    return (
      <div className="grid place-items-center py-32">
        <LoaderCircle className="animate-spin text-brand-700" size={28} />
      </div>
    );
  if (error)
    return (
      <p className="rounded-3xl bg-red-50 p-6 text-sm text-red-700">
        Couldn't load users: {error.message}
      </p>
    );

  return (
    <Card
      title="Users"
      subtitle={`${users.length} registered · ${plusCount} on Plus`}
      action={
        <Pagination page={current} pageCount={pageCount} onChange={setPage} />
      }
    >
      <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <SearchInput
          value={search}
          onChange={(v) => {
            setSearch(v);
            setPage(1);
          }}
          placeholder="Search name or email…"
        />
        <div className="flex w-fit rounded-xl bg-mist p-1 text-xs font-semibold">
          {PLAN_TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => {
                setPlan(t.key);
                setPage(1);
              }}
              className={`rounded-lg px-3 py-1.5 transition-colors ${plan === t.key ? "bg-white text-ink shadow-sm" : "text-gray-500 hover:text-ink"}`}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      <div className="mt-4 overflow-x-auto">
        <table className="w-full min-w-[820px] text-left text-sm">
          <thead className="border-b border-black/5 text-xs text-gray-500">
            <tr>
              {[
                "User",
                "Plan",
                "Subscription",
                "Joined",
                "Last active",
                "",
              ].map((h) => (
                <th key={h} className="py-3 font-medium">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-black/5">
            {visible.map((u) => {
              const status = planStatus(u);
              return (
                <tr key={u.id} className="transition-colors hover:bg-mist/60">
                  <td className="py-3">
                    <Link
                      to={`/admin/users/${u.id}`}
                      className="group flex items-center gap-3"
                    >
                      <Avatar
                        name={u.displayName || u.email || "?"}
                        photo={u.photoUrl}
                      />
                      <span className="min-w-0">
                        <span className="block font-semibold group-hover:text-brand-700 group-hover:underline">
                          {u.displayName || "No name"}
                        </span>
                        <span className="block truncate text-xs text-gray-500">
                          {u.email}
                        </span>
                      </span>
                    </Link>
                  </td>
                  <td>
                    <StatusPill status={status} />
                  </td>
                  <td className="text-gray-600">
                    {status === "Free"
                      ? "—"
                      : `${u.subscriptionTitle ?? u.subscriptionPlan ?? "Plus"}${status === "Plus" ? ` · until ${formatDate(u.subscriptionExpiresAt)}` : ""}`}
                  </td>
                  <td className="text-gray-600">{formatDate(u.createdAt)}</td>
                  <td className="text-gray-600">{timeAgo(u.lastLoginAt)}</td>
                  <td className="text-right">
                    <Link
                      to={`/admin/users/${u.id}`}
                      className="inline-grid h-8 w-8 place-items-center rounded-lg text-gray-400 hover:bg-white hover:text-ink"
                      aria-label={`View ${u.displayName}`}
                    >
                      <ChevronRight size={16} />
                    </Link>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {list.length === 0 && (
          <p className="py-10 text-center text-sm text-gray-500">
            {users.length === 0
              ? "No users yet."
              : "No users match your search."}
          </p>
        )}
      </div>
    </Card>
  );
}
