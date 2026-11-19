'use strict';
/*
 * tools/checks/common.js
 * -----------------------------------------------------------------------------
 * Shared helpers for the TDI lab checkers.
 *
 * Everything here parses files that are really present on this machine:
 *   - the ADC8 example that ships with Custom IC Platform 2025.4
 *   - the Generic 250 nm technology / standard cell libraries
 *   - the Custom IC installation scripts (tanner_oasys.tcl, flow_variables.tcl)
 *
 * No checker invents data. If a file is missing the checker reports FAIL
 * with the path it looked at, it never fabricates a value.
 *
 * Output is deliberately pure ASCII so that it survives any Windows console
 * code page (see tools/checks/README.txt).
 * -----------------------------------------------------------------------------
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const DESIGN_DIR = path.join(ROOT, 'design');

// ---------------------------------------------------------------------------
// output helpers
// ---------------------------------------------------------------------------

function line(ch) {
  return new Array(73).join(ch); // 72 chars wide
}

class Check {
  constructor(title) {
    this.title = title;
    this.rows = [];
    this.failures = 0;
    this.notes = [];
    console.log(line('='));
    console.log('  ' + title);
    console.log(line('='));
  }

  /**
   * @param {string} name   what is being checked
   * @param {boolean} ok    true = pass
   * @param {string} detail one line of evidence (numbers, paths, names)
   */
  test(name, ok, detail) {
    this.rows.push({ name, ok: !!ok, detail: detail === undefined ? '' : String(detail) });
    if (!ok) this.failures++;
    const tag = ok ? '[PASS]' : '[FAIL]';
    console.log('  ' + tag + ' ' + name);
    if (detail !== undefined && detail !== '') {
      console.log('         ' + String(detail));
    }
    return !!ok;
  }

  note(text) {
    this.notes.push(String(text));
    console.log('  [NOTE] ' + String(text));
  }

  info(text) {
    console.log('  [INFO] ' + String(text));
  }

  finish() {
    console.log(line('-'));
    const total = this.rows.length;
    const passed = total - this.failures;
    console.log('  ' + passed + '/' + total + ' checks passed');
    const verdict = this.failures === 0 ? 'PASS' : 'FAIL';
    console.log('  RESULT: ' + verdict);
    console.log(line('='));
    return this.failures === 0;
  }
}

// ---------------------------------------------------------------------------
// install detection
// ---------------------------------------------------------------------------

/**
 * Locate the Custom IC Platform installation (the folder that holds
 * tanner_oasys.tcl). Returns null when nothing is found.
 */
