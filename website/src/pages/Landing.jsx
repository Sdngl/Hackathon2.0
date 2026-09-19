import CTA from "../components/Cta";
import DoctorCTA from "../components/DoctorCTA";
import Features from "../components/Features";
import Footer from "../components/Footer";
import Hero from "../components/Hero";
import HowItWorks from "../components/HowItWorks";
import Navbar from "../components/Navbar";
import Pricing from "../components/Pricing";
import Reminders from "../components/Reminders";

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
        <DoctorCTA />
        <CTA />
      </main>
      <Footer />
    </>
  );
}
