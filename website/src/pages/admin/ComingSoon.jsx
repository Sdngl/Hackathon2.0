import { Link } from 'react-router'
import { Construction } from 'lucide-react'

export default function ComingSoon({ title, standalone = false }) {
  const content = (
    <div className="grid place-items-center rounded-3xl border border-black/5 bg-white px-6 py-24 text-center">
      <span className="grid h-14 w-14 place-items-center rounded-2xl bg-amber-100 text-amber-600">
        <Construction size={26} />
      </span>
      <h1 className="mt-5 text-2xl font-bold tracking-tight">{title}</h1>
      <p className="mt-2 max-w-sm text-sm text-gray-500">This page is being built. Check back soon.</p>
      {standalone && (
        <Link to="/portal" className="mt-6 rounded-full bg-ink px-5 py-2.5 text-sm font-semibold text-white">
          Back to portals
        </Link>
      )}
    </div>
  )

  return standalone ? <div className="grid min-h-screen place-items-center bg-mist p-5">{content}</div> : content
}
