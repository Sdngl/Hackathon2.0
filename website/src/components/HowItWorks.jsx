import { Footprints, ScanLine, Sparkles } from 'lucide-react'
import SectionHeading from './SectionHeading'

const steps = [
  { icon: ScanLine, title: 'Scan', text: 'Medicine strip, meal or medical report — one camera for everything.' },
  { icon: Sparkles, title: 'Understand', text: 'AI turns it into reminders, calorie logs and plain-language insights.' },
  { icon: Footprints, title: 'Stay on track', text: 'Daily steps, doses and a movement plan that adapts to you.' },
]

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="scroll-mt-16 bg-white py-20 lg:py-28">
      <div className="mx-auto max-w-6xl px-5 lg:px-8">
        <SectionHeading badge="How it works" title="Three steps to a calmer routine" />

        <ol className="mt-14 grid gap-5 md:grid-cols-3">
          {steps.map(({ icon: Icon, title, text }, i) => (
            <li key={title} className="rounded-2xl border border-black/5 bg-mist p-7">
              <div className="flex items-start justify-between">
                <span className="text-4xl font-bold text-brand-200">0{i + 1}</span>
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-white text-brand-700 shadow-sm">
                  <Icon size={18} />
                </span>
              </div>
              <h3 className="mt-4 text-xl font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-gray-600">{text}</p>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
