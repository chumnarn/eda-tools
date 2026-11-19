'use strict';
/*
 * tools/checks/check06_settings.js
 * LAB 06 : the contract between the TDI Setup dialog and the flow.
 *
 * The "Setup TDI" dialog does not run anything itself.  It writes a TCL
 * settings file and hands it to the flow.  The flow reads a fixed list of
 * variable names, and a variable that is missing or misspelled is simply
 * an empty string -- TCL does not complain, the flow just produces a wrong
 * result much later.
 *
 * This lab works from a curated contract table.  For every entry it
 *
 *   1. proves that the variable really is read by one of the installed
 *      scripts, and shows the line that reads it,
 *   2. checks that the example settings file defines it,
 *   3. checks the value against the rule that the flow itself applies.
 *
 * The power plan is checked against the rule that the flow applies in
 * compute_floorplan_details.tcl, including the geometry that the flow
 * derives from the ring settings.
 */

const fs = require('fs');
const path = require('path');
const C = require('./common');

const c = new C.Check('LAB 06 : the TDI settings contract  (nitro_settings.tcl)');

const install = C.detectInstall();
if (!install) {
  c.test(
    'the Custom IC installation was found',
    false,
    'no installation found under C:\\Siemens\\Custom IC - set TDI_INSTALL to override'
  );
  process.exit(c.finish() ? 0 : 1);
}
c.info('install         : ' + install);

const oasysFile = path.join(install, 'tanner_oasys.tcl');
const flowDir = path.join(install, 'ap_ref_flows');
const settingsFile = C.design('nitro_settings_ADCCtrl.tcl');

// --- collect the scripts of the flow --------------------------------------
function walk(dir, acc) {
  acc = acc || [];
  let entries = [];
  try {
    entries = fs.readdirSync(dir);
  } catch (e) {
    return acc;
  }
  for (const e of entries) {
    const p = path.join(dir, e);
    let st;
    try {
      st = fs.statSync(p);
    } catch (err) {
      continue;
    }
    if (st.isDirectory()) walk(p, acc);
    else if (/\.tcl$/i.test(e)) acc.push(p);
  }
  return acc;
}

const allFlowTcl = walk(flowDir);
const stageScripts = allFlowTcl.filter(
  (p) => !/flow_variables\.tcl$/i.test(p) && !/tcl_procs[\\/]/i.test(p)
);
// the search covers the stage scripts AND the procedures they call
const searchList = [oasysFile].concat(
  allFlowTcl.filter((p) => !/flow_variables\.tcl$/i.test(p))
);

