// Evaluation harness. Runs the engine over a labelled corpus and reports
// precision / recall / confusion matrix, per-rule behaviour, and every
// failure case. Mirrors tool/evaluate.dart.
import fs from 'node:fs';
import { check } from './engine.mjs';

const pack = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const corpus = fs.readFileSync(process.argv[3], 'utf8')
  .split('\n').filter(Boolean).map(l => JSON.parse(l));

// Decision rule under test: flag the message if >=1 non-low signal fires.
const THRESHOLD = 1;

let tp = 0, fp = 0, tn = 0, fn = 0;
const failures = [];
const ruleStats = new Map();

for (const item of corpus) {
  const res = check(item.text, pack);
  const flagged = res.signalCount >= THRESHOLD;
  const isScam = item.label === 'scam';

  if (flagged && isScam) tp++;
  else if (flagged && !isScam) { fp++; failures.push({ ...item, res, kind: 'FALSE POSITIVE' }); }
  else if (!flagged && !isScam) tn++;
  else { fn++; failures.push({ ...item, res, kind: 'FALSE NEGATIVE' }); }

  for (const m of res.matches) {
    const s = ruleStats.get(m.id) ?? { scam: 0, legit: 0 };
    s[isScam ? 'scam' : 'legit']++;
    ruleStats.set(m.id, s);
  }
}

const prec = tp / (tp + fp) || 0;
const rec = tp / (tp + fn) || 0;
const f1 = 2 * prec * rec / (prec + rec) || 0;
const fpr = fp / (fp + tn) || 0;

console.log(`corpus: ${corpus.length} messages (${corpus.filter(c=>c.label==='scam').length} scam, ${corpus.filter(c=>c.label!=='scam').length} legitimate)`);
console.log(`decision rule: flag when >= ${THRESHOLD} non-low signal fires\n`);
console.log('              predicted scam   predicted legit');
console.log(`actual scam         ${String(tp).padStart(5)}            ${String(fn).padStart(5)}`);
console.log(`actual legit        ${String(fp).padStart(5)}            ${String(tn).padStart(5)}\n`);
console.log(`precision            ${prec.toFixed(3)}`);
console.log(`recall               ${rec.toFixed(3)}`);
console.log(`F1                   ${f1.toFixed(3)}`);
console.log(`false positive rate  ${fpr.toFixed(3)}   <- the number that decides trust`);

console.log('\nper-rule firing (scam / legit):');
[...ruleStats.entries()].sort((a,b)=>(b[1].scam+b[1].legit)-(a[1].scam+a[1].legit))
  .forEach(([id,s]) => {
    const flag = s.legit > s.scam ? '  <- fires more on legitimate messages' : '';
    console.log(`  ${id.padEnd(30)} ${String(s.scam).padStart(3)} / ${String(s.legit).padStart(3)}${flag}`);
  });

const unused = pack.rules.map(r=>r.id).filter(id=>!ruleStats.has(id));
if (unused.length) console.log(`\nrules never fired (${unused.length}): ${unused.join(', ')}`);

if (failures.length) {
  console.log(`\n${failures.length} failure case(s):`);
  for (const f of failures) {
    console.log(`\n  [${f.kind}] ${f.id} (${f.channel})`);
    console.log(`  "${f.text.slice(0,110)}${f.text.length>110?'...':''}"`);
    console.log(`  fired: ${f.res.matches.map(m=>`${m.id}(${m.severity})`).join(', ') || 'nothing'}`);
  }
} else {
  console.log('\nno failure cases');
}
