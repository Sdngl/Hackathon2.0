// Small green pill shown above section headings
export default function Badge({ children, icon: Icon }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
      {Icon && <Icon size={12} />}
      {children}
    </span>
  )
}
