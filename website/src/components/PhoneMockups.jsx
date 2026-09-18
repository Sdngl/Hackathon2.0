import {
  Activity, Bell, Check, ChevronRight, FileText, Flame, Footprints, House,
  MapPin, Pill, ScanLine, Sparkles, User, Utensils, Zap,
} from 'lucide-react'

/* ---------- small helpers ---------- */

function StatusBar({ dark = false }) {
  return (
    <div className={`flex items-center justify-between px-6 pt-3 text-[10px] font-semibold ${dark ? 'text-white' : 'text-ink'}`}>
      <span>9:41</span>
      <span className="flex items-center gap-1">
        <span className="flex items-end gap-[1.5px]">
          {[4, 6, 8, 10].map((h) => (
            <span key={h} className={`w-[2.5px] rounded-sm ${dark ? 'bg-white' : 'bg-ink'}`} style={{ height: h }} />
          ))}
        </span>
        <span className={`ml-1 h-2.5 w-5 rounded-[3px] border ${dark ? 'border-white' : 'border-ink'} p-[1.5px]`}>
          <span className={`block h-full w-3/4 rounded-[1px] ${dark ? 'bg-white' : 'bg-ink'}`} />
        </span>
      </span>
    </div>
  )
}

function ProgressRing({ percent = 68 }) {
  const r = 30
  const c = 2 * Math.PI * r
  return (
    <div className="relative h-[76px] w-[76px] shrink-0">
      <svg viewBox="0 0 76 76" className="h-full w-full -rotate-90">
        <circle cx="38" cy="38" r={r} fill="none" stroke="rgba(255,255,255,0.2)" strokeWidth="7" />
        <circle
          cx="38" cy="38" r={r} fill="none" stroke="white" strokeWidth="7" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c - (percent / 100) * c}
        />
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        <div>
          <Footprints size={11} className="mx-auto opacity-80" />
          <div className="text-sm font-bold">{percent}%</div>
        </div>
      </div>
    </div>
  )
}

/* ---------- front phone: home screen ---------- */

