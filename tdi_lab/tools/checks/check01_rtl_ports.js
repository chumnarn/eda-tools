'use strict';
/*
 * tools/checks/check01_rtl_ports.js
 * LAB 01 : the RTL module and the DEF pins must describe the same interface.
 *
 * Why this matters for TDI:
 *   TDI never sees the RTL ports directly. Nitro sees the DEF that L-Edit
 *   exported from the layout. If the two disagree, the flow fails late
 *   (at placement or at the first pin connection) with an error that does
 *   not point at the real cause.
 */

const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 01 : RTL ports vs DEF pins  (ADC8 / ADCCtrl)');

const rtlFile = C.design('files', 'ADCCtrl_rtl.v');
const defFile = C.design('from_ledit.def');

if (!C.exists(rtlFile)) {
  console.error('[ERROR] missing file: ' + rtlFile);
  process.exit(2);
}
if (!C.exists(defFile)) {
  console.error('[ERROR] missing file: ' + defFile);
  process.exit(2);
}

const rtl = C.parseRtl(rtlFile);
const def = C.parseDef(defFile);

c.info('rtl file        : ' + path.basename(rtlFile));
c.info('def file        : ' + path.basename(defFile));
c.info('rtl module      : ' + rtl.name);
c.info('rtl header ports: ' + rtl.ports.length + ' (before bus expansion)');
c.info('def pins        : ' + def.pins.length);
c.info('def nets        : ' + def.nets.length);

// --- the bus ---------------------------------------------------------------
const bus = rtl.buses.find((b) => b.name === 'B');
c.test(
  'RTL declares the 8 bit output bus B',
  !!bus && bus.width === 8 && bus.dir === 'output',
  bus
    ? 'B[' + bus.lsb + ':' + bus.msb + '] -> width ' + bus.width + ', direction ' + bus.dir
    : 'bus B not found in the RTL'
);

// --- expanded port list ----------------------------------------------------
const expanded = []
  .concat(rtl.inputs, rtl.outputs, rtl.inouts)
  .sort();
const defNames = def.pins.map((p) => p.name).sort();

c.test(
  'the expanded RTL port list and the DEF pin list are the same set',
  C.sameSet(expanded, defNames),
  'rtl = ' + expanded.length + ' ports, def = ' + defNames.length + ' pins'
);
if (!C.sameSet(expanded, defNames)) {
  const onlyRtl = expanded.filter((p) => defNames.indexOf(p) < 0);
  const onlyDef = defNames.filter((p) => expanded.indexOf(p) < 0);
  if (onlyRtl.length) c.info('only in RTL : ' + onlyRtl.join(', '));
  if (onlyDef.length) c.info('only in DEF : ' + onlyDef.join(', '));
}

// --- direction agreement ---------------------------------------------------
const noDir = def.pins.filter((p) => !p.direction);
c.test(
  'every DEF pin carries a DIRECTION attribute',
  noDir.length === 0,
  noDir.length === 0
    ? 'all ' + def.pins.length + ' pins carry a direction'
    : 'missing: ' + noDir.map((p) => p.name).join(', ')
);

const dirOfRtl = {};
rtl.inputs.forEach((p) => (dirOfRtl[p] = 'INPUT'));
rtl.outputs.forEach((p) => (dirOfRtl[p] = 'OUTPUT'));
rtl.inouts.forEach((p) => (dirOfRtl[p] = 'INOUT'));

const mismatched = def.pins.filter(
  (p) => dirOfRtl[p] && p.direction && dirOfRtl[p] !== p.direction
);
c.test(
  'every DEF pin has the same direction as the RTL port',
  mismatched.length === 0,
  mismatched.length === 0
    ? 'all ' + def.pins.length + ' pins agree (INPUT/OUTPUT)'
    : 'mismatch: ' +
      mismatched
        .map((p) => p.name + ' rtl=' + dirOfRtl[p.name] + ' def=' + p.direction)
        .join(', ')
);

// --- net list --------------------------------------------------------------
const netNames = def.nets.slice().sort();
const pinNets = def.pins.map((p) => p.net).filter(Boolean).sort();
c.test(
  'every pin is backed by a NET entry',
  C.sameSet(pinNets, netNames) && pinNets.length === def.pins.length,
  pinNets.length + ' pin nets / ' + netNames.length + ' net entries'
);

// --- top cell --------------------------------------------------------------
const designName = (C.readText(defFile).match(/^DESIGN\s+(\S+)\s*;/m) || [])[1];
c.test(
  'the DEF top cell name matches the RTL module name',
  designName === rtl.name,
  'DEF DESIGN = ' + designName + ', RTL module = ' + rtl.name
);

// --- summary ---------------------------------------------------------------
const inputs = def.pins.filter((p) => p.direction === 'INPUT').length;
const outputs = def.pins.filter((p) => p.direction === 'OUTPUT').length;
c.note('port mix: ' + inputs + ' input / ' + outputs + ' output');
c.note('the 8 bit bus B[7:0] is 8 of the ' + def.pins.length + ' physical pins');

process.exit(c.finish() ? 0 : 1);
