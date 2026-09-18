import Badge from './Badge'

export default function SectionHeading({ badge, title, subtitle }) {
  return (
    <div className="mx-auto max-w-2xl text-center">
      <Badge>{badge}</Badge>
      <h2 className="mt-4 text-3xl leading-tight font-bold tracking-tight sm:text-[2.6rem]">{title}</h2>
      {subtitle && <p className="mx-auto mt-4 max-w-xl text-gray-600">{subtitle}</p>}
    </div>
  )
}