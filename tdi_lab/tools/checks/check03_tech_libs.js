'use strict';
/*
 * tools/checks/check03_tech_libs.js
 * LAB 03 : the technology and library set that the TDI Setup dialog asks for.
 *
 * The "Tech and Lib" page of TDI collects four kinds of file:
 *   - LEF     : the physical view of the cells and of the technology
 *   - Liberty : the timing and power view of the cells
 *   - PTF     : the interconnect parasitic view (Nitro only)
 *   - corners : up to three (fast / nominal / slow)
 *
 * A mismatch between the LEF and the Liberty is one of the most common
 * causes of a failed run, and the error message usually does not point at
 * the real cause.
 */

const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 03 : technology and standard cell libraries  (Generic 250 nm)');

const techLef = C.design('files', 'Generic250nm_tech.lef');
const cellLef = C.design('files', 'Generic250nm_StdCells.lef');
const libTT = C.design('files', 'Generic250nm_TT_2P50V_25C.lib');
const libFF = C.design('files', 'Generic250nm_FF_2P75V_M40C.lib');
const libSS = C.design('files', 'Generic250nm_SS_2P25V_125C.lib');
const ptf = C.design('files', 'Generic250nm_typ.ptf');

const need = [
  [techLef, 'tech LEF'],
  [cellLef, 'standard cell LEF'],
  [libTT, 'nominal Liberty'],
  [ptf, 'PTF'],
];
const missing = need.filter((f) => !C.exists(f[0]));
if (missing.length) {
  missing.forEach((m) => console.error('[ERROR] missing ' + m[1] + ': ' + m[0]));
  process.exit(2);
}

// --- tech LEF --------------------------------------------------------------
const tech = C.parseLef(techLef);
c.test(
  'the tech LEF declares its database unit',
  tech.dbUnits > 0,
  'DATABASE MICRONS ' + tech.dbUnits + '  (1 um = ' + tech.dbUnits + ' DBU)'
);
c.test(
  'the tech LEF defines exactly the four routing layers Metal1..Metal4',
  tech.routingLayers.length === 4 &&
    ['Metal1', 'Metal2', 'Metal3', 'Metal4'].every((x) => tech.routingLayers.indexOf(x) >= 0),
  'routing layers: ' + tech.routingLayers.join(', ') +
    ' | cut layers: ' + tech.cutLayers.join(', ')
);

// --- standard cell LEF -----------------------------------------------------
const cells = C.parseLef(cellLef);
c.test(
  'the standard cell LEF contains MACRO definitions',
  cells.macros.length > 0,
  cells.macros.length + ' macros'
);
c.test(
  'the standard cell LEF uses the same database unit as the tech LEF',
  cells.dbUnits === tech.dbUnits,
  'tech LEF = ' + tech.dbUnits + ', cell LEF = ' + cells.dbUnits
);
c.test(
  'the standard cell LEF defines the standard cell row site',
  !!cells.site && !!cells.siteSize,
  'SITE ' + cells.site +
    (cells.siteSize ? ', SIZE ' + cells.siteSize.width + ' BY ' + cells.siteSize.height + ' um' : '')
);

// --- Liberty ---------------------------------------------------------------
const tt = C.parseLiberty(libTT);
c.test(
  'the nominal Liberty parses and names its library',
  !!tt.library && tt.cells.length > 0,
  'library "' + tt.library + '", ' + tt.cells.length + ' cells, ' +
    tt.nominalVoltage + ' V, ' + tt.nominalTemperature + ' C'
);

// corner roles
const corners = [
  [libFF, 'fast'],
  [libTT, 'nominal'],
  [libSS, 'slow'],
];
let roleOk = true;
const roleDetail = [];
for (const [f, want] of corners) {
  const role = C.cornerRole(f);
  const ok = role === want;
  if (!ok) roleOk = false;
  roleDetail.push(path.basename(f) + ' -> ' + role + (ok ? '' : ' (expected ' + want + ')'));
}
c.test(
  'the three Liberty files map to the three TDI corners',
  roleOk,
  roleDetail.join('; ')
);

// --- LEF / Liberty consistency --------------------------------------------
// A tie cell (TIE*) only needs timing. A filler cell (FILL*) only needs a
// physical macro. A scan flavoured macro (DFFPC) is a variant of a cell
// that the Liberty already describes. Everything else must exist in both
// libraries.
const libNames = new Set(tt.cells);
const lefNames = new Set(cells.macros);

const libertyOnly = tt.cells.filter((m) => !lefNames.has(m));
const lefOnly = cells.macros.filter((m) => !libNames.has(m));

/**
 * A macro without a Liberty model is acceptable when it is a scan flavoured
 * variant of a cell the Liberty already has (DFFPC is a variant of DFF).
 */
function isVariantOfKnownCell(macro) {
  return tt.cells.some((known) => known.length >= 3 && macro.indexOf(known) === 0);
}

const unexplained = libertyOnly.filter((m) => !/^(TIE|FILL)/.test(m));
c.test(
  'every Liberty cell that is not a tie or filler cell also exists in the LEF',
  unexplained.length === 0,
  unexplained.length === 0
    ? libertyOnly.length
      ? 'timing-only cells (tie cells): ' + libertyOnly.join(', ')
      : 'the two libraries describe exactly the same cells'
    : 'no physical macro for: ' + unexplained.join(', ')
);

const physicalOnly = lefOnly.filter((m) => !/^(TIE|FILL)/.test(m) && !isVariantOfKnownCell(m));
c.test(
  'every LEF macro that is not a tie, a filler or a scan variant also exists in the Liberty',
  physicalOnly.length === 0,
  physicalOnly.length === 0
    ? lefOnly.length
      ? 'physical-only macros: ' + lefOnly.join(', ')
      : 'the two libraries describe exactly the same cells'
    : 'no timing model for: ' + physicalOnly.join(', ')
);

c.test(
  'the LEF and the Liberty describe the same number of cells',
  cells.macros.length === tt.cells.length,
  cells.macros.length + ' macros in the LEF, ' + tt.cells.length + ' cells in the Liberty'
);

if (lefOnly.length) {
  c.note(
    'LEF macros without a Liberty model: ' + lefOnly.join(', ') +
    '  -- a filler cell needs no timing model; a scan flavoured macro needs one of its own'
  );
}
if (libertyOnly.length) {
  c.note(
    'Liberty cells without a LEF macro: ' + libertyOnly.join(', ') +
    '  -- a tie cell cannot be tied if it has no physical macro'
  );
}

// --- PTF -------------------------------------------------------------------
const p = C.parsePtf(ptf);
c.test(
  'the PTF parses and names its process technology',
  !!p.process,
  'process_technology "' + p.process + '", capacitance unit ' + p.capUnit +
    ', resistance unit ' + p.resUnit
);
const ptfLayers = p.layers.filter((x) => /^Metal\d+$/.test(x));
const missingPtf = tech.routingLayers.filter((x) => ptfLayers.indexOf(x) < 0);
c.test(
  'the PTF covers every routing layer of the technology',
  missingPtf.length === 0,
  missingPtf.length === 0
    ? 'PTF covers ' + ptfLayers.join(', ')
    : 'not covered by the PTF: ' + missingPtf.join(', ')
);

// --- summary ---------------------------------------------------------------
c.note('files and sizes:');
need
  .concat([[libFF, 'fast Liberty'], [libSS, 'slow Liberty']])
  .forEach((f) => {
    c.info('  ' + path.basename(f[0]) + '  (' + C.sizeOf(f[0]) + ' bytes)');
  });

process.exit(c.finish() ? 0 : 1);
