// Defaults and options for the Settings page.
//
// Two different kinds of settings live in two different places:
//   adminSettings/{adminUid}  → how the DASHBOARD behaves for this admin
//   appConfig/general         → how the MOBILE APP behaves for every user (the app reads it)

export const ADMIN_SETTINGS = "adminSettings";
export const APP_CONFIG = { collection: "appConfig", id: "general" };

// Activity-feed types you can turn on/off (keys match `kind` in lib/alerts.js)
export const ALERT_KINDS = [
  { key: "join", label: "New users", hint: "Someone creates a SEVA account" },
  {
    key: "subscribe",
    label: "New subscriptions",
    hint: "Someone buys or renews Plus",
  },
  {
    key: "expiring",
    label: "Plans expiring soon",
    hint: "A Plus plan has less than 7 days left",
  },
  {
    key: "cancel",
    label: "Cancellations",
    hint: "Someone turns off auto-renew",
  },
  { key: "appointment", label: "New bookings", hint: "A user books a doctor" },
];

export const RANGE_OPTIONS = [7, 30, 90];

export const DEFAULT_ADMIN_SETTINGS = {
  defaultRange: 30,
  alertKinds: Object.fromEntries(ALERT_KINDS.map((k) => [k.key, true])),
};

export const LANGUAGES = [
  { key: "en", label: "English" },
  { key: "ne", label: "नेपाली (Nepali)" },
];

export const DEFAULT_APP_CONFIG = {
  defaultLanguage: "en",
  supportedLanguages: ["en", "ne"],
  maintenanceMode: false,
  maintenanceMessage:
    "SEVA is being updated. Please check back in a few minutes.",
  supportEmail: "",
  supportPhone: "",
};

// Fill in anything missing from a saved document with the defaults
export function mergeAdminSettings(saved) {
  return {
    ...DEFAULT_ADMIN_SETTINGS,
    ...saved,
    alertKinds: { ...DEFAULT_ADMIN_SETTINGS.alertKinds, ...saved?.alertKinds },
  };
}

export function mergeAppConfig(saved) {
  return { ...DEFAULT_APP_CONFIG, ...saved };
}
