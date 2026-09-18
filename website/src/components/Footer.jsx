import Logo from './Logo'

const links = ['Privacy', 'Terms', 'Contact', 'Not a substitute for medical advice']

export default function Footer() {
  return (
    <footer id="privacy" className="border-t border-black/5 bg-white">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-5 py-8 md:flex-row md:items-center md:justify-between lg:px-8">
        <div className="flex items-center gap-3">
          <Logo size="sm" />
          <span className="text-xs text-gray-500">HealthTech &amp; Wellbeing</span>
        </div>
        <ul className="flex flex-wrap gap-x-7 gap-y-2 text-xs text-gray-500">
          {links.map((l) => (
            <li key={l}><a href="#" className="hover:text-ink">{l}</a></li>
          ))}
        </ul>
      </div>
    </footer>
  )
}