function HomeScreen() {
  return (
    <div className="relative h-full overflow-hidden rounded-[34px] bg-mist">
      <StatusBar />
      <div className="px-3.5 pt-3">
        {/* greeting */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="grid h-7 w-7 place-items-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">A</span>
            <div className="leading-tight">
              <p className="text-[8px] text-gray-500">Good morning</p>
              <p className="text-[11px] font-bold">Aarya Sharma</p>
            </div>
          </div>
          <span className="relative grid h-7 w-7 place-items-center rounded-full bg-white shadow-sm">
            <Bell size={12} />
            <span className="absolute top-1.5 right-1.5 h-1.5 w-1.5 rounded-full bg-red-500" />
          </span>
        </div>

        {/* steps card */}
        <div className="mt-3 flex items-center gap-3 rounded-2xl bg-gradient-to-br from-brand-700 to-brand-500 p-3 text-white">
          <ProgressRing />
          <div>
            <p className="text-[8px] opacity-80">Today's steps</p>
            <p className="text-xl leading-tight font-bold">6,842</p>
            <p className="text-[8px] opacity-80">of 10,000 goal</p>
            <div className="mt-1.5 flex gap-1">
              <span className="flex items-center gap-0.5 rounded-full bg-white/20 px-1.5 py-0.5 text-[7px]"><Flame size={7} />274 kcal</span>
              <span className="flex items-center gap-0.5 rounded-full bg-white/20 px-1.5 py-0.5 text-[7px]"><MapPin size={7} />4.9 km</span>
            </div>
          </div>
        </div>

        {/* next dose */}
        <div className="mt-2.5 rounded-2xl bg-white p-2.5 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="grid h-7 w-7 place-items-center rounded-lg bg-amber-100 text-amber-600"><Pill size={13} /></span>
              <div className="leading-tight">
                <p className="text-[7px] font-bold text-amber-600">NEXT DOSE · 2:00 PM</p>
                <p className="text-[10px] font-bold whitespace-nowrap">Paracetamol 500 mg</p>
                <p className="text-[7px] text-gray-500">1 tablet · after lunch</p>
              </div>
            </div>
            <span className="flex items-center gap-0.5 rounded-full bg-ink px-2 py-1 text-[7px] font-semibold text-white">
              <Check size={8} /> Taken
            </span>
          </div>
          <div className="mt-2 grid grid-cols-3 gap-1.5 text-center">
            <div className="rounded-md bg-brand-50 py-1"><p className="text-[8px] font-semibold">6:00 AM</p><p className="text-[6px] text-brand-600">Taken</p></div>
            <div className="rounded-md bg-amber-50 py-1"><p className="text-[8px] font-semibold">2:00 PM</p><p className="text-[6px] text-amber-600">Next</p></div>
            <div className="rounded-md bg-gray-100 py-1"><p className="text-[8px] font-semibold">10:00 PM</p><p className="text-[6px] text-gray-500">Later</p></div>
          </div>
        </div>

        {/* meals + report */}
        <div className="mt-2.5 grid grid-cols-2 gap-2">
          <div className="rounded-2xl bg-white p-2.5 shadow-sm">
            <span className="grid h-5 w-5 place-items-center rounded-md bg-red-50 text-red-400"><Utensils size={10} /></span>
            <p className="mt-1.5 text-[7px] text-gray-500">Meals today</p>
            <p className="text-[12px] font-bold">1,240 <span className="text-[7px] font-normal text-gray-400">/1,800 kcal</span></p>
            <div className="mt-1 h-1 rounded-full bg-gray-100"><div className="h-full w-2/3 rounded-full bg-red-400" /></div>
            <p className="mt-1 text-[6px] text-gray-500">3 of 4 meals logged</p>
          </div>
          <div className="rounded-2xl bg-white p-2.5 shadow-sm">
            <span className="grid h-5 w-5 place-items-center rounded-md bg-blue-50 text-blue-500"><FileText size={10} /></span>
            <p className="mt-1.5 text-[7px] text-gray-500">Latest report</p>
            <p className="text-[10px] font-bold">Vitamin D low</p>
            <span className="mt-1 inline-flex items-center gap-0.5 rounded-full bg-violet-100 px-1.5 py-0.5 text-[6px] font-semibold text-violet-600">
              <Sparkles size={6} /> AI tip ready
            </span>
            <p className="mt-1 text-[6px] text-gray-500">Uploaded 2 days ago</p>
          </div>
        </div>

        <p className="mt-1.5 text-right text-[7px] font-semibold text-brand-600">See all</p>

        {/* yoga */}
        <div className="mt-1 flex items-center gap-2 rounded-2xl bg-white p-2 shadow-sm">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-violet-50 text-violet-500"><Activity size={13} /></span>
          <div className="flex-1 leading-tight">
            <span className="rounded bg-gray-100 px-1 text-[6px] text-gray-500">Default plan</span>
            <p className="text-[9px] font-bold">Morning Yoga Flow</p>
            <p className="text-[6px] text-gray-500">15 min · Beginner · 6 poses</p>
          </div>
          <ChevronRight size={11} className="text-gray-400" />
        </div>
      </div>

      {/* bottom nav */}
      <div className="absolute inset-x-3 bottom-3 flex items-center gap-2">
        <span className="grid h-10 w-10 place-items-center rounded-full bg-brand-700 text-white shadow-lg"><ScanLine size={15} /></span>
        <div className="flex flex-1 items-center justify-around rounded-full bg-white py-1.5 shadow-md">
          <span className="flex flex-col items-center rounded-full bg-brand-50 px-3 py-0.5 text-[6px] font-semibold text-brand-700"><House size={10} />Home</span>
          <span className="flex flex-col items-center text-[6px] text-gray-500"><Sparkles size={10} />AI</span>
          <span className="flex flex-col items-center text-[6px] text-gray-500"><User size={10} />Profile</span>
        </div>
      </div>
    </div>
  )
}

/* ---------- back phone: scanner screen ---------- */

function ScannerScreen() {
  return (
    <div className="relative h-full overflow-hidden rounded-[34px] bg-[radial-gradient(circle_at_50%_40%,#3b4a45,#111a17_70%)]">
      <StatusBar dark />
      <div className="flex items-center justify-between px-4 pt-3">
        <span className="flex items-center gap-1 rounded-full bg-white/15 px-2 py-1 text-[7px] text-white">
          <Sparkles size={7} /> Hold steady · reading label
        </span>
        <span className="grid h-6 w-6 place-items-center rounded-full bg-white/15 text-white"><Zap size={10} /></span>
      </div>

      {/* scan frame */}
      <div className="relative mx-auto mt-10 h-36 w-44">
        {['top-0 left-0 border-t-2 border-l-2 rounded-tl-xl', 'top-0 right-0 border-t-2 border-r-2 rounded-tr-xl',
          'bottom-0 left-0 border-b-2 border-l-2 rounded-bl-xl', 'bottom-0 right-0 border-b-2 border-r-2 rounded-br-xl',
        ].map((pos) => <span key={pos} className={`absolute h-6 w-6 border-white ${pos}`} />)}

        <div className="absolute inset-x-3 top-6 -rotate-6 rounded-md bg-gray-50 p-2 shadow-xl">
          <div className="h-1 w-full rounded bg-red-500" />
          <p className="mt-1 text-[11px] font-extrabold tracking-wide">AMOXICILLIN</p>
          <p className="text-[6px] text-gray-600">Capsules IP 500 mg</p>
          <p className="text-[5px] text-gray-400">10 × 10 capsules · Rx only</p>
        </div>
        <div className="absolute inset-x-0 top-[62%] h-0.5 bg-brand-500 shadow-[0_0_10px_2px_rgba(22,163,127,0.7)]" />
      </div>

      <div className="mx-auto mt-8 flex w-fit gap-1 rounded-full bg-white/10 p-1 text-[7px]">
        <span className="flex items-center gap-1 rounded-full bg-white px-2 py-1 font-semibold"><Pill size={8} />Medicine</span>
        <span className="flex items-center gap-1 px-2 py-1 text-white"><FileText size={8} />Report</span>
      </div>

      <div className="mx-3 mt-3 rounded-2xl bg-white p-2.5">
        <span className="rounded-full bg-brand-100 px-1.5 py-0.5 text-[6px] font-semibold text-brand-700">Detected · 96% match</span>
        <p className="mt-1 text-[10px] font-bold">Amoxicillin 500 mg</p>
        <p className="text-[7px] text-gray-500">3× a day · 5 days</p>
      </div>
    </div>
  )
}

function Phone({ children, className = '' }) {
  return (
    <div className={`absolute h-[545px] w-[262px] rounded-[42px] border-[7px] border-ink bg-ink shadow-2xl shadow-black/25 ${className}`}>
      <span className="absolute top-2 left-1/2 z-10 h-5 w-20 -translate-x-1/2 rounded-full bg-ink" />
      {children}
    </div>
  )
}

/* ---------- composition ---------- */

export default function PhoneMockups() {
  return (
    <div className="relative mx-auto h-[450px] w-full max-w-[560px] sm:h-[590px]" aria-hidden="true">
      <div className="absolute top-0 left-1/2 h-[590px] w-[560px] origin-top -translate-x-1/2 scale-[0.76] sm:scale-100">
        <Phone className="top-12 right-4 rotate-[7deg]">
          <ScannerScreen />
        </Phone>
        <Phone className="top-0 left-[90px] -rotate-[5deg]">
          <HomeScreen />
        </Phone>

        {/* floating AI toast */}
        <div className="absolute top-[315px] left-0 flex items-center gap-2.5 rounded-xl bg-ink py-2.5 pr-4 pl-2.5 text-xs text-white shadow-xl">
          <span className="grid h-7 w-7 place-items-center rounded-lg bg-violet-500"><Sparkles size={13} /></span>
          Vitamin D is low — here's what to eat
        </div>

        {/* floating reminder */}
        <div className="absolute top-[380px] right-0 flex items-center gap-3 rounded-2xl bg-white px-3.5 py-3 shadow-xl">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-amber-100 text-amber-600"><Pill size={16} /></span>
          <div className="leading-tight">
            <p className="text-sm font-semibold">Time for Amoxicillin</p>
            <p className="text-xs text-gray-500">Dose 2 of 3 · 2:00 PM</p>
          </div>
        </div>
      </div>
    </div>
  )
}
