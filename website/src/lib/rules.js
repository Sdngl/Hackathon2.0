// Suggestion rules: "IF a report shows Vitamin D < 20 → suggest vitamin-D foods".
// Stored in the Firestore collection "suggestionRules". The mobile app reads the
// enabled rules and shows the message when a user's scan matches.

export const RULES_COLLECTION = "suggestionRules";

export const TRIGGERS = [
  {
    key: "report",
    label: "Lab report",
    hint: "e.g. Vitamin D, Fasting glucose, HbA1c",
  },
  { key: "meal", label: "Meal scan", hint: "e.g. Calories, Sugar, Sodium" },
  { key: "medicine", label: "Medicine scan", hint: "e.g. Category, Name" },
];

export const OPERATORS = [
  { key: "<", label: "is below" },
  { key: ">", label: "is above" },
  { key: "=", label: "equals" },
];

export const ACTIONS = [
  { key: "doctor", label: "Suggest a doctor" },
  { key: "food", label: "Suggest food" },
  { key: "tip", label: "Show a health tip" },
];

export const PRIORITIES = ["high", "medium", "low"];

export const labelOf = (list, key) =>
  list.find((x) => x.key === key)?.label ?? key;

// "Lab report · Vitamin D is below 20 ng/mL"
export function describeCondition(rule) {
  return `${labelOf(TRIGGERS, rule.trigger)} · ${rule.metric} ${labelOf(OPERATORS, rule.operator)} ${rule.value}${rule.unit ? ` ${rule.unit}` : ""}`;
}

// Doctors whose specialization matches a "Suggest a doctor" rule
export function matchingDoctors(rule, doctors) {
  if (rule.action !== "doctor" || !rule.specialization) return [];
  const target = rule.specialization.trim().toLowerCase();
  return doctors.filter((d) => {
    const specs = Array.isArray(d.specialization)
      ? d.specialization
      : [d.specialization];
    return (
      d.isActive && specs.some((s) => String(s ?? "").toLowerCase() === target)
    );
  });
}

// Example rules for the "Add starter rules" button
export const STARTER_RULES = [
  {
    name: "Low Vitamin D",
    trigger: "report",
    metric: "Vitamin D",
    operator: "<",
    value: 20,
    unit: "ng/mL",
    action: "food",
    specialization: "",
    priority: "medium",
    enabled: true,
    message:
      "Your Vitamin D is low. Add eggs, fish and fortified milk, and get 15 minutes of morning sun.",
  },
  {
    name: "High fasting sugar",
    trigger: "report",
    metric: "Fasting glucose",
    operator: ">",
    value: 126,
    unit: "mg/dL",
    action: "doctor",
    specialization: "Endocrinologist",
    priority: "high",
    enabled: true,
    message:
      "Your fasting sugar is above the normal range. Consider booking an endocrinologist.",
  },
  {
    name: "High cholesterol",
    trigger: "report",
    metric: "LDL cholesterol",
    operator: ">",
    value: 160,
    unit: "mg/dL",
    action: "doctor",
    specialization: "Cardiologist",
    priority: "high",
    enabled: true,
    message:
      "Your LDL cholesterol is high. A cardiologist can help you plan next steps.",
  },
  {
    name: "Heavy meal",
    trigger: "meal",
    metric: "Calories",
    operator: ">",
    value: 900,
    unit: "kcal",
    action: "tip",
    specialization: "",
    priority: "low",
    enabled: true,
    message:
      "That was a heavy meal. Keep dinner light and try a 20-minute walk.",
  },
  {
    name: "Antibiotic course",
    trigger: "medicine",
    metric: "Category",
    operator: "=",
    value: "Antibiotic",
    unit: "",
    action: "tip",
    specialization: "",
    priority: "high",
    enabled: true,
    message:
      "Finish the full antibiotic course, even if you start feeling better.",
  },
];
