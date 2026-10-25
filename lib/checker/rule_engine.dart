import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'normaliser.dart';

/// The checker.
///
/// Design constraint, from DR-001: this reports WHICH KNOWN SCAM PATTERNS a
/// message matches. It never returns a verdict. There is deliberately no
/// `isScam` anywhere in this file — a pattern matcher cannot honestly deliver
/// the accuracy a verdict implies, and a wrong "looks fine" is worse than no
/// answer at all for the person asking.

enum Severity { high, medium, low }

Severity _severity(String s) => switch (s) {
      'high' => Severity.high,
      'medium' => Severity.medium,
      _ => Severity.low,
    };

@immutable
class Rule {
  final String id;
  final String category;
  final Severity severity;
  final String title;

  /// Shown to the user verbatim. Plain language, one idea, no jargon.
  final String plainExplanation;

  final List<RegExp> patterns;

  /// Special matcher: compares link hosts against the brand the message names.
  final bool brandDomainMismatch;

  /// Independent markers required before this rule means anything.
  final int minPatternMatches;

  /// When true, only report if one of [combineWith] also fired.
  final bool requiresCorroboration;
  final List<String> combineWith;

  /// When false, never shown on its own — context only.
  final bool reportAlone;

  const Rule({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.plainExplanation,
    required this.patterns,
    this.brandDomainMismatch = false,
    this.minPatternMatches = 1,
    this.requiresCorroboration = false,
    this.combineWith = const [],
    this.reportAlone = true,
  });

  factory Rule.fromJson(Map<String, dynamic> j) => Rule(
        id: j['id'] as String,
        category: j['category'] as String? ?? 'uncategorised',
        severity: _severity(j['severity'] as String? ?? 'low'),
        title: j['title'] as String,
        plainExplanation: j['plain_explanation'] as String,
        patterns: ((j['patterns'] ?? const []) as List)
            .map((p) => RegExp(p['value'] as String, caseSensitive: false))
            .toList(growable: false),
        brandDomainMismatch: j['match_type'] == 'brand_domain_mismatch',
        minPatternMatches: j['min_pattern_matches'] as int? ?? 1,
        requiresCorroboration: j['requires_corroboration'] as bool? ?? false,
        combineWith:
            ((j['combine_with'] ?? const []) as List).cast<String>(),
        reportAlone: j['report_alone'] as bool? ?? true,
      );
}

@immutable
class BrandSpec {
  final RegExp mentions;
  final List<String> domains;
  const BrandSpec({required this.mentions, required this.domains});
}

@immutable
class RedFlag {
  final Rule rule;

  /// The text that triggered it — shown so the user can see *why*.
  final String evidence;

  /// True when a related rule also fired. Raises display priority only;
  /// it never manufactures a conclusion.
  final bool corroborated;

  const RedFlag(
      {required this.rule, required this.evidence, this.corroborated = false});
}

@immutable
class CheckResult {
  final String normalisedText;
  final List<RedFlag> flags;

  const CheckResult({required this.normalisedText, required this.flags});

  /// Count of non-low signals. For ordering and copy selection — NOT a score,
  /// and deliberately not thresholded into a verdict here.
  int get signalCount =>
      flags.where((f) => f.rule.severity != Severity.low).length;

  bool get foundNothing => flags.isEmpty;
}

class ScamPatternPack {
  final String packVersion;
  final List<Rule> rules;
  final Map<String, BrandSpec> brandDomains;

  ScamPatternPack(
      {required this.packVersion,
      required this.rules,
      required this.brandDomains});

  factory ScamPatternPack.fromJson(Map<String, dynamic> j) {
    final brands = <String, BrandSpec>{};
    ((j['brand_domains'] ?? const {}) as Map).forEach((k, v) {
      brands[k as String] = BrandSpec(
        mentions: RegExp(v['mentions'] as String, caseSensitive: false),
        domains: (v['domains'] as List).cast<String>(),
      );
    });
    return ScamPatternPack(
      packVersion: j['pack_version'] as String? ?? 'unknown',
      rules: (j['rules'] as List)
          .map((r) => Rule.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
      brandDomains: brands,
    );
  }

  static Future<ScamPatternPack> load(
      {String path = 'assets/content/scam-patterns.json'}) async {
    final raw = await rootBundle.loadString(path);
    return ScamPatternPack.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }
}

class RuleEngine {
  final ScamPatternPack pack;
  const RuleEngine(this.pack);

  CheckResult check(String input) {
    final text = normalise(input);
    final fired = <String, RedFlag>{};

    for (final rule in pack.rules) {
      final evidence = _evaluate(rule, text);
      if (evidence != null) {
        fired[rule.id] = RedFlag(rule: rule, evidence: evidence);
      }
    }

    // Corroboration gate. Naming an organisation is not suspicious — real
    // bank texts name the bank. Naming one *alongside* a deadline and an
    // off-domain link is. Without this the false positive rate is
    // unusable; see EVALUATION.md.
    fired.removeWhere((_, f) =>
        f.rule.requiresCorroboration &&
        !f.rule.combineWith.any(fired.containsKey));

    final standalone =
        fired.values.where((f) => f.rule.reportAlone).toList();
    if (standalone.isEmpty) {
      return CheckResult(normalisedText: text, flags: const []);
    }
    final supporting =
        fired.values.where((f) => !f.rule.reportAlone).toList();

    final flags = [
      for (final f in [...standalone, ...supporting])
        RedFlag(
          rule: f.rule,
          evidence: f.evidence,
          corroborated: f.rule.combineWith.any(fired.containsKey),
        )
    ]..sort((a, b) {
        final s = a.rule.severity.index.compareTo(b.rule.severity.index);
        if (s != 0) return s;
        return (b.corroborated ? 1 : 0).compareTo(a.corroborated ? 1 : 0);
      });

    return CheckResult(normalisedText: text, flags: flags);
  }

  String? _evaluate(Rule rule, String text) {
    if (rule.brandDomainMismatch) {
      final hosts = extractHosts(text);
      if (hosts.isEmpty) return null;
      for (final spec in pack.brandDomains.values) {
        if (!spec.mentions.hasMatch(text)) continue;
        for (final h in hosts) {
          if (!hostMatchesAny(h, spec.domains)) return h;
        }
      }
      return null;
    }

    final hits = <String>[];
    for (final p in rule.patterns) {
      final m = p.firstMatch(text);
      if (m != null) hits.add(m.group(0)!);
    }
    return hits.length >= rule.minPatternMatches ? hits.first : null;
  }
}
