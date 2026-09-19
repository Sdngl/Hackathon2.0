import { useState } from 'react'
import { Outlet } from 'react-router'
import DoctorSidebar from './DoctorSidebar'
import DoctorTopbar from './DoctorTopbar'
import { DoctorProvider } from '../../context/DoctorContext'

export default function DoctorLayout() {
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <DoctorProvider>
      <div className="min-h-screen bg-[#f4f6f5]">
        <DoctorSidebar open={menuOpen} onClose={() => setMenuOpen(false)} />
        <div className="lg:pl-64">
          <DoctorTopbar onMenu={() => setMenuOpen(true)} />
          <main className="p-5 lg:p-8">
            <Outlet />
          </main>
        </div>
      </div>
    </DoctorProvider>
  )
}