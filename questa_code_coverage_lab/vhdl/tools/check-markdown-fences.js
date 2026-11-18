// CommonMark-aware fence balance checker for the lab guide.
// Rules: a closing fence must use >= the opening fence's backtick count
// and must NOT have an info string. Tilde fences are tracked separately.
const fs = require('fs');
const path = process.argv[2];
const lines = fs.readFileSync(path, 'utf8').split(/\r?\n/);

let open = null; // { marker, count, line }
let errors = [];
let fenceCount = 0;

for (let i = 0; i < lines.length; i++) {
  const m = /^(\s{0,3})(`{3,}|~{3,})(.*)$/.exec(lines[i]);
  if (!m) continue;
  fenceCount++;
  const [, indent, marker, info] = m;
  const count = marker.length;
  const ch = marker[0];

  if (open === null) {
    open = { ch, count, line: i + 1 };
    continue;
  }
  // inside a fence: only a matching, long-enough fence with no info string closes it
  if (ch === open.ch && count >= open.count && info.trim() === '') {
    open = null;
  }
}

if (open !== null) {
  errors.push(`unclosed fence opened at line ${open.line} (${open.ch.repeat(open.count)})`);
}

// Report headings for a quick structural overview
const headings = lines
  .map((l, i) => ({ l, n: i + 1 }))
  .filter(o => /^#{1,3}\s/.test(o.l));

console.log(`file            : ${path}`);
console.log(`lines           : ${lines.length}`);
console.log(`fence markers   : ${fenceCount}`);
console.log(`headings (h1-h3): ${headings.length}`);
console.log(`h1 count        : ${headings.filter(o => /^#\s/.test(o.l)).length}`);
console.log(`h2 count        : ${headings.filter(o => /^##\s/.test(o.l)).length}`);
console.log(`h3 count        : ${headings.filter(o => /^###\s/.test(o.l)).length}`);
console.log(errors.length ? 'PROBLEMS:\n  ' + errors.join('\n  ') : 'fence balance  : OK');
