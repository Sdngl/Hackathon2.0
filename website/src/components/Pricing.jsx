import { Check } from 'lucide-react'
import SectionHeading from './SectionHeading'

const plans = [
  {
    name: 'Free',
    price: 'Rs. 0',
    period: 'forever',
    note: 'For getting started',
    features: ['5 scans per day', 'Basic AI assistant', 'Medicine reminders & step tracking', 'Meal & report log'],
    cta: 'Get the app',
    variant: 'free',
  },
  {
    name: 'Plus Monthly',
    price: 'Rs. 149',
    period: '/ month',
    note: 'Flexible, cancel anytime',
    features: ['Unlimited scans', 'More AI tokens', 'Doctor consultation', 'Everything in Free'],
    cta: 'Choose monthly',
    variant: 'monthly',
  },
  {
    name: 'Plus Yearly',
    price: 'Rs. 1,499',
    period: '/ year',
    note: '≈ Rs. 125/month · save Rs. 289',
    features: ['Unlimited scans', 'More AI tokens', 'Doctor consultation', 'Everything in Free'],
    cta: 'Choose yearly',
    variant: 'yearly',
  },
]

const styles = {
  free: {
    card: 'bg-white border border-black/10',
    muted: 'text-gray-500', divider: 'border-black/10',
    check: 'bg-brand-100 text-brand-700',
    button: 'bg-mist text-ink hover:bg-gray-200',
  },
  monthly: {
    card: 'bg-white border border-black/10',
    muted: 'text-gray-500', divider: 'border-black/10',
    check: 'bg-brand-100 text-brand-700',
    button: 'bg-ink text-white hover:bg-brand-800',
  },
  yearly: {
    card: 'bg-gradient-to-br from-brand-800 to-brand-500 text-white shadow-xl shadow-brand-700/20',
    muted: 'text-white/75', divider: 'border-white/20',
    check: 'bg-white/20 text-white',
    button: 'bg-white text-brand-700 hover:bg-brand-50',
  },
}

export default function Pricing() {
  return (
    <section id="pricing" className="scroll-mt-16 bg-white py-20 lg:py-28">
      <div className="mx-auto max-w-6xl px-5 lg:px-8">
        <SectionHeading
          badge="Pricing"
          title="Start free. Upgrade when you need more."
          subtitle="Every account gets 5 free scans a day. Go Plus for unlimited scans, doctor consultations and more AI."
        />

        <div className="mt-14 grid gap-5 md:grid-cols-3">
          {plans.map((plan) => {
            const s = styles[plan.variant]
            return (
              <div key={plan.name} className={`flex flex-col rounded-3xl p-8 ${s.card}`}>
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">{plan.name}</h3>
                  {plan.variant === 'yearly' && (
                    <span className="rounded-full bg-amber-300 px-2.5 py-1 text-[10px] font-bold text-ink">BEST VALUE</span>
                  )}
                </div>

                <p className="mt-5 flex items-baseline gap-2">
                  <span className="text-4xl font-bold tracking-tight">{plan.price}</span>
                  <span className={`text-sm ${s.muted}`}>{plan.period}</span>
                </p>
                <p className={`mt-3 text-sm ${s.muted}`}>{plan.note}</p>

                <ul className={`mt-6 flex-1 space-y-3 border-t pt-6 ${s.divider}`}>
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-center gap-3 text-sm">
                      <span className={`grid h-5 w-5 place-items-center rounded-full ${s.check}`}>
                        <Check size={11} strokeWidth={3} />
                      </span>
                      {f}
                    </li>
                  ))}
                </ul>

                <a href="#" className={`mt-8 rounded-full py-3 text-center text-sm font-semibold transition-colors ${s.button}`}>
                  {plan.cta}
                </a>
              </div>
            )
          })}
        </div>

        <p className="mt-8 text-center text-xs text-gray-500">
          Prices in Nepali Rupees. Plus renews automatically; cancel anytime.
        </p>
      </div>
    </section>
  )
}