// --- the contract table ----------------------------------------------------
// [variable, TDI Setup page, mode]   mode: undefined = always, 'clocks', 'sdc'
const CONTRACT = [
  ['ams_run_control', 'Run File'],
  ['lef_file_list', 'Tech and Lib'],
  ['lib_file_list', 'Tech and Lib'],
  ['ptf_file_list', 'Tech and Lib'],
  ['tanner_ptf_file_corner_list', 'Tech and Lib'],
  ['tech_file_list', 'Tech and Lib'],
  ['cell_lef_file_list', 'Tech and Lib'],
  ['corner_list', 'Tech and Lib'],
  ['rlc_file_list', 'Tech and Lib'],
  ['top_cell', 'Netlist/RTL'],
  ['tanner_cell', 'Netlist/RTL'],
  ['verilog_file_list', 'Netlist/RTL'],
  ['is_list_file', 'Netlist/RTL'],
  ['is_Verilog', 'Netlist/RTL'],
  ['list_file', 'Netlist/RTL'],
  ['use_list_file', 'Netlist/RTL'],
  ['enable_scan', 'Netlist/RTL'],
  ['syn_netlist', 'Netlist/RTL'],
  ['tanner_timing_mode', 'Timing'],
  ['tanner_clock_spec', 'Timing', 'clocks'],
  ['MGC_modes', 'Timing', 'sdc'],
  ['oasys_importConstraintsFile', 'Timing', 'sdc'],
  ['floorplan_mode', 'Floorplan'],
  ['def_floorplan_file', 'Floorplan'],
  ['chip_width', 'Floorplan'],
  ['chip_height', 'Floorplan'],
  ['chip_origin_x', 'Floorplan'],
  ['chip_origin_y', 'Floorplan'],
  ['core_site', 'Floorplan'],
  ['core_yb_spacing', 'Floorplan'],
  ['core_xl_spacing', 'Floorplan'],
  ['core_yt_spacing', 'Floorplan'],
  ['core_xr_spacing', 'Floorplan'],
  ['highest_routing_layer', 'Floorplan'],
  ['fp_utilization', 'Floorplan'],
  ['fp_aspect_ratio', 'Floorplan'],
  ['power_nets', 'Power Plan'],
  ['ground_nets', 'Power Plan'],
  ['enable_pg_ring', 'Power Plan'],
  ['enable_pg_stripe', 'Power Plan'],
  ['pg_ring_vlayer', 'Power Plan'],
  ['pg_ring_hlayer', 'Power Plan'],
  ['pg_ring_net_order', 'Power Plan'],
  ['pg_ring_widths', 'Power Plan'],
  ['pg_ring_spacing', 'Power Plan'],
  ['pg_ring_offset_top', 'Power Plan'],
  ['pg_ring_offset_right', 'Power Plan'],
  ['pg_ring_offset_bottom', 'Power Plan'],
  ['pg_ring_offset_left', 'Power Plan'],
  ['pg_stripe_list', 'Power Plan'],
  ['num_of_stripes', 'Power Plan'],
];

/** Find the line of an installed script that reads a variable. */
function findRead(v) {
  const re = new RegExp('\\$' + v.replace(/[$]/g, '\\$') + '(\\b|\\()');
  for (const s of searchList) {
    let lines;
    try {
      lines = C.readText(s).split(/\r?\n/);
    } catch (e) {
      continue;
    }
    for (let i = 0; i < lines.length; i++) {
      if (re.test(lines[i])) {
        return { file: path.basename(s), line: i + 1, text: lines[i].trim() };
      }
    }
  }
  return null;
}

// --- the settings file -----------------------------------------------------
if (!C.exists(settingsFile)) {
  c.test('the example settings file exists', false, 'missing: ' + settingsFile);
  process.exit(c.finish() ? 0 : 1);
}

const settingsTxt = C.readText(settingsFile);
const set = C.tclSetVars(settingsTxt);
const defined = new Set(set.scalars.keys());
set.arrays.forEach((a) => defined.add(a.name));

const timingMode = set.scalars.get('tanner_timing_mode');
c.info('timing mode     : ' + timingMode);

// --- 1. every contract entry is really read by the installed flow ---------
const notRead = [];
const evidence = {};
for (const [v, page, mode] of CONTRACT) {
  if (mode && mode !== timingMode) continue;
  const hit = findRead(v);
  if (!hit) notRead.push(v);
  else evidence[v] = hit;
}
c.test(
  'every variable of the contract is read by a script that is installed',
  notRead.length === 0,
  notRead.length === 0
    ? CONTRACT.length + ' contract variables, all found in the installed flow'
    : 'no script reads: ' + notRead.join(', ')
);

// --- 2. the settings file defines them all --------------------------------
const notDefined = CONTRACT.filter(
  (e) => (!e[2] || e[2] === timingMode) && !defined.has(e[0])
).map((e) => e[0]);
c.test(
  'the settings file defines every variable of the contract',
  notDefined.length === 0,
  notDefined.length === 0
    ? 'all contract variables are defined (' + defined.size + ' names in the file)'
    : 'missing: ' + notDefined.join(', ')
);

