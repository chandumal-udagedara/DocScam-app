// Reference implementation of the ScamShield rule engine.
// Mirrors lib/checker/rule_engine.dart exactly. Used to validate patterns
// and produce evaluation metrics. Dart RegExp is ECMAScript-flavoured, so
// behaviour here matches the shipping engine.

const HOMOGLYPHS = {
  '\u0410':'A', '\u0412':'B', '\u0415':'E', '\u041A':'K', '\u041C':'M', '\u041D':'H',
  '\u041E':'O', '\u0420':'P', '\u0421':'C', '\u0422':'T', '\u0423':'Y', '\u0425':'X',
  '\u0405':'S', '\u0406':'I', '\u0408':'J', '\u0430':'a', '\u0435':'e', '\u043E':'o',
  '\u0440':'p', '\u0441':'c', '\u0443':'y', '\u0445':'x', '\u0455':'s', '\u0456':'i',
  '\u0458':'j', '\u04BB':'h', '\u04CF':'l', '\u0501':'d', '\u051B':'q', '\u051D':'w',
  '\u0391':'A', '\u0392':'B', '\u0395':'E', '\u0396':'Z', '\u0397':'H', '\u0399':'I',
  '\u039A':'K', '\u039C':'M', '\u039D':'N', '\u039F':'O', '\u03A1':'P', '\u03A4':'T',
  '\u03A5':'Y', '\u03A7':'X', '\u03BF':'o', '\u03C1':'p', '\u03BD':'v', '\u03B1':'a',
  '\uFF10':'0', '\uFF11':'1', '\uFF12':'2', '\uFF13':'3', '\uFF14':'4', '\uFF15':'5',
  '\uFF16':'6', '\uFF17':'7', '\uFF18':'8', '\uFF19':'9', '\uFF21':'A', '\uFF22':'B',
  '\uFF23':'C', '\uFF24':'D', '\uFF25':'E', '\uFF26':'F', '\uFF27':'G', '\uFF28':'H',
  '\uFF29':'I', '\uFF2A':'J', '\uFF2B':'K', '\uFF2C':'L', '\uFF2D':'M', '\uFF2E':'N',
  '\uFF2F':'O', '\uFF30':'P', '\uFF31':'Q', '\uFF32':'R', '\uFF33':'S', '\uFF34':'T',
  '\uFF35':'U', '\uFF36':'V', '\uFF37':'W', '\uFF38':'X', '\uFF39':'Y', '\uFF3A':'Z',
  '\uFF41':'a', '\uFF42':'b', '\uFF43':'c', '\uFF44':'d', '\uFF45':'e', '\uFF46':'f',
  '\uFF47':'g', '\uFF48':'h', '\uFF49':'i', '\uFF4A':'j', '\uFF4B':'k', '\uFF4C':'l',
  '\uFF4D':'m', '\uFF4E':'n', '\uFF4F':'o', '\uFF50':'p', '\uFF51':'q', '\uFF52':'r',
  '\uFF53':'s', '\uFF54':'t', '\uFF55':'u', '\uFF56':'v', '\uFF57':'w', '\uFF58':'x',
  '\uFF59':'y', '\uFF5A':'z'
};

export function normalise(input) {
  let s = input.normalize('NFKC');
  s = s.replace(/[​-‍﻿­]/g, '');        // zero-width
  s = [...s].map(c => HOMOGLYPHS[c] ?? c).join('');
  s = s.replace(/[‘’‛]/g, "'")
       .replace(/[“”]/g, '"')
       .replace(/[‐-―]/g, '-');
  s = s.replace(/\s+/g, ' ').trim();
  return s;
}

// Registrable-ish host extraction. Deliberately simple and readable.
export function extractHosts(text) {
  const hosts = [];
  const re = /\bhttps?:\/\/([^\s/?#]+)/gi;
  let m;
  while ((m = re.exec(text)) !== null) {
    hosts.push(m[1].toLowerCase().replace(/^www\./, ''));
  }
  return hosts;
}

function hostMatches(host, allowed) {
  return allowed.some(d => host === d || host.endsWith('.' + d));
}

export function check(text, pack) {
  const norm = normalise(text);
  const fired = new Map();

  for (const rule of pack.rules) {
    let evidence = null;

    if (rule.match_type === 'brand_domain_mismatch') {
      const hosts = extractHosts(norm);
      if (hosts.length) {
        for (const [brand, spec] of Object.entries(pack.brand_domains)) {
          if (!new RegExp(spec.mentions, 'i').test(norm)) continue;
          const bad = hosts.filter(h => !hostMatches(h, spec.domains));
          if (bad.length) { evidence = bad[0]; break; }
        }
      }
    } else {
      const hits = [];
      for (const p of rule.patterns ?? []) {
        const m = norm.match(new RegExp(p.value, 'i'));
        if (m) hits.push(m[0]);
      }
      // Some rules need several independent markers before they mean
      // anything. "Hi Mum" is a text from your kid; "Hi Mum" + "lost my
      // phone" + "new number" is the scam.
      if (hits.length >= (rule.min_pattern_matches ?? 1)) evidence = hits[0];
    }

    if (evidence !== null) {
      fired.set(rule.id, { rule, evidence });
    }
  }

  // Corroboration gate: naming an organisation is not suspicious on its
  // own. Drop rules that require support and did not get it.
  for (const [id, f] of [...fired]) {
    if (!f.rule.requires_corroboration) continue;
    const supported = (f.rule.combine_with ?? []).some(o => fired.has(o));
    if (!supported) fired.delete(id);
  }

  // Low-severity / report_alone:false rules are context only. They are
  // reported only when at least one standalone rule also fired.
  const standalone = [...fired.values()].filter(f => f.rule.report_alone !== false);
  const supporting = [...fired.values()].filter(f => f.rule.report_alone === false);

  const reported = standalone.length > 0
    ? [...standalone, ...supporting]
    : [];

  // combine_with raises display priority - it never manufactures a verdict.
  const firedIds = new Set(fired.keys());
  for (const f of reported) {
    f.boosted = (f.rule.combine_with ?? []).some(id => firedIds.has(id));
  }

  const order = { high: 0, medium: 1, low: 2 };
  reported.sort((a, b) =>
    (order[a.rule.severity] - order[b.rule.severity]) ||
    (Number(b.boosted) - Number(a.boosted)));

  return {
    normalised: norm,
    matches: reported.map(f => ({
      id: f.rule.id,
      title: f.rule.title,
      severity: f.rule.severity,
      explanation: f.rule.plain_explanation,
      evidence: f.evidence,
      boosted: !!f.boosted,
    })),
    // NOT a verdict. A count of what was recognised, for display ordering.
    signalCount: reported.filter(f => f.rule.severity !== 'low').length,
  };
}
