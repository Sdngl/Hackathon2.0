import { Sparkles } from 'lucide-react'
import Badge from './Badge'
import StoreButtons from './StoreButtons'
import PhoneMockups from './PhoneMockups'

const stats = [
  { value: '3 sec', label: 'to scan a label' },
  { value: '6 AM–10 PM', label: 'smart dose spacing' },
  { value: '100%', label: 'on-device encryption' },
]

export default function Hero() {
  return (
    <section className="overflow-hidden bg-mist">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-5 py-16 lg:grid-cols-[1.1fr_1fr] lg:px-8 lg:py-24">
        <div>
          <Badge icon={Sparkles}>Built for HealthTech &amp; Wellbeing</Badge>

          <h1 className="mt-6 text-4xl leading-[1.08] font-bold tracking-tight sm:text-5xl lg:text-[3.15rem] lg:tracking-[-0.035em]">
            <span className="block sm:inline">Scan it.</span>{' '}
            <span className="block sm:inline">Understand it.</span>
            <br className="hidden sm:block" />
            <span className="block sm:inline">Never miss a dose.</span>
          </h1>

          <p className="mt-6 max-w-lg text-base leading-relaxed text-gray-600 sm:text-lg">
            <span className="font-bold text-[#0b5a48]">Smart Everyday Vital Assistant (SEVA)</span> turns your medicine labels, meals and Medical reports into simple daily
            guidance — with smart reminders, AI health assistant, doctor appointments recommendation and step tracking in one app.
          </p>

          <div className="mt-8">
            <StoreButtons />
          </div>

          <dl className="mt-10 flex flex-wrap gap-x-10 gap-y-4">
            {stats.map((stat) => (
              <div key={stat.label}>
                <dt className="text-xl font-bold tracking-tight">{stat.value}</dt>
                <dd className="text-xs text-gray-500">{stat.label}</dd>
              </div>
            ))}
          </dl>
        </div>

        <PhoneMockups />
      </div>
    </section>
  )
}