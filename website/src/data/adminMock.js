// // Placeholder data so the dashboard renders before it's wired to Firestore.
// // Replace each export with real data one widget at a time (see useCollection).

// export const stats = {
//   dailyActiveUsers: 2418,
//   dauChange: '+8%',
//   plusSubscribers: 612,
//   monthlyRevenue: 112400,
//   revenueChange: '+14.2%',
//   pendingDoctors: 7,
// }

// // 30 days of users vs scans, gently rising
// export const activity = Array.from({ length: 30 }, (_, i) => {
//   const base = 400 + i * 55 + Math.round(Math.sin(i * 1.3) * 60)
//   return { day: `Day ${i + 1}`, users: base, scans: Math.round(base * 1.12 + Math.cos(i) * 40) }
// })

// export const plans = [
//   { name: '6-Month Plan', price: 'Rs. 799', share: 58, color: '#0d6e57' },
//   { name: 'Monthly Plan', price: 'Rs. 149', share: 28, color: '#16a37f' },
//   { name: 'Yearly Plan', price: 'Rs. 1,499', share: 14, color: '#d3f0e4' },
// ]

// export const scansToday = {
//   items: [
//     { label: 'Medicine Strips', count: 184, type: 'medicine' },
//     { label: 'Meal Log Plates', count: 296, type: 'meal' },
//     { label: 'Lab Reports', count: 92, type: 'report' },
//   ],
//   limitHitUsers: 48,
// }

// export const tokenBudget = {
//   used: 6.84,
//   total: 10,
//   breakdown: [
//     { label: 'AI Report Analysis', tokens: '3.4M' },
//     { label: 'Meal Nutritional AI', tokens: '2.1M' },
//     { label: 'Conversational Assistant Q&A', tokens: '1.3M' },
//   ],
// }

// export const doctorQueue = [
//   { id: 1, name: 'Dr. Rajesh Adhikari', speciality: 'Cardiologist', clinic: 'Norvic International', license: 'NMC-4592', submitted: 'Jan 12, 2026', status: 'Pending' },
//   { id: 2, name: 'Dr. Sunita Prasai', speciality: 'Endocrinologist', clinic: 'Grande Hospital', license: 'NMC-9812', submitted: 'Jan 11, 2026', status: 'Approved' },
//   { id: 3, name: 'Dr. Binod Karki', speciality: 'General Practitioner', clinic: 'Bir Hospital', license: 'NMC-1205', submitted: 'Jan 10, 2026', status: 'Pending' },
//   { id: 4, name: 'Dr. Kriti Shrestha', speciality: 'Pediatrician', clinic: "Kanti Children's", license: 'NMC-7731', submitted: 'Jan 09, 2026', status: 'Rejected' },
// ]

// export const consultations = [
//   { id: 1, patient: 'Niranjan Thapa', doctor: 'Dr. Rajesh Adhikari', time: '10:30 AM', type: 'In-Clinic', status: 'Completed' },
//   { id: 2, patient: 'Pooja Bhandari', doctor: 'Dr. Sunita Prasai', time: '11:15 AM', type: 'Video Consultation', status: 'Ongoing' },
//   { id: 3, patient: 'Sanjay Devkota', doctor: 'Dr. Binod Karki', time: '01:00 PM', type: 'Video Consultation', status: 'Scheduled' },
//   { id: 4, patient: 'Roshani Gurung', doctor: 'Dr. Kriti Shrestha', time: '02:45 PM', type: 'In-Clinic', status: 'Scheduled' },
// ]

// Sample data for the two widgets that don't have Firebase data yet.
// Everything else on the dashboard now reads from Firestore.

// export const tokenBudget = {
//   used: 6.84,
//   total: 10,
//   breakdown: [
//     { label: 'AI Report Analysis', tokens: '3.4M' },
//     { label: 'Meal Nutritional AI', tokens: '2.1M' },
//     { label: 'Conversational Assistant Q&A', tokens: '1.3M' },
//   ],
// }

// export const consultations = [
//   { id: 1, patient: 'Niranjan Thapa', doctor: 'Dr. Rajesh Adhikari', time: '10:30 AM', type: 'In-Clinic', status: 'Completed' },
//   { id: 2, patient: 'Pooja Bhandari', doctor: 'Dr. Sunita Prasai', time: '11:15 AM', type: 'Video Consultation', status: 'Ongoing' },
//   { id: 3, patient: 'Sanjay Devkota', doctor: 'Dr. Binod Karki', time: '01:00 PM', type: 'Video Consultation', status: 'Scheduled' },
//   { id: 4, patient: 'Roshani Gurung', doctor: 'Dr. Kriti Shrestha', time: '02:45 PM', type: 'In-Clinic', status: 'Scheduled' },
// ]

// Sample data for the one widget that doesn't have Firebase data yet.
// Everything else on the dashboard reads from Firestore.

export const tokenBudget = {
  used: 6.84,
  total: 10,
  breakdown: [
    { label: "AI Report Analysis", tokens: "3.4M" },
    { label: "Meal Nutritional AI", tokens: "2.1M" },
    { label: "Conversational Assistant Q&A", tokens: "1.3M" },
  ],
};
