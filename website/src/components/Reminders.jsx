import { Check, Moon, Pill, Sparkles, Sun, Sunrise } from 'lucide-react'
import Badge from './Badge'

const points = [
  'Evenly spaced within your awake window',
  'Meal-aware: before or after food',
  'Snooze, mark taken, and track streaks',
]

const doses = [
  { time: '6:00 AM', icon: Sunrise, color: 'text-amber-500', ring: 'border-amber-500' },
  { time: '2:00 PM', icon: Sun, color: 'text-orange-500', ring: 'border-orange-500' },
  { time: '10:00 PM', icon: Moon, color: 'text-violet-500', ring: 'border-violet-500' },
]

function ScheduleCard() {
  return (
    <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-xl shadow-black/5 sm:p-8">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="grid h-11 w-11 place-items-center rounded-xl bg-amber-100 text-amber-600">
            <Pill size={20} />
          </span>
          <div>
            <p className="font-semibold">Amoxicillin 500 mg</p>
            <p className="text-sm text-gray-500">1 capsule · 3 times a day</p>
          </div>
        </div>
        <span className="flex shrink-0 items-center gap-1 rounded-full bg-violet-100 px-3 py-1 text-xs font-semibold text-violet-600">
          <Sparkles size={11} /> Every 8 hrs
        </span>
      </div>

      {/* timeline */}
      <div className="mt-8">
        <div className="flex justify-between">
          {doses.map(({ time, icon: Icon, color }) => (
            <Icon key={time} size={20} className={color} />
          ))}
        </div>
        <div className="relative mt-3 flex items-center justify-between">
          <div className="absolute inset-x-2 h-1.5 rounded-full bg-gradient-to-r from-amber-300 via-orange-400 to-violet-500" />
          {doses.map(({ time, ring }) => (
            <span key={time} className={`relative h-6 w-6 rounded-full border-[5px] bg-white ${ring}`} />
          ))}
        </div>
        <div className="mt-3 flex justify-between text-sm font-semibold">
          {doses.map(({ time }) => <span key={time}>{time}</span>)}
        </div>
      </div>

      <div className="mt-8 flex flex-wrap gap-2 text-xs font-semibold">
        <span className="flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1.5 text-amber-600"><Sunrise size={12} />Wake 6:00 AM</span>
        <span className="flex items-center gap-1 rounded-full bg-violet-50 px-3 py-1.5 text-violet-600"><Moon size={12} />Sleep 10:00 PM</span>
        <span className="rounded-full bg-gray-100 px-3 py-1.5">16 hr window</span>
      </div>
    </div>
  )
}

export default function Reminders() {
  return (
    <section className="bg-mist py-20 lg:py-28">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-5 lg:grid-cols-2 lg:px-8">
        <div>
          <Badge>Smart reminders</Badge>
          <h2 className="mt-4 text-3xl leading-tight font-bold tracking-tight sm:text-[2.6rem]">
            “3 times a day” —<br />handled.
          </h2>
          <p className="mt-4 max-w-md text-gray-600">
            Scan the strip. We read the dosage, look at your wake and sleep time, and spread
            doses evenly so you never double up or forget.
          </p>
          <ul className="mt-6 space-y-3">
            {points.map((point) => (
              <li key={point} className="flex items-center gap-3 text-sm font-medium">
                <span className="grid h-5 w-5 place-items-center rounded-full bg-brand-600 text-white">
                  <Check size={12} strokeWidth={3} />
                </span>
                {point}
              </li>
            ))}
          </ul>
        </div>

        <ScheduleCard />
      </div>
    </section>
  )
}
