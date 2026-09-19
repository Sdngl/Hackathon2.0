import { Bell, Calendar, Menu, Search } from 'lucide-react'

export default function Topbar({ onMenu }) {
  return (
    <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-black/5 bg-white/90 px-5 py-4 backdrop-blur lg:px-8">
      <button onClick={onMenu} className="rounded-lg p-2 lg:hidden" aria-label="Open menu">
        <Menu size={20} />
      </button>

      <div className="relative w-full max-w-sm">
        <Search size={16} className="absolute top-1/2 left-3.5 -translate-y-1/2 text-gray-400" />
        <input
          type="search"
          placeholder="Search patients, doctors, or reports…"
          className="w-full rounded-xl border border-black/5 bg-mist py-2.5 pr-4 pl-10 text-sm outline-none focus:border-brand-500 focus:bg-white"
        />
      </div>

      <div className="ml-auto flex items-center gap-3">
        <button className="hidden items-center gap-2 rounded-xl border border-black/10 px-4 py-2.5 text-sm font-semibold sm:flex">
          <Calendar size={16} /> Last 30 days
        </button>
        <button className="relative rounded-xl border border-black/10 p-2.5" aria-label="Notifications">
          <Bell size={18} />
          <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-red-500" />
        </button>
      </div>
    </header>
  )
}