function detectInstall() {
  const candidates = [];
  if (process.env.TDI_INSTALL) candidates.push(process.env.TDI_INSTALL);

  const base = 'C:\\Siemens\\Custom IC';
  if (fs.existsSync(base)) {
    let entries = [];
    try {
      entries = fs.readdirSync(base);
    } catch (e) {
      entries = [];
    }
    entries
      .filter((d) => /^Custom IC\s/i.test(d))
      .sort()
      .reverse()
      .forEach((d) => candidates.push(path.join(base, d, 'x64')));
  }

  for (const c of candidates) {
    try {
      if (fs.existsSync(path.join(c, 'tanner_oasys.tcl'))) return c;
    } catch (e) {
      /* ignore */
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// file helpers
// ---------------------------------------------------------------------------

function readText(file) {
  return fs.readFileSync(file, 'utf8');
}

function exists(file) {
  try {
    fs.accessSync(file);
    return true;
  } catch (e) {
    return false;
  }
}

function sizeOf(file) {
  try {
    return fs.statSync(file).size;
  } catch (e) {
    return -1;
  }
}

/** Build a path inside the design folder. */
function design() {
  const parts = Array.prototype.slice.call(arguments);
  return path.join.apply(path, [DESIGN_DIR].concat(parts));
}

// ---------------------------------------------------------------------------
// Verilog / RTL
// ---------------------------------------------------------------------------

/**
 * Parse a non-ANSI Verilog module: a port list in the module header plus
 * separate input/output/inout declarations.
 *
 * @returns {{name:string, ports:string[], inputs:string[], outputs:string[],
 *            inouts:string[], buses:Array}}
 */
function parseRtl(file) {
  const txt = readText(file);
  const mod = txt.match(/module\s+([A-Za-z_]\w*)\s*\(([\s\S]*?)\)\s*;/);
  if (!mod) throw new Error('no module header found in ' + file);

  const name = mod[1];
  const header = mod[2]
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const inputs = [];
  const outputs = [];
  const inouts = [];
  const buses = [];

  const declRe = /(?:^|\n)\s*(input|output|inout)\s*(\[[^\]]*\])?\s*([^;]*);/g;
  let m;
  while ((m = declRe.exec(txt)) !== null) {
    const dir = m[1];
    const range = (m[2] || '').trim();
    const names = m[3]
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
    for (const n of names) {
      if (range) {
        const rm = range.match(/\[(\d+)\s*:\s*(\d+)\]/);
        const msb = rm ? parseInt(rm[1], 10) : 0;
        const lsb = rm ? parseInt(rm[2], 10) : 0;
        buses.push({ name: n, msb, lsb, width: Math.abs(msb - lsb) + 1, dir });
        for (let b = Math.min(msb, lsb); b <= Math.max(msb, lsb); b++) {
          const full = n + '[' + b + ']';
          if (dir === 'input') inputs.push(full);
          else if (dir === 'output') outputs.push(full);
          else inouts.push(full);
        }
      } else {
        if (dir === 'input') inputs.push(n);
        else if (dir === 'output') outputs.push(n);
        else inouts.push(n);
      }
    }
  }

  const ports = header.slice();
  return { name, ports, inputs, outputs, inouts, buses };
}

// ---------------------------------------------------------------------------
// LEF
// ---------------------------------------------------------------------------

/**
 * Parse a LEF file for the top level layer list, the database unit and the
 * site name. Layers inside MACRO / SITE blocks are ignored.
 */
/**
 * Parse a LEF file for the top level layer list, the database unit and the
 * site definition.
 *
 * Two LEF constructs look alike and must not be confused:
 *   LAYER Metal1          <- a layer definition (no semicolon)
 *   LAYER Metal1 ;        <- a reference inside a VIA block (semicolon)
 * Only the first form is collected, and blocks such as MACRO / SITE / VIA
 * are skipped completely.
 */
function parseLef(file) {
  const txt = readText(file);
  const lines = txt.split(/\r?\n/);
  const layers = [];
  const macros = [];
  let siteName = null;
  let siteSize = null;
  let inBlock = null; // 'MACRO' | 'SITE' | 'VIA' | null

  for (const raw of lines) {
    const l = raw.trim();
    if (!l || l[0] === '#') continue;

    const openMac = l.match(/^MACRO\s+(\S+)/);
    if (openMac) {
      macros.push(openMac[1]);
      inBlock = 'MACRO';
      continue;
    }
    const openSite = l.match(/^SITE\s+(\S+)\s*$/);
    if (openSite) {
      siteName = openSite[1];
      inBlock = 'SITE';
      continue;
    }
    const openVia = l.match(/^(?:Via|VIA)\s+(\S+)/);
    if (openVia) {
      inBlock = 'VIA';
      continue;
    }
    if (/^END\s+\S+/.test(l)) {
      inBlock = null;
      continue;
    }

    if (inBlock === 'SITE') {
      const sz = l.match(/^SIZE\s+([\d.]+)\s+BY\s+([\d.]+)/i);
      if (sz) siteSize = { width: parseFloat(sz[1]), height: parseFloat(sz[2]) };
      continue;
    }
    if (inBlock) continue; // inside MACRO or VIA

    // top level layer definition: no trailing semicolon
    const m = l.match(/^LAYER\s+(\S+)\s*$/);
    if (m) layers.push(m[1]);
  }

  const db = txt.match(/DATABASE\s+MICRONS\s+(\d+)/i);
  return {
    layers,
    macros,
    dbUnits: db ? parseInt(db[1], 10) : null,
    site: siteName,
    siteSize,
    routingLayers: layers.filter((x) => /^Metal\d+$/.test(x)),
    cutLayers: layers.filter((x) => /^Via\d+$/.test(x)),
  };
}

/**
 * Parse the detail of every routing layer in a LEF file:
 * type, direction, width, pitch and the minimum spacing.
 *
 * @returns {Object} keyed by layer name
 */
function parseLefRoutingLayers(file) {
  const txt = readText(file);
  const lines = txt.split(/\r?\n/);
  const out = {};
  let cur = null;
  let inVia = false;

  for (const raw of lines) {
    const l = raw.trim();
    if (!l || l[0] === '#') continue;

    if (/^(?:Via|VIA)\s+\S+/.test(l)) { inVia = true; continue; }
    if (/^END\s+\S+/.test(l)) {
      if (cur && /^END\s+/.test(l) && cur.name) { out[cur.name] = cur; cur = null; }
      inVia = false;
      continue;
    }
    if (inVia) continue;

    const open = l.match(/^LAYER\s+(\S+)\s*$/);
    if (open) {
      cur = { name: open[1], type: null, direction: null, width: null, pitch: null, spacing: null };
      continue;
    }
    if (!cur) continue;

    const t = l.match(/^TYPE\s+(\S+)\s*;/);
    if (t) { cur.type = t[1]; continue; }
    const d = l.match(/^DIRECTION\s+(\S+)\s*;/);
    if (d) { cur.direction = d[1]; continue; }
    const w = l.match(/^WIDTH\s+([\d.]+)\s*;/);
    if (w && cur.width === null) { cur.width = parseFloat(w[1]); continue; }
    const p = l.match(/^PITCH\s+([\d.]+)\s*;/);
    if (p) { cur.pitch = parseFloat(p[1]); continue; }
    const s = l.match(/^SPACING\s+([\d.]+)\s*;/);
    if (s && cur.spacing === null) { cur.spacing = parseFloat(s[1]); continue; }
  }
  if (cur) out[cur.name] = cur;
  return out;
}

// ---------------------------------------------------------------------------
// Liberty
// ---------------------------------------------------------------------------

function parseLiberty(file) {
  const txt = readText(file);
  const lib = txt.match(/library\s*\(\s*([^)\s]+)\s*\)/i);
  const cells = [];
  const cre = /^[ \t]*cell\s*\(\s*([^)\s]+)\s*\)/gm;
  let m;
  while ((m = cre.exec(txt)) !== null) cells.push(m[1]);
  const oc = [];
  const ore = /operating_conditions\s*\(\s*([^)\s]+)\s*\)/gi;
  while ((m = ore.exec(txt)) !== null) oc.push(m[1]);
  const nom = txt.match(/Library nominal:\s*([\d.]+)/);
  const volt = txt.match(/Voltage values given:[\s\S]*?Library nominal:\s*([\d.]+)/);
  const temp = txt.match(/Temperature values given:[\s\S]*?Library nominal:\s*([\d.]+)/);
  return {
    library: lib ? lib[1] : null,
    cells,
    operatingConditions: oc,
    nominalVoltage: volt ? parseFloat(volt[1]) : null,
    nominalTemperature: temp ? parseFloat(temp[1]) : null,
    nomProcess: nom ? parseFloat(nom[1]) : null,
  };
}

