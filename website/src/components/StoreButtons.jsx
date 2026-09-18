import { Apple, Play } from 'lucide-react'

function StoreButton({ icon: Icon, small, label, light }) {
  const colors = light
    ? 'bg-white text-ink hover:bg-brand-50'
    : 'bg-ink text-white hover:bg-brand-800'

  return (
    <a
      href="#"
      className={`flex items-center gap-2.5 rounded-xl px-4 py-2.5 transition-colors ${colors}`}
    >
      <Icon size={20} />
      <span className="leading-tight">
        <span className="block text-[10px] opacity-75">{small}</span>
        <span className="block text-sm font-semibold">{label}</span>
      </span>
    </a>
  )
}

export default function StoreButtons({ light = false }) {
  return (
    <div className="flex flex-wrap gap-3">
      <StoreButton icon={Apple} small="Download on the" label="App Store" light={light} />
      <StoreButton icon={Play} small="Get it on" label="Google Play" light={light} />
    </div>
  )
}
