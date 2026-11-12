// Build a single-mode EDID so the source has no choice but to output it.
// Usage: node make-mode-edid.mjs <base.hex> <out.hex> <mode>
import { readFileSync, writeFileSync } from "node:fs";

// CEA-861 standard timings: [hact, hbl, hfp, hsync, vact, vbl, vfp, vsync, pclk10k, vic]
const MODES = {
  "720p60":  [1280, 370, 110,  40,  720,  30, 5,  5,  7425,  4],
  "480p60":  [ 720, 138,  16,  62,  480,  45, 9,  6,  2700,  2],
  "1080p60": [1920, 280,  88,  44, 1080,  45, 4,  5, 14850, 16],
  "1080p120":[1920, 280,  88,  44, 1080,  45, 4,  5, 29700, 63],
};

const [, , baseFile, outFile, modeName] = process.argv;
const m = MODES[modeName];
if (!m) throw new Error(`unknown mode ${modeName}; have ${Object.keys(MODES)}`);
const [ha, hb, hfp, hs, va, vb, vfp, vs, pclk, vic] = m;

const e = Uint8Array.from(
  readFileSync(baseFile, "utf8").trim().split(/\s+/).map((h) => parseInt(h, 16)),
);

const dtd = [
  pclk & 0xff, pclk >> 8,
  ha & 0xff, hb & 0xff, ((ha >> 8) << 4) | (hb >> 8),
  va & 0xff, vb & 0xff, ((va >> 8) << 4) | (vb >> 8),
  hfp & 0xff, hs & 0xff, ((vfp & 0xf) << 4) | (vs & 0xf),
  ((hfp >> 8) << 6) | ((hs >> 8) << 4) | ((vfp >> 4) << 2) | (vs >> 4),
  0xc4, 0x8e, 0x21, 0x00, 0x00, 0x1e,
];

e.set(dtd, 54);                                   // preferred DTD
e.set([0x00, 0x00, 0x00, 0x10, 0x00], 72);        // kill the second DTD
for (let i = 77; i < 90; i++) e[i] = 0x00;
e[10] = 0x50 + Object.keys(MODES).indexOf(modeName); e[11] = 0x01;  // unique product id

// CEA block: this VIC only, plus the HDMI VSDB, then the same DTD.
const body = [(2 << 5) | 1, vic, 0x67, 0x03, 0x0c, 0x00, 0x10, 0x00, 0x00, 0x4c];
const blk = new Uint8Array(128);
blk[0] = 0x02; blk[1] = 0x03; blk[2] = 4 + body.length; blk[3] = 0xc1;  // audio flag set
blk.set(body, 4);
blk.set(dtd, 4 + body.length);
let s1 = 0; for (let i = 0; i < 127; i++) s1 += blk[i];
blk[127] = (256 - (s1 % 256)) % 256;
e.set(blk, 128);

let s0 = 0; for (let i = 0; i < 127; i++) s0 += e[i];
e[127] = (256 - (s0 % 256)) % 256;

let out = "";
for (let i = 0; i < 256; i += 16)
  out += [...e.slice(i, i + 16)].map((b) => b.toString(16).padStart(2, "0")).join(" ") + "\n";
writeFileSync(outFile, out);
console.log(`${modeName}: ${ha}x${va}, ${(pclk / 100).toFixed(2)} MHz, VIC ${vic} -> ${outFile}`);