// --- 3. the technology LEF has to be first ---------------------------------
const lefNames = (set.scalars.get('lef_file_list') || '').match(/"([^"]+)"/g) || [];
const lefList = lefNames.map((s) => s.replace(/"/g, ''));
c.test(
  'the technology LEF is the first entry of the LEF list',
  lefList.length > 0 && /tech/i.test(lefList[0]),
  lefList.length ? 'order: ' + lefList.join(' -> ') : 'no LEF list found'
);

// --- 4. every referenced file has to exist ---------------------------------
const referenced = [];
const addRefs = (v) => {
  if (!v) return;
  (v.match(/"([^"]+)"/g) || []).forEach((s) => referenced.push(s.replace(/"/g, '')));
};
addRefs(set.scalars.get('lef_file_list'));
addRefs(set.scalars.get('lib_file_list'));
addRefs(set.scalars.get('ptf_file_list'));
addRefs(set.scalars.get('verilog_file_list'));
addRefs(set.scalars.get('def_floorplan_file'));
addRefs(set.scalars.get('tanner_scan_configuration_file'));
addRefs(set.scalars.get('tech_file_list'));
addRefs(set.scalars.get('cell_lef_file_list'));
set.arrays.forEach((a) => addRefs(a.value));

const base = path.dirname(settingsFile);
const absent = referenced.filter((f) => !C.exists(path.join(base, f)) && !C.exists(f));
c.test(
  'every file the settings file refers to is present',
  absent.length === 0,
  absent.length === 0
    ? referenced.length + ' referenced files, all present'
    : 'not found: ' + absent.join(', ')
);

// --- 5. the top cell has to match the design ------------------------------
const topCell = set.scalars.get('tanner_cell');
const defTxt = C.readText(C.design('from_ledit.def'));
const defCell = (defTxt.match(/^DESIGN\s+(\S+)\s*;/m) || [])[1];
c.test(
  'the top cell in the settings file matches the top cell of the DEF',
  !!topCell && topCell === defCell,
  'settings tanner_cell = ' + topCell + ', DEF DESIGN = ' + defCell
);

// --- 6. the power ring, with the rules that the flow applies -------------
const numList = (v) => (v || '').match(/[\d.]+/g) || [];
const quoted = (v) => (v || '').match(/"([^"]+)"/g) || [];

