// Turns rows into a CSV file and downloads it (opens fine in Excel / Google Sheets).

function cell(value) {
  let text = value == null ? "" : String(value);
  // stop spreadsheet apps from running a cell as a formula
  if (/^[=+\-@]/.test(text)) text = `'${text}`;
  // quote cells that contain commas, quotes or line breaks
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

// columns = [{ label: 'Email', value: (row) => row.email }, ...]
export function toCSV(rows, columns) {
  const header = columns.map((c) => cell(c.label)).join(",");
  const lines = rows.map((row) =>
    columns.map((c) => cell(c.value(row))).join(","),
  );
  return [header, ...lines].join("\r\n");
}

export function downloadCSV(filename, csv) {
  // the BOM makes Excel read Nepali text correctly
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
