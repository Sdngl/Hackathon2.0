import { useState } from 'react'
import { Menu, X } from 'lucide-react'
import { Link } from 'react-router'
import Logo from './Logo'

const links = [
  { label: 'Features', href: '#features' },
  { label: 'How it works', href: '#how-it-works' },
  { label: 'AI Assistant', href: '#features' },
  { label: 'Pricing', href: '#pricing' },
  { label: 'Privacy', href: '#privacy' },
  { label: 'For doctors', href: '#for-doctors' },
]

export default function Navbar() {
  const [open, setOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 border-b border-black/5 bg-mist/85 backdrop-blur">
      <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5 lg:px-8">
        <Logo />

        <ul className="hidden items-center gap-8 md:flex">
          {links.map((link) => (
            <li key={link.label}>
              <a href={link.href} className="text-sm text-gray-600 transition-colors hover:text-ink">
                {link.label}
              </a>
            </li>
          ))}
        </ul>

        <div className="hidden items-center gap-5 md:flex">
          <Link to="/portal" className="text-sm font-semibold">Sign in</Link>
          <a
            href="#"
            className="rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-brand-800"
          >
            Get the app
          </a>
        </div>

        <button
          className="rounded-lg p-2 md:hidden"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
          aria-expanded={open}
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </nav>

      {open && (
        <div className="border-t border-black/5 bg-mist px-5 pb-5 md:hidden">
          <ul className="flex flex-col py-2">
            {links.map((link) => (
              <li key={link.label}>
                <a
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="block py-2.5 text-gray-700"
                >
                  {link.label}
                </a>
              </li>
            ))}
          </ul>
          <Link to="/portal" className="mb-2 block rounded-full border border-black/10 py-3 text-center text-sm font-semibold">
            Sign in
          </Link>
          <a href="#" className="block rounded-full bg-ink py-3 text-center text-sm font-semibold text-white">
            Get the app
          </a>
        </div>
      )}
    </header>
  )
}
