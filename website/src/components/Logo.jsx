import logo from '../assets/logo.png'

export default function Logo({ size = 'md' }) {
  const img = size === 'sm' ? 'h-16 w-16' : 'h-22 w-22'

  return (
    <a href="#" className="flex items-center gap-2">
      <img src={logo} alt="SEVA logo" className={`${img} object-contain`} />
    </a>
  )
}