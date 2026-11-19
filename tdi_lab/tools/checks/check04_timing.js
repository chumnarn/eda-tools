'use strict';
/*
 * tools/checks/check04_timing.js
 * LAB 04 : the timing constraint, and what the two TDI timing modes really do.
 *
 * The TDI Setup dialog offers two ways to describe the timing:
 *   "Define clocks"  - quick, no delay / load / fanout information
 *   SDC file         - the production route
 *
 * This lab works on two constraint files:
 *   timing_constraints.sdc      - the one that ships with the example
 *   timing_constraints_full.sdc  - the complete one that this lab asks for
 *
 * and proves that every port that a constraint mentions really exists.
 * It then reads the installed Custom IC scripts to show exactly what the
 * flow does with each of the two modes.
 */

const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 04 : timing constraints  (SDC and the two TDI modes)');

const sdcShipped = C.design('files', 'timing_constraints.sdc');
const sdcFull = C.design('files', 'timing_constraints_full.sdc');
const defFile = C.design('from_ledit.def');
const rtlFile = C.design('files', 'ADCCtrl_rtl.v');

if (!C.exists(sdcShipped) || !C.exists(sdcFull) || !C.exists(defFile)) {
  console.error('[ERROR] a needed file is missing under design/');
  process.exit(2);
}

const sdc = C.parseSdc(sdcShipped);
const full = C.parseSdc(sdcFull);
const def = C.parseDef(defFile);
const rtl = C.parseRtl(rtlFile);

const defPins = def.pins.map((p) => p.name);
const rtlPorts = [].concat(rtl.inputs, rtl.outputs, rtl.inouts);

c.info('sdc file        : ' + path.basename(sdcShipped));
c.info('def file        : ' + path.basename(defFile));

// --- the clock -------------------------------------------------------------
c.test(
  'the shipped SDC defines exactly one clock',
  sdc.clocks.length === 1,
  sdc.clocks.length + ' clock(s): ' + sdc.clocks.map((k) => k.name).join(', ')
);

const clk = sdc.clocks[0];
if (!clk) {
  console.log('');
  console.log('  no clock to check');
  process.exit(c.finish() ? 0 : 1);
}

// The SDC time unit is the library time unit; Oasys reads the period in ns.
const periodNs = clk.period;
c.test(
  'the clock period is positive and the waveform is a valid duty cycle',
  clk.period > 0 && clk.waveform.length === 2 && clk.waveform[0] < clk.waveform[1],
  'period = ' + periodNs + ' ns (' + (periodNs / 1000).toFixed(3) + ' us), waveform = {' +
    clk.waveform.join(' ') + '} -> duty ' +
    (((clk.waveform[1] - clk.waveform[0]) / clk.period) * 100).toFixed(1) + '%'
);

// --- the clock port must exist --------------------------------------------
c.test(
  'the port the clock is attached to exists in the layout',
  defPins.indexOf(clk.port) >= 0,
  'get_ports ' + clk.port + ' -> ' +
    (defPins.indexOf(clk.port) >= 0 ? 'found in the DEF pin list' : 'NOT FOUND in the DEF')
);
c.test(
  'the port the clock is attached to exists in the RTL',
  rtlPorts.indexOf(clk.port) >= 0,
  'get_ports ' + clk.port + ' -> ' +
    (rtlPorts.indexOf(clk.port) >= 0 ? 'found in the RTL port list' : 'NOT FOUND in the RTL')
);

// --- the timescale in the RTL ---------------------------------------------
const ts = C.readText(rtlFile).match(
  /`timescale\s+([\d.]+)\s*(ms|us|ns|ps|s)\s*\/\s*([\d.]+)\s*(ms|us|ns|ps|s)/i
);
let unitNs = null;
if (ts) {
  const mult = { s: 1e9, ms: 1e6, us: 1e3, ns: 1, ps: 1e-3 };
  unitNs = mult[ts[2].toLowerCase()] * parseFloat(ts[1]);
  c.info('rtl timescale   : ' + ts[1] + ts[2] + ' per ' + ts[3] + ts[4] +
    '  (1 time unit = ' + unitNs + ' ns)');
  const cycles = periodNs / unitNs;
  c.test(
    'the SDC clock period is a whole number of RTL clock cycles',
    Number.isInteger(cycles) && cycles > 0,
    periodNs + ' ns / ' + unitNs + ' ns = ' + cycles + ' clock cycles'
  );
} else {
  c.test('the RTL declares a timescale', false, 'no `timescale found in ' + path.basename(rtlFile));
}

