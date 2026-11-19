'use strict';
/*
 * tools/checks/check05_scan.js
 * LAB 05 : the DFT configuration that the scan flow needs.
 *
 * The example ships a scan configuration script. The TDI Setup dialog can
 * point at it, and the synthesis script then rewrites the design to scan
 * and writes a scan DEF.
 *
 * The important consequence for the layout side: scan creates NEW ports.
 * Those ports have to exist in the layout, and the layout has to be
 * exported to DEF again before Nitro is run.
 */

const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 05 : scan configuration  (scanchain.tcl)');

const scanFile = C.design('scanchain.tcl');
const defFile = C.design('from_ledit.def');

if (!C.exists(scanFile)) {
  console.error('[ERROR] missing file: ' + scanFile);
  process.exit(2);
}

const scan = C.parseScan(scanFile);
const def = C.exists(defFile) ? C.parseDef(defFile) : { pins: [] };

c.info('scan file       : ' + path.basename(scanFile));
c.info('twochains flag  : ' + scan.twochains + ' (the "if" branch is ' +
  (scan.twochains ? 'taken' : 'not taken') + ')');

// --- how many chains are actually configured --------------------------------
c.test(
  'the script configures exactly one scan chain',
  scan.chains.length === 1,
  scan.chains.length + ' active chain(s)' +
    (scan.twochains ? ' - twochains is true, so the two chain branch is used' : '')
);

const chain = scan.chains[0];
if (chain) {
  c.test(
    'the chain names its scan in, scan out and scan enable',
    !!chain.scanIn && !!chain.scanOut && !!chain.scanEnable,
    'scan_in = ' + chain.scanIn + ', scan_out = ' + chain.scanOut +
      ', scan_enable = ' + chain.scanEnable
  );
  c.test(
    'the chain asks the tool to create the ports it needs',
    chain.createPort,
    chain.createPort
      ? '-create_port is set, so ' + chain.scanIn + ', ' + chain.scanOut +
        ' and ' + chain.scanEnable + ' will be added to the design'
      : '-create_port is not set, the ports must already exist in the RTL'
  );
}

// --- the test pins ----------------------------------------------------------
const enablePin = scan.testPins.find((p) => p.createPort);
c.test(
  'the scan enable pin is created as a port',
  !!enablePin,
  enablePin
    ? 'define_test_pin -pin ' + enablePin.pin + ' -scan ' + enablePin.scan + ' -create_port'
    : 'no test pin with -create_port'
);

const testClk = scan.testClocks.find((t) => t.pin);
c.test(
  'a test clock is defined on the functional clock',
  !!testClk,
  testClk ? 'define_test_clock -name ' + testClk.name + ' -pin ' + testClk.pin : 'none found'
);

// --- the ports that scan adds ----------------------------------------------
const created = [];
if (chain) {
  if (chain.scanIn) created.push(chain.scanIn);
  if (chain.scanOut) created.push(chain.scanOut);
  if (chain.scanEnable) created.push(chain.scanEnable);
}
if (enablePin && created.indexOf(enablePin.pin) < 0) created.push(enablePin.pin);

const defPins = def.pins.map((p) => p.name);
const missingInDef = created.filter((p) => defPins.indexOf(p) < 0);

// A port in the DEF that looks like a scan port but that the configuration
// does not create would be a contradiction.
const strayScanPins = defPins.filter(
  (p) => /^Scan_/.test(p) && created.indexOf(p) < 0
);
c.test(
  'the DEF does not contain a scan port that the configuration does not create',
  strayScanPins.length === 0,
  strayScanPins.length === 0
    ? 'the DEF has no stray scan port'
    : 'in the DEF but not created by the configuration: ' + strayScanPins.join(', ')
);

c.info(
  'the scan configuration creates ' + created.length + ' ports (' + created.join(', ') + ')'
);
c.info(
  'the exported DEF contains ' + (created.length - missingInDef.length) + ' of them'
);
if (missingInDef.length) {
  c.note(
    'the DEF was exported before the scan flow was enabled. Add ' +
    missingInDef.join(', ') + ' to the layout and export the DEF again before ' +
    'running TDI with the scan configuration turned on.'
  );
}

// --- what the installed synthesis script does -----------------------------
const install = C.detectInstall();
if (!install) {
  c.test(
    'the Custom IC installation was found',
    false,
    'no installation found under C:\\Siemens\\Custom IC - set TDI_INSTALL to override'
  );
} else {
  const txt = C.readText(path.join(install, 'tanner_oasys.tcl'));
  c.test(
    'the synthesis script switches to scan mapping when a scan file is given',
    /synthesize\s+-module\s+\$tanner_cell\s+-map_to_scan/.test(txt),
    'synthesize -module $tanner_cell -map_to_scan'
  );
  c.test(
    'the synthesis script writes a scan DEF into the results folder',
    /write_scandef\s+results\//.test(txt),
    'write_scandef results/${tanner_cell}_scan.def'
  );
  c.test(
    'the synthesis script connects and reports the scan chains',
    /connect_scan_chains/.test(txt) && /report_scan_chains\s+-detail/.test(txt),
    'check_dft -> connect_scan_chains -> report_scan_chains -detail'
  );
}

process.exit(c.finish() ? 0 : 1);
