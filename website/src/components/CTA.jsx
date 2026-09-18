import StoreButtons from './StoreButtons'

export default function CTA() {
  return (
    <section className="bg-white px-5 pb-20 lg:px-8 lg:pb-28">
      <div className="mx-auto flex max-w-6xl flex-col gap-8 rounded-3xl bg-gradient-to-br from-brand-800 to-brand-500 px-8 py-12 text-white md:flex-row md:items-center md:justify-between lg:px-16 lg:py-16">
        <div>
          <h2 className="max-w-lg text-3xl leading-tight font-bold tracking-tight sm:text-4xl">
            Your health, looked after — quietly, every day.
          </h2>
          <p className="mt-4 text-sm text-white/80">
            Free on iOS and Android. Your data stays encrypted on your phone.
          </p>
        </div>
        <StoreButtons light />
      </div>
    </section>
  )
}
