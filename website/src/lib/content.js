// App content managed by the admin: articles, daily tips, banners and FAQs.
// Stored in the Firestore collection "content"; the mobile app shows the
// items where published is true.

export const CONTENT_COLLECTION = "content";

export const CONTENT_TYPES = [
  { key: "article", label: "Article", tint: "bg-blue-50 text-blue-600" },
  { key: "tip", label: "Daily tip", tint: "bg-brand-50 text-brand-700" },
  { key: "banner", label: "Banner", tint: "bg-violet-50 text-violet-600" },
  { key: "faq", label: "FAQ", tint: "bg-amber-50 text-amber-600" },
];

export const AUDIENCES = [
  { key: "all", label: "Everyone" },
  { key: "free", label: "Free users" },
  { key: "plus", label: "Plus users" },
];

export const typeOf = (key) =>
  CONTENT_TYPES.find((t) => t.key === key) ?? CONTENT_TYPES[0];
export const audienceLabel = (key) =>
  AUDIENCES.find((a) => a.key === key)?.label ?? "Everyone";

export const STARTER_CONTENT = [
  {
    type: "tip",
    title: "Drink water before meals",
    category: "Nutrition",
    audience: "all",
    published: true,
    imageUrl: "",
    body: "A glass of water 30 minutes before eating helps digestion and keeps you from overeating.",
  },
  {
    type: "article",
    title: "Why Vitamin D matters",
    category: "Lab reports",
    audience: "all",
    published: true,
    imageUrl: "",
    body: "Vitamin D keeps bones strong and supports your immune system. Many people in Nepal run low, especially in winter. Morning sunlight, eggs, fish and fortified milk all help. If your report shows a low value, SEVA will suggest foods and when to see a doctor.",
  },
  {
    type: "banner",
    title: "Go Plus for 6 months, save Rs. 95",
    category: "Offer",
    audience: "free",
    published: true,
    imageUrl: "",
    body: "Unlimited scans, more AI and doctor consultations for Rs. 799.",
  },
  {
    type: "faq",
    title: "How many scans do I get for free?",
    category: "Plans",
    audience: "all",
    published: true,
    imageUrl: "",
    body: "Every account gets 5 free scans a day. Plus members get unlimited scans.",
  },
];