/** Map a Liberty file name to a corner role using the Siemens naming pattern. */
function cornerRole(fileName) {
  const n = path.basename(fileName);
  if (/_FF_/i.test(n)) return 'fast';
  if (/_SS_/i.test(n)) return 'slow';
  if (/_TT_/i.test(n)) return 'nominal';
  return 'unknown';
}

// ---------------------------------------------------------------------------
// PTF
// ---------------------------------------------------------------------------

function parsePtf(file) {
  const txt = readText(file);
  const proc = txt.match(/process_technology\s*\(\s*([^)\s]+)\s*\)/i);
  const layers = [];
  const re = /^[ \t]*layer\s*\(\s*([^)]+?)\s*\)\s*\{/gim;
  let m;
  while ((m = re.exec(txt)) !== null) layers.push(m[1]);
  const cu = txt.match(/capacitance_unit\s*:\s*(\S+)/i);
  const ru = txt.match(/resistance_unit\s*:\s*(\S+)/i);
  return {
    process: proc ? proc[1] : null,
    layers,
    capUnit: cu ? cu[1] : null,
    resUnit: ru ? ru[1] : null,
  };
}

// ---------------------------------------------------------------------------
// DEF
// ---------------------------------------------------------------------------

/**
 * Parse the subset of LEF/DEF that L-Edit writes for a P&R boundary:
 * UNITS, DIEAREA and the PINS section.
 */
