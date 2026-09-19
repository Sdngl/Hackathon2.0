// There is no "clinics" collection yet, so clinics are built from the doctors
// who work there. Doctors with the same clinic name are grouped together.

const clinicNameOf = (d) => (d.clinicName || d.hospital || d.Clinic || d.clinic || '').trim()
const asList = (v) => (Array.isArray(v) ? v : v ? [v] : [])
const firstFilled = (docs, key) => docs.map((d) => d[key]).find(Boolean)

export function groupClinics(doctors) {
  const groups = {}

  for (const d of doctors) {
    const name = clinicNameOf(d)
    if (!name) continue
    const key = name.toLowerCase() // "City Care" and "city care" are the same clinic
    groups[key] ??= { id: key, name, doctors: [] }
    groups[key].doctors.push(d)
  }

  return Object.values(groups)
    .map((c) => ({
      ...c,
      address: firstFilled(c.doctors, 'clinicAddress'),
      hours: firstFilled(c.doctors, 'clinicHours'),
      phone: firstFilled(c.doctors, 'phone'),
      email: firstFilled(c.doctors, 'email'),
      specializations: [...new Set(c.doctors.flatMap((d) => asList(d.specialization)))],
      availableCount: c.doctors.filter((d) => d.available && d.isActive).length,
      activeCount: c.doctors.filter((d) => d.isActive).length,
    }))
    .sort((a, b) => a.name.localeCompare(b.name))
}

export const doctorsWithoutClinic = (doctors) => doctors.filter((d) => !clinicNameOf(d))