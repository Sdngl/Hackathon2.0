import { ChevronLeft, ChevronRight } from "lucide-react";

// < 1 / 3 >
export default function Pagination({ page, pageCount, onChange }) {
  if (pageCount <= 1) return null;

  const btn =
    "grid h-8 w-8 place-items-center rounded-lg border border-black/10 transition-colors hover:bg-mist disabled:cursor-not-allowed disabled:opacity-40";

  return (
    <div className="flex items-center gap-2 text-sm">
      <button
        className={btn}
        onClick={() => onChange(page - 1)}
        disabled={page === 1}
        aria-label="Previous page"
      >
        <ChevronLeft size={16} />
      </button>
      <span className="min-w-12 text-center font-medium tabular-nums">
        {page} <span className="text-gray-400">/ {pageCount}</span>
      </span>
      <button
        className={btn}
        onClick={() => onChange(page + 1)}
        disabled={page === pageCount}
        aria-label="Next page"
      >
        <ChevronRight size={16} />
      </button>
    </div>
  );
}