// --- the complete SDC ------------------------------------------------------
c.test(
  'the complete SDC defines the same clock as the shipped one',
  full.clocks.length === 1 &&
    full.clocks[0].name === clk.name &&
    full.clocks[0].port === clk.port &&
    full.clocks[0].period === clk.period,
  full.clocks.length
    ? full.clocks[0].name + ' on ' + full.clocks[0].port + ', period ' + full.clocks[0].period + ' ns'
    : 'no clock'
);

c.test(
  'the complete SDC states the input and the output delays',
  full.hasInputDelay && full.hasOutputDelay,
  'set_input_delay ' + (full.hasInputDelay ? 'present' : 'MISSING') +
    ', set_output_delay ' + (full.hasOutputDelay ? 'present' : 'MISSING')
);

c.note(
  'the shipped SDC has ' +
  (sdc.hasInputDelay || sdc.hasOutputDelay ? 'some' : 'no') +
  ' interface delays: the clock alone does not constrain the inputs or the outputs'
);

// every port that the complete SDC mentions has to exist
const mentioned = [];
const fullTxt = C.readText(sdcFull);
const getPortsRe = /get_ports\s*\{([^}]*)\}/g;
let gm;
while ((gm = getPortsRe.exec(fullTxt)) !== null) {
  gm[1]
    .split(/[\s,]+/)
    .filter((s) => s.length > 0)
    .forEach((s) => mentioned.push(s.replace(/\[\*\]/, '[0]')));
}
const unknown = mentioned.filter(
  (p) => defPins.indexOf(p) < 0 && defPins.indexOf(p.replace('[0]', '')) < 0
);
c.test(
  'every port that the complete SDC constrains exists in the layout',
  unknown.length === 0,
  unknown.length === 0
    ? mentioned.length + ' constrained port references, all present'
    : 'unknown ports: ' + unknown.join(', ')
);

// --- what the installed flow does with each mode --------------------------
const install = C.detectInstall();
if (!install) {
  c.test(
    'the Custom IC installation was found',
    false,
    'no installation found under C:\\Siemens\\Custom IC - set TDI_INSTALL to override'
  );
} else {
  c.info('install         : ' + install);
  const txt = C.readText(path.join(install, 'tanner_oasys.tcl'));

  c.test(
    'the installed synthesis script offers both timing modes',
    /tanner_timing_mode\s*==\s*"clocks"/.test(txt) && /tanner_timing_mode\s*==\s*"sdc"/.test(txt),
    'tanner_timing_mode = "clocks" | "sdc"'
  );

  const inDelay = txt.match(/set_input_delay\s+-clock\s+\$\w+\s+([\d.]+)/);
  const outDelay = txt.match(/set_output_delay\s+-clock\s+\$\w+\s+([\d.]+)/);
  c.test(
    'the "Define clocks" mode applies a fixed input and output delay',
    !!inDelay && !!outDelay,
    'set_input_delay ' + (inDelay ? inDelay[1] : '?') +
      ' / set_output_delay ' + (outDelay ? outDelay[1] : '?') +
      ' -- a placeholder, not a real budget'
  );

  c.test(
    'the "sdc" mode reads one SDC file per analysis mode',
    /read_sdc\s+\$sdc_file\s+-mode\s+\$mode/.test(txt),
    'read_sdc $sdc_file -mode $mode, for every mode in MGC_modes'
  );

  c.note(
    '"Define clocks" is a shortcut for exploration. For a tape out run, ' +
    'use the SDC page so that the delays, loads and false paths are real.'
  );
}

process.exit(c.finish() ? 0 : 1);
