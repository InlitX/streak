// Zero-dependency rasterizer that renders the Streak app icon to a 1024px PNG.
// Mirrors assets/icon.svg: a violet GitHub-style heatmap grid on a dark tile.
// Run: node assets/generate_icon_png.js
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

const SIZE = 1024;
let buf = new Uint8ClampedArray(SIZE * SIZE * 4); // RGBA, transparent

function hex(h) {
  return [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
}

// Signed distance to a rounded rectangle (negative inside).
function sdRoundRect(px, py, x, y, w, h, r) {
  const cx = x + w / 2, cy = y + h / 2;
  const qx = Math.abs(px - cx) - (w / 2 - r);
  const qy = Math.abs(py - cy) - (h / 2 - r);
  const ax = Math.max(qx, 0), ay = Math.max(qy, 0);
  return Math.min(Math.max(qx, qy), 0) + Math.sqrt(ax * ax + ay * ay) - r;
}

function paint(x, y, w, h, r, color) {
  const [cr, cg, cb] = hex(color);
  const x0 = Math.max(0, Math.floor(x - 1)), x1 = Math.min(SIZE, Math.ceil(x + w + 1));
  const y0 = Math.max(0, Math.floor(y - 1)), y1 = Math.min(SIZE, Math.ceil(y + h + 1));
  for (let py = y0; py < y1; py++) {
    for (let px = x0; px < x1; px++) {
      const sd = sdRoundRect(px + 0.5, py + 0.5, x, y, w, h, r);
      const cov = Math.min(Math.max(0.5 - sd, 0), 1); // 1px analytic AA
      if (cov <= 0) continue;
      const i = (py * SIZE + px) * 4;
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

// 5x5 grid (matches icon.svg).
const grid = [
  ['#5B21B6', '#7C3AED', '#3B0764', '#6D28D9', '#A78BFA'],
  ['#C4B5FD', '#6D28D9', '#7C3AED', '#5B21B6', '#241B33'],
  ['#3B0764', '#5B21B6', '#A78BFA', '#7C3AED', '#6D28D9'],
  ['#7C3AED', '#C4B5FD', '#5B21B6', '#6D28D9', '#241B33'],
  ['#6D28D9', '#3B0764', '#7C3AED', '#A78BFA', '#5B21B6'],
];

function drawGrid(cell, gap, start, radius) {
  for (let row = 0; row < 5; row++) {
    for (let col = 0; col < 5; col++) {
      paint(start + col * (cell + gap), start + row * (cell + gap), cell, cell, radius, grid[row][col]);
    }
  }
}

// Encode PNG (truecolour + alpha, filter 0 per scanline).
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const body = Buffer.concat([typeBuf, data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body) >>> 0, 0);
  return Buffer.concat([len, body, crc]);
}

const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return c ^ 0xffffffff;
}

function writePng(name) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(SIZE, 0);
  ihdr.writeUInt32BE(SIZE, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // colour type RGBA
  const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1));
  for (let y = 0; y < SIZE; y++) {
    raw[y * (SIZE * 4 + 1)] = 0;
    Buffer.from(buf.buffer, y * SIZE * 4, SIZE * 4).copy(raw, y * (SIZE * 4 + 1) + 1);
  }
  const png = Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
  fs.writeFileSync(path.join(__dirname, '..', 'assets', name), png);
  console.log('Wrote assets/' + name + ' (' + png.length + ' bytes)');
}

// Full icon: dark rounded tile + grid.
paint(0, 0, SIZE, SIZE, 230, '#0D0D0D');
drawGrid(122, 24, 160, 24);
writePng('icon.png');

// Adaptive foreground: transparent bg, grid scaled into the safe zone.
buf = new Uint8ClampedArray(SIZE * SIZE * 4);
drawGrid(110, 18, 201, 22);
writePng('icon_foreground.png');
