// Turns a photo the user picks into a small square JPEG stored as text (a "data URL"),
// e.g. "data:image/jpeg;base64,/9j/4AAQ...". It can go straight into a Firestore field
// and into <img src>, with no storage bucket needed.
//
// Firestore documents are limited to 1 MB, and the doctors list is downloaded by the
// app, so photos are shrunk to 320×320 and kept under ~120 KB.

const SIZE = 320;
const MAX_LENGTH = 120_000; // characters of base64 text (≈ 90 KB of image)
const MAX_INPUT_MB = 10;
const ACCEPTED = ["image/jpeg", "image/png", "image/webp"];

export const ACCEPT_ATTR = ACCEPTED.join(",");

export async function photoToDataUrl(file) {
  if (!ACCEPTED.includes(file.type))
    throw new Error("Please choose a JPG, PNG or WebP photo.");
  if (file.size > MAX_INPUT_MB * 1024 * 1024)
    throw new Error(
      `That photo is over ${MAX_INPUT_MB} MB. Please choose a smaller one.`,
    );

  const url = URL.createObjectURL(file);
  try {
    const img = new Image();
    img.src = url;
    await img.decode();

    // crop the middle square, so faces stay centred
    const side = Math.min(img.naturalWidth, img.naturalHeight);
    const sx = (img.naturalWidth - side) / 2;
    const sy = (img.naturalHeight - side) / 2;

    const canvas = document.createElement("canvas");
    canvas.width = SIZE;
    canvas.height = SIZE;
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#ffffff"; // transparent PNGs get a white background instead of black
    ctx.fillRect(0, 0, SIZE, SIZE);
    ctx.drawImage(img, sx, sy, side, side, 0, 0, SIZE, SIZE);

    // lower the quality step by step until it's small enough
    for (let quality = 0.85; quality >= 0.4; quality -= 0.15) {
      const dataUrl = canvas.toDataURL("image/jpeg", quality);
      if (dataUrl.length <= MAX_LENGTH) return dataUrl;
    }
    throw new Error(
      "Could not make that photo small enough. Try a different one.",
    );
  } catch (err) {
    if (err.name === "EncodingError")
      throw new Error("That file could not be read as an image.", {
        cause: err,
      });
    throw err;
  } finally {
    URL.revokeObjectURL(url);
  }
}

export const isDataUrl = (value) =>
  typeof value === "string" && value.startsWith("data:image/");