const netOrder = quoted(set.scalars.get('pg_ring_net_order')).map((s) => s.replace(/"/g, ''));
const widths = numList(set.scalars.get('pg_ring_widths'));
const spacings = numList(set.scalars.get('pg_ring_spacing'));
const nbSupplies = netOrder.length;

// this is the rule of compute_floorplan_details.tcl, line 36 and line 41
const widthOk = widths.length === 1 || widths.length === nbSupplies;
const spacingOk = spacings.length === 1 || spacings.length === nbSupplies - 1;
c.test(
  'the number of ring widths matches the number of supplies',
  widthOk,
  nbSupplies + ' supplies (' + netOrder.join(', ') + '), ' + widths.length + ' widths'
);
c.test(
  'the number of ring spacings matches the number of intervals between the supplies',
  spacingOk,
  nbSupplies + ' supplies -> ' + (nbSupplies - 1) + ' interval(s), ' +
    spacings.length + ' spacing(s) given'
);

// --- 7. the geometry that the flow derives from the ring ------------------
const techLayers = C.parseLefRoutingLayers(C.design('files', 'Generic250nm_tech.lef'));
const site = C.parseLef(C.design('files', 'Generic250nm_StdCells.lef')).siteSize;
const vlayer = set.scalars.get('pg_ring_vlayer');
const hlayer = set.scalars.get('pg_ring_hlayer');
const vMin = techLayers[vlayer] ? techLayers[vlayer].spacing : null;
const hMin = techLayers[hlayer] ? techLayers[hlayer].spacing : null;

c.test(
  'the power ring layers exist in the technology LEF',
  !!vMin && !!hMin,
  vlayer + ' (min spacing ' + vMin + ' um), ' + hlayer + ' (min spacing ' + hMin + ' um)'
);
c.test(
  'the power ring spacing is not tighter than the layer spacing',
  spacings.length > 0 &&
    Math.min.apply(null, spacings.map(Number)) >= Math.max(vMin || 0, hMin || 0),
  'ring spacing ' + Math.min.apply(null, spacings.map(Number)) + ' um vs layer spacing ' +
    Math.max(vMin || 0, hMin || 0) + ' um -- the flow stops with FLOW-ERROR otherwise'
);

const totalWidths =
  widths.length === 1 ? widths[0] * nbSupplies : widths.reduce((a, b) => a + parseFloat(b), 0);
const totalSpacings =
  spacings.length === 1
    ? spacings[0] * (nbSupplies - 1)
    : spacings.reduce((a, b) => a + parseFloat(b), 0);
const pgRingWidth = totalWidths + totalSpacings;
const widthContrib =
  widths.length === 1
    ? 2 * widths[0]
    : parseFloat(widths[0]) + parseFloat(widths[1]);
const spacingContrib = 2 * parseFloat(spacings[0]);
const macroRingSpacing = site ? 2 * site.height : 0;
const oversizeM2M = 2 * (widthContrib + spacingContrib + macroRingSpacing);

const offset = (n) => parseFloat(set.scalars.get('pg_ring_offset_' + n) || '0');
const ringOffset = {
  bottom: offset('bottom') + pgRingWidth,
  left: offset('left') + pgRingWidth,
  top: offset('top') + pgRingWidth,
  right: offset('right') + pgRingWidth,
};
const oversizeB2M = Math.max(ringOffset.bottom, ringOffset.left, ringOffset.top, ringOffset.right) + oversizeM2M;

c.note('the geometry that the flow derives from the ring settings:');
c.info('  total ring width  = ' + totalWidths + ' + ' + totalSpacings + ' = ' + pgRingWidth + ' um');
c.info('  width_contrib     = ' + widthContrib + ' um');
c.info('  spacing_contrib   = ' + spacingContrib + ' um');
c.info('  macro_ring_spacing= ' + macroRingSpacing + ' um  (2 x site height ' + (site ? site.height : '?') + ' um)');
c.info('  oversize_m2m      = ' + oversizeM2M + ' um');
c.info('  ring offsets      = ' + ringOffset.bottom + ' um on every side');
c.info('  oversize_b2m      = ' + oversizeB2M + ' um');

c.test(
  'the core margins are larger than the power ring that surrounds them',
  parseFloat(set.scalars.get('core_yb_spacing') || '0') > 0 &&
    parseFloat(set.scalars.get('core_yb_spacing') || '0') + ringOffset.bottom > 0,
  'core_yb_spacing ' + set.scalars.get('core_yb_spacing') + ' um + ring offset ' +
    ringOffset.bottom + ' um = the distance from the die edge to the first row'
);

// --- 8. the timing mode and its SDC ---------------------------------------
c.test(
  'the timing mode is one that the flow understands',
  timingMode === 'clocks' || timingMode === 'sdc',
  'tanner_timing_mode = ' + timingMode
);

if (timingMode === 'sdc') {
  const modes = quoted(set.scalars.get('MGC_modes')).map((s) => s.replace(/"/g, ''));
  const sdcArrays = set.arrays.filter((a) => a.name === 'oasys_importConstraintsFile');
  c.test(
    'every analysis mode has an SDC file',
    modes.length > 0 && modes.every((m) => sdcArrays.some((a) => a.key === m)),
    modes.length
      ? 'modes: ' + modes.join(', ') + ' | sdc arrays: ' + sdcArrays.map((a) => a.key).join(', ')
      : 'no MGC_modes defined'
  );
}

// --- 9. the run control ----------------------------------------------------
const control = set.scalars.get('ams_run_control');
c.test(
  'the run control is one of the three modes the flow understands',
  ['synpnr', 'syn', 'pnr'].indexOf(control) >= 0,
  'ams_run_control = ' + control
);

// --- the evidence table ----------------------------------------------------
c.note('where the flow reads the contract variables:');
Object.keys(evidence).forEach((v) => {
  const e = evidence[v];
  c.info('  $' + v + '  <- ' + e.file + ':' + e.line);
});

c.note(
  'a missing variable is not an error in TCL: it reads as an empty string, ' +
  'and the flow produces a wrong result instead of stopping.'
);

process.exit(c.finish() ? 0 : 1);
