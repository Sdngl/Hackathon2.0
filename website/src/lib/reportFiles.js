// Works out how to display a report document from users/{userId}/reports/{reportId}.
// The app may store the file as a link, as "data:...;base64,..." text, or as plain
// base64 text, so this checks the common field names and recognises the file type.

// Fields that may hold the file itself, checked in this order
const FILE_FIELDS = [
  "fileUrl",
  "downloadUrl",
  "url",
  "pdfUrl",
  "imageUrl",
  "documentUrl",
  "scanUrl",
  "fileBase64",
  "base64",
  "fileData",
  "data",
  "image",
  "imageBase64",
  "pdf",
  "pdfBase64",
  "file",
  "document",
];

// Fields shown as the report's title, in this order
const TITLE_FIELDS = [
  "title",
  "name",
  "fileName",
  "reportName",
  "reportType",
  "type",
];

// Recognise raw base64 by its first characters
const SIGNATURES = [
  { start: "JVBER", mime: "application/pdf" },
  { start: "/9j/", mime: "image/jpeg" },
  { start: "iVBOR", mime: "image/png" },
  { start: "UklGR", mime: "image/webp" },
];

const isLong = (v) => typeof v === "string" && v.length > 300;

function detect(value, mimeHint) {
  if (typeof value !== "string" || !value) return null;

  if (value.startsWith("data:")) {
    const mime = value.slice(5, value.indexOf(";")) || mimeHint;
    return { mime, base64: value.slice(value.indexOf(",") + 1) };
  }
  if (/^https?:\/\//.test(value)) {
    const lower = value.toLowerCase().split("?")[0];
    const mime =
      mimeHint ??
      (lower.endsWith(".pdf")
        ? "application/pdf"
        : /\.(jpe?g|png|webp|gif)$/.test(lower)
          ? "image/*"
          : null);
    return { mime, url: value };
  }
  if (isLong(value)) {
    const sig = SIGNATURES.find((s) => value.startsWith(s.start));
    if (sig || mimeHint) return { mime: mimeHint ?? sig.mime, base64: value };
  }
  return null;
}

// → { mime, url } or { mime, base64 } or null
export function findReportFile(report) {
  const mimeHint =
    report.mimeType ?? report.contentType ?? report.fileType ?? null;
  for (const key of FILE_FIELDS) {
    const found = detect(
      report[key],
      typeof mimeHint === "string" && mimeHint.includes("/") ? mimeHint : null,
    );
    if (found) return { ...found, field: key };
  }
  return null;
}

export function reportTitle(report) {
  for (const key of TITLE_FIELDS) {
    if (typeof report[key] === "string" && report[key] && !isLong(report[key]))
      return report[key];
  }
  return "Medical report";
}

// Every other short, readable field (summary, findings, lab name…) for the details list
export function reportDetails(report, fileField) {
  return Object.entries(report)
    .filter(
      ([key]) =>
        key !== "id" && key !== fileField && !TITLE_FIELDS.includes(key),
    )
    .filter(
      ([, value]) => value !== null && value !== undefined && value !== "",
    )
    .filter(
      ([, value]) =>
        !(
          typeof value === "string" &&
          isLong(value) &&
          !/\s/.test(value.slice(0, 200))
        ),
    )
    .map(([key, value]) => ({ key, value }));
}

// base64 text → a temporary blob: link the browser can show in an <iframe> or <img>
export function base64ToObjectUrl(base64, mime) {
  const bytes = Uint8Array.from(atob(base64.replace(/\s/g, "")), (c) =>
    c.charCodeAt(0),
  );
  return URL.createObjectURL(
    new Blob([bytes], { type: mime ?? "application/octet-stream" }),
  );
}

// "labName" → "Lab name"
export const prettyKey = (key) =>
  key
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/[_-]/g, " ")
    .replace(/^\w/, (c) => c.toUpperCase());
