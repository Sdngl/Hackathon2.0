import Navbar from './components/Navbar'
import Hero from './components/Hero'
import Features from './components/Features'
import Reminders from './components/Reminders'
import HowItWorks from './components/HowItWorks'
import Pricing from './components/Pricing'
import CTA from './components/Cta'
import Footer from './components/Footer'

export default function App() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <Features />
        <Reminders />
        <HowItWorks />
        <Pricing />
        <CTA />
      </main>
      <Footer />
    </>
  )
}