function parseDef(file) {
  const txt = readText(file);

  const units = txt.match(/UNITS\s+DISTANCE\s+MICRONS\s+(\d+)/i);
  const dbUnits = units ? parseInt(units[1], 10) : null;

  const die = txt.match(
    /DIEAREA\s*\(\s*(-?\d+)\s+(-?\d+)\s*\)\s*\(\s*(-?\d+)\s+(-?\d+)\s*\)/i
  );

  const pins = [];
  const pinBlock = txt.match(/PINS\s+(\d+)\s*;([\s\S]*?)END\s+PINS/i);
  if (pinBlock) {
    const body = pinBlock[2];
    const entries = body.split(/\n\s*-\s+/).slice(1);
    for (const e of entries) {
      const first = e.split(/\r?\n/)[0].trim();
      const name = first.split(/\s+/)[0];
      // NET and DIRECTION are not guaranteed to be on the first line of the
      // entry, so both are matched against the whole entry.
      const net = (e.match(/\+ NET\s+(\S+)/) || [])[1];
      const dir = (e.match(/\+ DIRECTION\s+(\S+)/) || [])[1];
      const layer = (e.match(/\+ LAYER\s+(\S+)/) || [])[1];
      const fixed = e.match(/\+ FIXED\s*\(\s*(-?\d+)\s+(-?\d+)\s*\)\s*([NSEW])/i);
      pins.push({
        name,
        net,
        direction: dir,
        layer,
        x: fixed ? parseInt(fixed[1], 10) : null,
        y: fixed ? parseInt(fixed[2], 10) : null,
        orientation: fixed ? fixed[3] : null,
        hasFix: !!fixed,
      });
    }
  }

  const nets = [];
  const netBlock = txt.match(/NETS\s+(\d+)\s*;([\s\S]*?)END\s+NETS/i);
  if (netBlock) {
    const entries = netBlock[2].split(/\n\s*-\s+/).slice(1);
    for (const e of entries) {
      const first = e.split(/\r?\n/)[0].trim();
      nets.push(first.split(/\s+/)[0]);
    }
  }

  return {
    dbUnits,
    dieArea: die
      ? {
          x1: parseInt(die[1], 10),
          y1: parseInt(die[2], 10),
          x2: parseInt(die[3], 10),
          y2: parseInt(die[4], 10),
        }
      : null,
    pins,
    nets,
    hasComponents: /COMPONENTS\s+(\d+)\s*;/.test(txt),
    componentCount: parseInt((txt.match(/COMPONENTS\s+(\d+)\s*;/) || [])[1] || '-1', 10),
  };
}

/** Convert a DEF distance (database units) to microns. */
function dbuToMicron(dbu, def) {
  if (!def.dbUnits) return NaN;
  return dbu / def.dbUnits;
}

// ---------------------------------------------------------------------------
// SDC
// ---------------------------------------------------------------------------

function parseSdc(file) {
  const raw = readText(file);
  // A comment line may show an example command; it must not be parsed.
  const txt = raw.replace(/^[ \t]*#.*$/gm, '');
  const clocks = [];
  const re =
    /create_clock\s+-name\s+(\S+)\s+-period\s+([\d.]+)\s*(?:-waveform\s*\{([^}]*)\})?\s*\[get_ports\s+([^\]]+)\]/g;
  let m;
  while ((m = re.exec(txt)) !== null) {
    const wave = (m[3] || '')
      .split(/[,\s]+/)
      .filter((s) => s.length > 0)
      .map(Number);
    clocks.push({ name: m[1], period: parseFloat(m[2]), waveform: wave, port: m[4].trim() });
  }

  // The delay value may be preceded by "-clock <name>", so the value is not
  // always the first thing after the command.
  const delayOf = (cmd) => {
    const d = new RegExp(cmd + '\\s+(?:-clock\\s+\\S+\\s+)?(-?[\\d.]+)').exec(txt);
    return d ? parseFloat(d[1]) : null;
  };

  return {
    clocks,
    hasInputDelay: /set_input_delay\b/.test(txt),
    hasOutputDelay: /set_output_delay\b/.test(txt),
    inputDelay: delayOf('set_input_delay'),
    outputDelay: delayOf('set_output_delay'),
    hasFalsePath: /set_false_path\b/.test(txt),
    text: txt,
  };
}

// ---------------------------------------------------------------------------
// scan chain TCL
// ---------------------------------------------------------------------------

