import { isActivePlus, toDate } from './dashboardStats'

// 'Plus' (paid, not expired) · 'Expired' (paid before, now lapsed) · 'Free'
export function planStatus(user) {
  if (isActivePlus(user)) return 'Plus'
  if (user.isPaid) return 'Expired'
  return 'Free'
}

// Search by name or email, filter by plan, newest users first
export function filterUsers(users, { search = '', plan = 'all' }) {
  const q = search.trim().toLowerCase()
  return users
    .filter((u) => plan === 'all' || planStatus(u) === plan)
    .filter((u) => !q || `${u.displayName ?? ''} ${u.email ?? ''}`.toLowerCase().includes(q))
    .sort((a, b) => (toDate(b.createdAt)?.getTime() ?? 0) - (toDate(a.createdAt)?.getTime() ?? 0))
}