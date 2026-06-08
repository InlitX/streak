// Generates the two alternate launcher-icon foregrounds by recolouring the
// same 5x5 heatmap grid as the default icon (see generate_icon_png.js).
//   - Green:    every violet cell mapped to the matching green shade.
//   - Tricolor: three horizontal colour bands top->bottom (red/green/blue),
//               each preserving the cell's original intensity.
// Writes transparent foreground PNGs into the Android mipmap density folders.
// Run: node assets/generate_icon_variants.js
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

function hex(h) {
  return [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
}

// Original violet grid (matches icon.svg / generate_icon_png.js).
const grid = [
  ['#5B21B6', '#7C3AED', '#3B0764', '#6D28D9', '#A78BFA'],
  ['#C4B5FD', '#6D28D9', '#7C3AED', '#5B21B6', '#241B33'],
  ['#3B0764', '#5B21B6', '#A78BFA', '#7C3AED', '#6D28D9'],
  ['#7C3AED', '#C4B5FD', '#5B21B6', '#6D28D9', '#241B33'],
  ['#6D28D9', '#3B0764', '#7C3AED', '#A78BFA', '#5B21B6'],
];

// Map each violet shade (dark->light) onto an equivalent ramp in another hue.
const GREEN = {
  '#241B33': '#0A2E16', '#3B0764': '#0B3D1A', '#5B21B6': '#15803D',
  '#6D28D9': '#16A34A', '#7C3AED': '#22C55E', '#A78BFA': '#4ADE80',
  '#C4B5FD': '#86EFAC',
};
const RED = {
  '#241B33': '#3B0A14', '#3B0764': '#7F1D1D', '#5B21B6': '#B91C1C',
  '#6D28D9': '#DC2626', '#7C3AED': '#EF4444', '#A78BFA': '#F87171',
  '#C4B5FD': '#FCA5A5',
};
const BLUE = {
  '#241B33': '#0A1E3B', '#3B0764': '#1E3A8A', '#5B21B6': '#1D4ED8',
  '#6D28D9': '#2563EB', '#7C3AED': '#3B82F6', '#A78BFA': '#60A5FA',
  '#C4B5FD': '#93C5FD',
};

function greenColor(row, col) {
  return GREEN[grid[row][col]];
}
function tricolorColor(row, col) {
  const band = Math.floor((row * 3) / 5); // rows 0-1 red, 2 green, 3-4 blue
  const ramp = [RED, GREEN, BLUE][band];
  return ramp[grid[row][col]];
}

// --- Tiny rasteriser (rounded-rect grid, transparent bg) ---
function sdRoundRect(px, py, x, y, w, h, r) {
  const cx = x + w / 2, cy = y + h / 2;
  const qx = Math.abs(px - cx) - (w / 2 - r);
  const qy = Math.abs(py - cy) - (h / 2 - r);
  const ax = Math.max(qx, 0), ay = Math.max(qy, 0);
  return Math.min(Math.max(qx, qy), 0) + Math.sqrt(ax * ax + ay * ay) - r;
}

function renderForeground(size, colorFor) {
  const buf = new Uint8ClampedArray(size * size * 4);
  const scale = size / 1024;
  // Foreground layout from generate_icon_png.js (cell 110, gap 18, start 201, r 22).
  const cell = 110 * scale, gap = 18 * scale, start = 201 * scale, radius = 22 * scale;

  function paint(x, y, w, h, r, color) {
    const [cr, cg, cb] = hex(color);
    const x0 = Math.max(0, Math.floor(x - 1)), x1 = Math.min(size, Math.ceil(x + w + 1));
    const y0 = Math.max(0, Math.floor(y - 1)), y1 = Math.min(size, Math.ceil(y + h + 1));
    for (let py = y0; py < y1; py++) {
      for (let px = x0; px < x1; px++) {
        const sd = sdRoundRect(px + 0.5, py + 0.5, x, y, w, h, r);
        const cov = Math.min(Math.max(0.5 - sd, 0), 1);
        if (cov <= 0) continue;
        const i = (py * size + px) * 4;
        const a = buf[i + 3] / 255;
        const na = cov + a * (1 - cov);
        if (na <= 0) continue;
        buf[i] = (cr * cov + buf[i] * a * (1 - cov)) / na;
        buf[i + 1] = (cg * cov + buf[i + 1] * a * (1 - cov)) / na;
        buf[i + 2] = (cb * cov + buf[i + 2] * a * (1 - cov)) / na;
        buf[i + 3] = na * 255;
      }
    }
  }

  for (let row = 0; row < 5; row++) {
    for (let col = 0; col < 5; col++) {
      paint(start + col * (cell + gap), start + row * (cell + gap), cell, cell, radius, colorFor(row, col));
    }
  }
  return buf;
}

// --- PNG encoder ---
const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(b) {
  let c = 0xffffffff;
  for (let i = 0; i < b.length; i++) c = crcTable[(c ^ b[i]) & 0xff] ^ (c >>> 8);
  return c ^ 0xffffffff;
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body) >>> 0, 0);
  return Buffer.concat([len, body, crc]);
}
function encodePng(buf, size) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; ihdr[9] = 6;
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0;
    Buffer.from(buf.buffer, y * size * 4, size * 4).copy(raw, y * (size * 4 + 1) + 1);
  }
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// Adaptive foreground sizes per density (108dp * density).
const densities = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
const resDir = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');

for (const [dpi, size] of Object.entries(densities)) {
  const dir = path.join(resDir, `mipmap-${dpi}`);
  fs.writeFileSync(path.join(dir, 'ic_launcher_fg_green.png'), encodePng(renderForeground(size, greenColor), size));
  fs.writeFileSync(path.join(dir, 'ic_launcher_fg_tri.png'), encodePng(renderForeground(size, tricolorColor), size));
  console.log(`Wrote ic_launcher_fg_green/tri.png @ ${dpi} (${size}px)`);
}
console.log('Done.');