/**
 * Parse a scan configuration script. The Siemens example is written as
 *
 *     set twochains false
 *     if {$twochains} then { ... } else { ... }
 *
 * so the script is first reduced to the branch that is actually taken and
 * only that branch is parsed.
 */
function parseScan(file) {
  const raw = readText(file);
  // Comment lines may show an example command; they must not be parsed.
  const txt = raw.replace(/^[ \t]*#.*$/gm, '');

  let twochains = false;
  const tv = txt.match(/set\s+twochains\s+(true|false|0|1)/i);
  if (tv) twochains = /^(true|1)$/i.test(tv[1]);

  let body = txt;
  const ifIdx = txt.search(/if\s*\{\$twochains\}/);
  if (ifIdx >= 0) {
    // the statements before the if are always executed
    const before = txt.slice(0, ifIdx);
    const thenStart = txt.indexOf('{', txt.indexOf('then', ifIdx));
    const thenBlock = matchBraces(txt, thenStart);
    const elseIdx = txt.indexOf('else', thenStart + thenBlock.text.length + 1);
    let elseBlock = null;
    if (elseIdx >= 0) {
      const elseStart = txt.indexOf('{', elseIdx);
      elseBlock = matchBraces(txt, elseStart);
    }
    const chosen = twochains ? thenBlock : elseBlock;
    body = before + (chosen ? chosen.text : '');
  }

  const chains = [];
  const cre = /define_scan_chain\s+([^\n]*)/g;
  let m;
  while ((m = cre.exec(body)) !== null) {
    const args = m[1];
    chains.push({
      name: (args.match(/-name\s+(\S+)/) || [])[1] || null,
      scanIn: (args.match(/-scan_in\s+(\S+)/) || [])[1] || null,
      scanOut: (args.match(/-scan_out\s+(\S+)/) || [])[1] || null,
      scanEnable: (args.match(/-scan_enable\s+(\S+)/) || [])[1] || null,
      createPort: /-create_port/.test(args),
      maxLength: (args.match(/-max_length\s+(\d+)/) || [])[1] || null,
    });
  }

  const testPins = [];
  const tre = /define_test_pin\s+([^\n]*)/g;
  while ((m = tre.exec(body)) !== null) {
    const args = m[1];
    testPins.push({
      pin: (args.match(/-pin\s+(\S+)/) || [])[1] || null,
      scan: (args.match(/-scan\s+(\d+)/) || [])[1] || null,
      scanMode: (args.match(/-scan_mode\s+(\d+)/) || [])[1] || null,
      createPort: /-create_port/.test(args),
    });
  }

  const testClocks = [];
  const clre = /define_test_clock\s+([^\n]*)/g;
  while ((m = clre.exec(body)) !== null) {
    const args = m[1];
    testClocks.push({
      name: (args.match(/-name\s+(\S+)/) || [])[1] || null,
      pin: (args.match(/-pin\s+(\S+)/) || [])[1] || null,
    });
  }

  return { twochains, chains, testPins, testClocks, hasScanDef: /write_scandef/.test(txt) };
}

/**
 * Return the text between the braces that start at `start` and its matching
 * closing brace.
 */
function matchBraces(txt, start) {
  if (start < 0 || txt[start] !== '{') return null;
  let depth = 0;
  for (let i = start; i < txt.length; i++) {
    if (txt[i] === '{') depth++;
    else if (txt[i] === '}') {
      depth--;
      if (depth === 0) return { text: txt.slice(start + 1, i) };
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// TCL variables
// ---------------------------------------------------------------------------

/**
 * Collect every `set NAME value` in a TCL script. Array assignments
 * (set NAME(key) value) are reported separately because they are not plain
 * scalars.
 */
function tclSetVars(txt) {
  const scalars = new Map();
  const arrays = [];
  // A value may continue on the next line with a backslash. Join those
  // lines first, otherwise a list is only seen up to its first entry.
  const joined = txt.replace(/\\\r?\n/g, ' ');

  const re = /^[ \t]*set\s+([A-Za-z_][A-Za-z0-9_]*)\s+([\s\S]*?)$/gm;
  let m;
  while ((m = re.exec(joined)) !== null) {
    let v = m[2].trim();
    const comment = v.indexOf('#');
    if (comment >= 0) v = v.slice(0, comment).trim();
    v = v.replace(/;[\s]*$/, '').trim();
    if (v.length >= 2 && v[0] === '"' && v[v.length - 1] === '"') v = v.slice(1, -1);
    scalars.set(m[1], v);
  }
  const are = /^[ \t]*set\s+([A-Za-z_][A-Za-z0-9_]*)\(([^)]*)\)\s+([\s\S]*?)$/gm;
  while ((m = are.exec(joined)) !== null) {
    arrays.push({ name: m[1], key: m[2], value: m[3].replace(/;[\s]*$/, '').trim() });
  }
  return { scalars, arrays };
}

/**
 * Collect every `$name` that a TCL script reads. Names that are immediately
 * followed by `(` are commands, not variables, and are skipped.
 */
function tclUsedVars(txt) {
  const used = new Set();
  const re = /\$([A-Za-z_][A-Za-z0-9_]*)/g;
  let m;
  while ((m = re.exec(txt)) !== null) {
    const after = txt[m.index + m[0].length];
    if (after === '(') continue; // command call, not a variable
    used.add(m[1]);
  }
  return used;
}

/** Collect every variable a TCL script guards with `info exists`. */
function tclInfoExists(txt) {
  const set = new Set();
  const re = /info\s+exists\s+([A-Za-z_][A-Za-z0-9_]*)/g;
  let m;
  while ((m = re.exec(txt)) !== null) set.add(m[1]);
  return set;
}

/**
 * Collect every name that a TCL script assigns, wherever the assignment
 * happens: at the start of a line, inside a brace block, as a foreach
 * control variable or as a procedure argument.
 *
 * `set_param` is a different command and is not a variable assignment.
 */
function tclAssignedVars(txt) {
  const out = new Set();
  let m;

  const setRe = /(?:^|[\s{;])set\s+(?!param\b)([A-Za-z_][A-Za-z0-9_]*)\s*(\(|\s)/g;
  while ((m = setRe.exec(txt)) !== null) out.add(m[1]);

  const feRe = /\bforeach\s+([A-Za-z_][A-Za-z0-9_]*)\s/g;
  while ((m = feRe.exec(txt)) !== null) out.add(m[1]);

  const prRe = /\bproc\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{([^}]*)\}/g;
  while ((m = prRe.exec(txt)) !== null) {
    out.add(m[1]);
    m[2]
      .split(/\s+/)
      .filter((a) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(a))
      .forEach((a) => out.add(a));
  }

  // regexp ... -> name  assigns the match to a variable
  const reRe = /->\s*([A-Za-z_][A-Za-z0-9_]*)/g;
  while ((m = reRe.exec(txt)) !== null) out.add(m[1]);

  // global name  makes a variable visible to a procedure
  const glRe = /\bglobal\s+([A-Za-z_][A-Za-z0-9_]*)/g;
  while ((m = glRe.exec(txt)) !== null) out.add(m[1]);

  // gets $handle name  reads a line into a variable
  const getsRe = /\bgets\s+\$\w+\s+([A-Za-z_][A-Za-z0-9_]*)/g;
  while ((m = getsRe.exec(txt)) !== null) out.add(m[1]);

  // redirect_to_file -to_tcl_var name { ... }
  const rtfRe = /-to_tcl_var\s+([A-Za-z_][A-Za-z0-9_]*)/g;
  while ((m = rtfRe.exec(txt)) !== null) out.add(m[1]);

  return out;
}

// ---------------------------------------------------------------------------
// misc
// ---------------------------------------------------------------------------

function sortedUnique(arr) {
  return Array.from(new Set(arr)).sort();
}

function sameSet(a, b) {
  const sa = sortedUnique(a);
  const sb = sortedUnique(b);
  if (sa.length !== sb.length) return false;
  for (let i = 0; i < sa.length; i++) if (sa[i] !== sb[i]) return false;
  return true;
}

module.exports = {
  ROOT,
  DESIGN_DIR,
  Check,
  detectInstall,
  readText,
  exists,
  sizeOf,
  design,
  parseRtl,
  parseLef,
  parseLefRoutingLayers,
  parseLiberty,
  cornerRole,
  parsePtf,
  parseDef,
  dbuToMicron,
  parseSdc,
  parseScan,
  matchBraces,
  tclSetVars,
  tclAssignedVars,
  tclUsedVars,
  tclInfoExists,
  sortedUnique,
  sameSet,
};
