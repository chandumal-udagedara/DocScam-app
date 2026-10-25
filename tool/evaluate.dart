// Evaluation harness. Runs the SHIPPING engine over a labelled corpus and
// reports precision / recall / confusion matrix, per-rule behaviour, and
// every failure case.
//
// It imports lib/checker/rule_engine.dart directly and deliberately does not
// reimplement any matching logic. A harness that reimplements the engine
// measures the reimplementation, not the product.
//
//   dart run tool/evaluate.dart assets/content/scam-patterns.json corpus.jsonl
//
// Exit code 1 if the false positive rate exceeds --max-fpr, so this can gate CI.

import 'dart:convert';
import 'dart:io';
import '../lib/checker/rule_engine.dart';

const int kThreshold = 1; // flag when >= 1 non-low signal fires

void main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('usage: evaluate.dart <pattern-pack.json> <corpus.jsonl> [--max-fpr 0.05]');
    exit(2);
  }
  final maxFpr = _flag(args, '--max-fpr');

  final pack = ScamPatternPack.fromJson(
      jsonDecode(await File(args[0]).readAsString()) as Map<String, dynamic>);
  final engine = RuleEngine(pack);

  final corpus = (await File(args[1]).readAsLines())
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  var tp = 0, fp = 0, tn = 0, fn = 0;
  final failures = <(String, Map<String, dynamic>, CheckResult)>[];
  final ruleStats = <String, (int scam, int legit)>{};

  for (final item in corpus) {
    final res = engine.check(item['text'] as String);
    final flagged = res.signalCount >= kThreshold;
    final isScam = item['label'] == 'scam';

    if (flagged && isScam) {
      tp++;
    } else if (flagged && !isScam) {
      fp++;
      failures.add(('FALSE POSITIVE', item, res));
    } else if (!flagged && !isScam) {
      tn++;
    } else {
      fn++;
      failures.add(('FALSE NEGATIVE', item, res));
    }

    for (final f in res.flags) {
      final s = ruleStats[f.rule.id] ?? (0, 0);
      ruleStats[f.rule.id] =
          isScam ? (s.$1 + 1, s.$2) : (s.$1, s.$2 + 1);
    }
  }

  final precision = tp + fp == 0 ? 0.0 : tp / (tp + fp);
  final recall = tp + fn == 0 ? 0.0 : tp / (tp + fn);
  final f1 = precision + recall == 0
      ? 0.0
      : 2 * precision * recall / (precision + recall);
  final fpr = fp + tn == 0 ? 0.0 : fp / (fp + tn);

  print('pack ${pack.packVersion} | ${pack.rules.length} rules '
      '| ${corpus.length} messages');
  print('');
  print('              predicted scam   predicted legit');
  print('actual scam   ${_p(tp)}            ${_p(fn)}');
  print('actual legit  ${_p(fp)}            ${_p(tn)}');
  print('');
  print('precision            ${precision.toStringAsFixed(3)}');
  print('recall               ${recall.toStringAsFixed(3)}');
  print('F1                   ${f1.toStringAsFixed(3)}');
  print('false positive rate  ${fpr.toStringAsFixed(3)}');
  print('');

  print('per-rule firing (scam / legit):');
  final sorted = ruleStats.entries.toList()
    ..sort((a, b) => (b.value.$1 + b.value.$2).compareTo(a.value.$1 + a.value.$2));
  for (final e in sorted) {
    final warn = e.value.$2 > e.value.$1
        ? '   <- fires more on legitimate messages'
        : '';
    print('  ${e.key.padRight(30)} ${_p(e.value.$1)} / ${_p(e.value.$2)}$warn');
  }

  final unused =
      pack.rules.map((r) => r.id).where((id) => !ruleStats.containsKey(id));
  if (unused.isNotEmpty) {
    print('\nrules never fired (${unused.length}): ${unused.join(', ')}');
    print('  an untested rule is an unverified claim - add corpus coverage');
  }

  if (failures.isEmpty) {
    print('\nno failure cases');
  } else {
    print('\n${failures.length} failure case(s):');
    for (final (kind, item, res) in failures) {
      final text = item['text'] as String;
      print('\n  [$kind] ${item['id']} (${item['channel']})');
      print('  "${text.length > 110 ? '${text.substring(0, 110)}...' : text}"');
      print('  fired: ${res.flags.isEmpty ? 'nothing' : res.flags.map((f) => '${f.rule.id}(${f.rule.severity.name})').join(', ')}');
    }
  }

  if (maxFpr != null && fpr > maxFpr) {
    print('\nFAIL: false positive rate ${fpr.toStringAsFixed(3)} exceeds '
        'threshold ${maxFpr.toStringAsFixed(3)}');
    exit(1);
  }
}

String _p(int n) => n.toString().padLeft(5);

double? _flag(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? double.tryParse(args[i + 1]) : null;
}
