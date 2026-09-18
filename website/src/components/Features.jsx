import { Activity, FileText, Pill, ScanLine, Sparkles, Utensils } from 'lucide-react'
import SectionHeading from './SectionHeading'

const features = [
  {
    icon: ScanLine, tint: 'bg-brand-100 text-brand-700',
    title: 'Smart Scanner',
    text: 'Recognises medicine labels, meals and medical reports in seconds.',
  },
  {
    icon: Pill, tint: 'bg-amber-100 text-amber-600',
    title: 'Medicine reminders',
    text: 'Reads the dosage and spaces doses across your waking hours automatically.',
  },
  {
    icon: Utensils, tint: 'bg-red-100 text-red-500',
    title: 'Meal scan & log',
    text: 'Snap your plate — even dal bhat — to log calories and macros.',
  },
  {
    icon: FileText, tint: 'bg-blue-100 text-blue-600',
    title: 'Report insights',
    text: 'Flags values out of range and explains them in plain language.',
  },
  {
    icon: Sparkles, tint: 'bg-violet-100 text-violet-600',
    title: 'AI health assistant',
    text: 'Ask anything. Answers use your own reports, meds and meals as context.',
  },
  {
    icon: Activity, tint: 'bg-sky-100 text-sky-600',
    title: 'Yoga & exercise',
    text: 'Starts with a gentle default plan, then adapts to your steps and health.',
  },
]

export default function Features() {
  return (
    <section id="features" className="scroll-mt-16 bg-white py-20 lg:py-28">
      <div className="mx-auto max-w-6xl px-5 lg:px-8">
        <SectionHeading
          badge="Everything in one place"
          title="One scanner. Your whole health routine."
          subtitle="Point your camera at a medicine, a plate of food or a medical report — SEVA does the rest."
        />

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map(({ icon: Icon, tint, title, text }) => (
            <article key={title} className="rounded-2xl border border-black/5 bg-mist p-7">
              <span className={`grid h-11 w-11 place-items-center rounded-xl ${tint}`}>
                <Icon size={20} />
              </span>
              <h3 className="mt-5 text-lg font-semibold">{title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-gray-600">{text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
