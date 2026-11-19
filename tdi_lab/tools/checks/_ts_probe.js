'use strict';
const fs = require('fs');
const t = fs.readFileSync(process.argv[2], 'utf8');
const tests = [
  ['A backtick only', /`timescale/i],
  ['B backtick+scale', /`timescale\s+/i],
  ['C backtick+num', /`timescale\s+([\d.]+)/i],
  ['D backtick+num+unit', /`timescale\s+([\d.]+)([munps])/i],
  ['E no backtick full', /timescale\s+([\d.]+)([munps])\s*\/\s*([\d.]+)([munps])/i],
  ['F backtick full', /`timescale\s+([\d.]+)([munps])\s*\/\s*([\d.]+)([munps])/i],
];
for (const [name, re] of tests) {
  const m = t.match(re);
  console.log(name.padEnd(22), m ? JSON.stringify(m[0]) : 'NULL');
}
console.log('char codes of first 14:', (t.slice(0, 14).split('').map((c) => c.charCodeAt(0)).join(',')));
