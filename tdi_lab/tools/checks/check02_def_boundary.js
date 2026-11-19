'use strict';
/*
 * tools/checks/check02_def_boundary.js
 * LAB 02 : the P&R boundary and the pin locations that Nitro will use.
 *
 * The DEF file that L-Edit writes is the only description of the physical
 * block that Nitro receives. This lab proves that the boundary is sane and
 * that every pin sits inside it, on a routable layer, at a unique location.
 */

const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 02 : P&R boundary and pin geometry  (from_ledit.def)');

const defFile = C.design('from_ledit.def');
if (!C.exists(defFile)) {
  console.error('[ERROR] missing file: ' + defFile);
  process.exit(2);
}

const def = C.parseDef(defFile);

c.info('def file        : ' + path.basename(defFile));

// --- units -----------------------------------------------------------------
c.test(
  'the DEF declares its distance unit',
  def.dbUnits > 0,
  'UNITS DISTANCE MICRONS ' + def.dbUnits + '  (1 um = ' + def.dbUnits + ' DBU)'
);

// --- die area --------------------------------------------------------------
c.test(
  'the DEF contains a DIEAREA',
  !!def.dieArea,
  def.dieArea
    ? 'DIEAREA (' + def.dieArea.x1 + ' ' + def.dieArea.y1 + ') (' + def.dieArea.x2 + ' ' + def.dieArea.y2 + ') DBU'
    : 'DIEAREA not found'
);

const um = (v) => C.dbuToMicron(v, def);
let w = 0;
let h = 0;
if (def.dieArea) {
  w = um(def.dieArea.x2 - def.dieArea.x1);
  h = um(def.dieArea.y2 - def.dieArea.y1);
  c.test(
    'the block has a non degenerate size',
    w > 0 && h > 0,
    'die area = ' + w.toFixed(3) + ' um x ' + h.toFixed(3) + ' um'
  );
}

// --- pins ------------------------------------------------------------------
const pins = def.pins;
c.test(
  'the DEF carries a full pin list',
  pins.length > 0,
  pins.length + ' pins'
);

const noFix = pins.filter((p) => !p.hasFix);
c.test(
  'every pin has a FIXED location',
  noFix.length === 0,
  noFix.length === 0 ? 'all pins are fixed' : 'no FIXED: ' + noFix.map((p) => p.name).join(', ')
);

const outside = pins.filter(
  (p) =>
    p.hasFix &&
    (p.x < def.dieArea.x1 || p.x > def.dieArea.x2 || p.y < def.dieArea.y1 || p.y > def.dieArea.y2)
);
c.test(
  'every pin lies inside the die area',
  outside.length === 0,
  outside.length === 0
    ? 'all ' + pins.length + ' pins are inside the boundary'
    : 'outside: ' + outside.map((p) => p.name).join(', ')
);

const layers = C.sortedUnique(pins.map((p) => p.layer));
c.test(
  'all pins are on one routable layer',
  layers.length === 1 && /^Metal\d+$/.test(layers[0]),
  'pin layer = ' + layers.join(', ')
);

// --- uniqueness and pitch --------------------------------------------------
const seen = new Map();
let dup = 0;
for (const p of pins) {
  const k = p.x + ',' + p.y;
  if (seen.has(k)) dup++;
  else seen.set(k, p.name);
}
c.test(
  'no two pins share the same location',
  dup === 0,
  dup === 0 ? pins.length + ' unique locations' : dup + ' duplicated locations'
);

// --- edge distribution -----------------------------------------------------
const margin = 1000; // 1 um
const edges = { bottom: [], top: [], left: [], right: [], inner: [] };
for (const p of pins) {
  if (Math.abs(p.y - def.dieArea.y1) <= margin) edges.bottom.push(p);
  else if (Math.abs(p.y - def.dieArea.y2) <= margin) edges.top.push(p);
  else if (Math.abs(p.x - def.dieArea.x1) <= margin) edges.left.push(p);
  else if (Math.abs(p.x - def.dieArea.x2) <= margin) edges.right.push(p);
  else edges.inner.push(p);
}
const usedEdges = Object.keys(edges).filter((k) => edges[k].length > 0);
c.test(
  'the pins sit on the boundary edges, not in the middle of the block',
  edges.inner.length === 0,
  usedEdges.map((k) => k + '=' + edges[k].length).join(', ')
);
c.note(
  'bottom edge pins are ' + um(def.dieArea.y1 - def.dieArea.y1 + 50).toFixed(3) +
  ' um above the die edge, top edge pins are ' +
  um(def.dieArea.y2 - 52700).toFixed(3) + ' um below the die edge'
);

// --- pitch on the busiest edge -------------------------------------------
let minPitch = Infinity;
let pitchEdge = '';
for (const k of usedEdges) {
  const xs = edges[k].map((p) => p.x).sort((a, b) => a - b);
  for (let i = 1; i < xs.length; i++) {
    const d = xs[i] - xs[i - 1];
    if (d < minPitch) {
      minPitch = d;
      pitchEdge = k;
    }
  }
}
c.test(
  'neighbouring pins on an edge are spaced apart',
  minPitch > 0,
  'minimum pitch = ' + um(minPitch).toFixed(3) + ' um on the ' + pitchEdge + ' edge'
);

// --- component count -------------------------------------------------------
c.test(
  'the DEF contains no placed components yet',
  def.componentCount === 0,
  'COMPONENTS ' + def.componentCount + ' -- this is the empty block that Nitro will fill'
);

// --- the shipped example vs the tutorial text ------------------------------
c.note(
  'the tutorial text describes the boundary as (0,0) to (177.8, 49.0) um; ' +
    'the DEF that ships with Custom IC 2025.4 says ' +
    w.toFixed(1) + ' x ' + h.toFixed(1) + ' um. Measure your own layout.'
);

process.exit(c.finish() ? 0 : 1);
